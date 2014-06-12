$ ->

  indent = (x) -> x?()
  #size   = [16, 16]
  size   = [128, 64]
  count  = size[0] * size[1]
  factor = 150
  h      = 5
  m      = 1
  u      = 10
  scale  = 0.004
  debug  = false
  time   = 0

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
    gridViscosity : "shaders/grid_viscosity.glsl"
    velocity  : "shaders/velocity.glsl"
    position  : "shaders/position.glsl"

    # Rendering
    axes: {
      vertexUrl: "shaders/axes.vertex.glsl"
      fragmentUrl: "shaders/axes.fragment.glsl"
    }

    particles : {
      vertexUrl   : "shaders/particles.vertex.glsl"
      fragmentUrl : "shaders/particles.fragment.glsl"
    }

  }, {

    # Constants
    pi        : 3.14.toFixed(8)

    # World dimensions
    factor    : factor.toFixed(8)
    lobound   : 1.toFixed(8)
    hibound   : (factor - 1).toFixed(8)
    bound     : (factor * scale).toFixed(8)
    sizex     : size[0].toFixed(8)
    sizey     : size[1].toFixed(8)
    count     : count.toFixed(8)
    grid_size : (factor / h).toFixed(8)
    scale     : scale.toFixed(8)

    # SPH parameters
    max_part  : 30.toFixed(8)
    h         : h.toFixed(8)
    m         : m.toFixed(16)
    k         : 0.004.toFixed(8)
    r0        : 100000.toFixed(16)
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
          0
        )
        #partsBuf.push(
          #deltaI * i + (deltaI / 2.0),
          #deltaJ * j + (deltaJ / 2.0),
          #1
        #)
    partsBuf = avr.createBuffer(partsBuf)

    axesBuf = [
      0, 0, 0,
      1, 0, 0, # x axis
      1, 0, 0,
      1, 1, 0, # y axis
      1, 0, 0,
      1, 0, 1, # z axis
    ]
    #axesBuf = []
    #for i in [0..factor] by h
      #cur = i / factor
      #axesBuf.push(
        #cur, 0, 0,
        #cur, 1, 0
      #)
      #axesBuf.push(
        #0, 0, cur,
        #1, 0, cur
      #)
      #axesBuf.push(
        #0, cur, 0,
        #0, cur, 1
      #)
    axesBuf = avr.createBuffer(axesBuf)


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
    c.pass(p.zero, 'auto densities')
    c.pass(p.zero, 'auto pressures')
    c.pass(p.zero, 'auto viscosity')

    #$("#next").click ->
    avr.drawLoop 20, ->
    #indent ->

      # Calculating new velocities
      c.pass(p.velocity, 'front velocities', {
        back: 'back velocities'
        particles: 'back particles'
        pressures: 'auto pressures'
        viscosity: 'auto viscosity'
      }, ({prog}) ->
        prog.sendFloat3 'userDefined', [
          if $("#moveRight").is(':checked') then 0.3 else 0,
          if $("#moveRight").is(':checked') then 0.02 else 0,
          0
        ]
      )

      # Calculating new position
      c.pass(p.position, 'front particles', {
        back: 'back particles'
        velocities: 'front velocities'
      })
 
      # Generating cell indexes
      c.pass(p.genGridCells, 'auto grid', {
        particles: 'front particles'
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

      c.pass(p.zero, 'auto densities')
      c.pass(p.zero, 'auto pressures')
      c.pass(p.zero, 'auto viscosity')

      eachCell (i, j, k) ->
        c.pass(p.genAccessor, "accessor_#{i}_#{j}_#{k}", {
          particles: 'front particles',
          grid: 'auto grid'
        }, ({prog}) ->
          prog.sendFloat3 'cmpCell', [i, j, k]
        )

      eachCell (i, j, k) ->
        c.pass(p.gridDensities, 'switch densities', {
          particles: 'front particles'
          grid: 'auto grid'
          accessor: "accessor_#{i}_#{j}_#{k}"
          densities: 'auto densities'
        })

      eachCell (i, j, k) ->
        c.pass(p.gridPressures, 'switch pressures', {
          particles: 'front particles'
          grid: 'auto grid'
          accessor: "accessor_#{i}_#{j}_#{k}"
          densities: 'auto densities'
          pressures: 'auto pressures'
        })

      eachCell (i, j, k) ->
        c.pass(p.gridViscosity, 'switch viscosity', {
          viscosity: 'auto viscosity'
          velocities: 'front velocities'
          densities: 'auto densities'
          particles: 'front particles'
          grid: 'auto grid'
          accessor: "accessor_#{i}_#{j}_#{k}"
        })

      # Display

      toDebug = 'auto particles'

      avr.clear()
      time += 1

      p.axes.use (prog) ->
        prog.sendFloat('time', time)
        prog.drawBuffer(axesBuf, vars: 3, type: avr.gl.LINES)

      p.particles.use (prog) ->
        prog.sendFloat('time', time)
        prog.sendInt('positions', c.getBuffer('front particles').activeTexture(0))
        prog.sendInt('colors', c.getBuffer(toDebug).activeTexture(1))
        prog.sendInt('vectors', c.getBuffer('front velocities').activeTexture(2))
        prog.drawBuffer(partsBuf, vars: 3, type: avr.gl.POINTS)

      c.swapBuffers()
