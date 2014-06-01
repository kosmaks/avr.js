$ ->

  indent = (x) -> x?()
  #size   = [4, 4]
  size   = [64, 64]
  count  = size[0] * size[1]
  factor = 100
  h      = 20
  m      = 1
  u      = 1
  debug  = false

  eachCell = (cb) ->
    for i in [-1..1]
      for j in [-1..1]
        for k in [-1..1]
          cb? i, j, k

  avr = new AVR.Context(document.getElementById 'display')
  avr.loadPrograms {

    # Basic functions
    fill      : "shaders/fill.glsl"
    zero      : "shaders/zero.glsl"
    display   : "shaders/display.glsl"

    # Neighbour search
    genGridCells : "shaders/gen_grid_cells.glsl"
    genAccessor  : "shaders/gen_accessor.glsl"
    bitonicSort  : "shaders/bitonic.glsl"

    # SPH
    gridDensities : "shaders/grid_densities.glsl"
    gridPressures : "shaders/grid_pressures.glsl"
    gridViscosity : "shaders/viscosity.glsl"
    densities : "shaders/densities.glsl"
    gpressure : "shaders/gpressure.glsl"
    velocity  : "shaders/velocity.glsl"
    position  : "shaders/position.glsl"

    # Rendering
    particles : {
      vertexUrl   : "shaders/particles.vertex.glsl"
      fragmentUrl : "shaders/particles.fragment.glsl"
    }

  }, {

    # Constants
    pi        : 3.14.toFixed(8)

    # World dimensions
    factor    : factor.toFixed(8)
    lobound   : 0.toFixed(8)
    hibound   : factor.toFixed(8)
    sizex     : size[0].toFixed(8)
    sizey     : size[1].toFixed(8)
    count     : count.toFixed(8)
    grid_size : (factor / h).toFixed(8)
    scale     : 0.0004

    # SPH parameters
    h         : h.toFixed(8)
    m         : m.toFixed(8)
    k         : 0.006.toFixed(8)
    r0        : 1.toFixed(8)
    u         : u.toFixed(8)

  }, (p) ->

    partsBuf = []
    deltaI = 1.0 / size[0]
    deltaJ = 1.0 / size[1]
    for i in [0...size[0]]
      for j in [0...size[1]]
        partsBuf.push(
          deltaI * i + (deltaI / 2.0),
          deltaJ * j + (deltaJ / 2.0),
        )
    partsBuf = avr.createBuffer(partsBuf)

    c = avr.createChain()

    # Generate buffers
    c.framebuffer('reader', size: size)
    c.doubleFramebuffer('pressures', size: size)
    c.doubleFramebuffer('densities', size: size)
    c.doubleFramebuffer('grid', size: size)
    c.doubleFramebuffer('particles', size: size)
    c.doubleFramebuffer('velocities', size: size)
    c.doubleFramebuffer('viscosity', size: size)
    eachCell (i, j, k) -> c.framebuffer("accessor_#{i}_#{j}_#{k}", size: size)

    # Bootstrap
    c.pass(p.fill, 'back particles')
    c.pass(p.zero, 'back velocities')

    #$("#next").click ->
    avr.drawLoop 30, ->
    #indent ->
 
      # Generating cell indexes
      c.pass(p.genGridCells, 'auto grid', {
        particles: 'back particles'
      })

      # Sorting
      sortSpread = 2
      while sortSpread <= count
        c.pass(p.bitonicSort, 'switch grid', {
          target: 'auto grid'
        }, ({prog}) ->
          prog.sendFloat 'spread', sortSpread
          prog.sendInt 'isSort', 1
        )
        mergeSpread = sortSpread / 2
        sortSpread *= 2
        while mergeSpread >= 2
          c.pass(p.bitonicSort, 'switch grid', {
            target: 'auto grid'
          }, ({prog}) ->
            prog.sendFloat 'spread', mergeSpread
            prog.sendInt 'isSort', 0
          )
          mergeSpread /= 2


      eachCell (i, j, k) ->
        c.pass(p.genAccessor, "accessor_#{i}_#{j}_#{k}", {
          particles: 'back particles',
          grid: 'auto grid'
        }, ({prog}) ->
          prog.sendFloat3 'cmpCell', [i, j, k]
        )

      c.pass(p.zero, 'auto densities')
      eachCell (i, j, k) ->
        c.pass(p.gridDensities, 'switch densities', {
          particles: 'back particles'
          grid: 'auto grid'
          accessor: "accessor_#{i}_#{j}_#{k}"
          densities: 'auto densities'
        })

      c.pass(p.zero, 'auto pressures')
      eachCell (i, j, k) ->
        c.pass(p.gridPressures, 'switch pressures', {
          particles: 'back particles'
          grid: 'auto grid'
          accessor: "accessor_#{i}_#{j}_#{k}"
          densities: 'auto densities'
          pressures: 'auto pressures'
        })

      c.pass(p.zero, 'auto viscosity')
      eachCell (i, j, k) ->
        c.pass(p.gridViscosity, 'switch viscosity', {
          viscosity: 'auto viscosity'
          velocities: 'back velocities'
          densities: 'auto densities'
          particles: 'back particles'
          grid: 'auto grid'
          accessor: "accessor_#{i}_#{j}_#{k}"
        })

      #c.pass(p.densities, 'auto densities', {
        #particles: 'back particles'
      #})

      #c.pass(p.gpressure, 'auto pressures', {
        #particles: 'back particles'
        #densities: 'auto densities'
      #})

      # Calculating new velocities
      c.pass(p.velocity, 'front velocities', {
        back: 'back velocities'
        particles: 'back particles'
        pressures: 'auto pressures'
        viscosity: 'auto viscosity'
      })

      # Calculating new position
      c.pass(p.position, 'front particles', {
        back: 'back particles'
        velocities: 'front velocities'
      })

      # Display

      toDebug = 'auto densities'
      if debug
        pixels = c.getBuffer(toDebug).getPixels()
        str = ""; line = ""
        i = 0
        printers = {
          fn0: (x) -> "(#{(x/255).toFixed(3)},"
          fn1: (x) -> "#{(x/255).toFixed(3)})"
          fn2: (x) -> (Math.pow(factor / h, 3) * x / 255.0).toFixed(2)
          #fn2: (x) -> (x/255).toFixed(3)
          #fn2: (x) -> (8 * x/255).toFixed(2)
          fn3: (x) -> if x == 0 then "not found" else "found"
        }

        for pix in pixels
          fn = printers["fn#{i % 4}"]
          str += fn(pix) + " " if fn?
          i += 1
          if i % 4 == 0
            str += "| "
          if i % (size[0] * 4) == 0
            str += "\n"
        console.log str

      avr.clear()
      p.particles.use (prog) ->
        prog.sendInt('positions', c.getBuffer('back particles').activeTexture(0))
        prog.sendInt('colors', c.getBuffer(toDebug).activeTexture(1))
        prog.drawBuffer(partsBuf, vars: 2)

      c.swapBuffers()
