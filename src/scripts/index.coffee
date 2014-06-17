$ ->

  indent = (x) -> x?()
  #size   = [16, 16]
  size   = [64, 64]
  count  = size[0] * size[1]
  factor = 150
  h      = 5
  m      = 1
  u      = 10
  scale  = 0.004
  debug  = false
  wind   = false

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
    vectors : {
      vertexUrl   : "shaders/vectors.vertex.glsl"
      fragmentUrl : "shaders/vectors.fragment.glsl"
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

    c = avr.createChain()
    vis = avr.createVisual({ constants: p.constants })

    $(document).keydown (e) ->
      switch e.which
        when 68 then vis.beginRotate([0, 1, 0])
        when 65 then vis.beginRotate([0, -1, 0])
        when 83 then vis.beginRotate([0, 1, 0])
        when 87 then vis.beginRotate([0, -1, 0])
        when 81 then wind = true

    $(document).keyup (e) ->
      vis.endRotate()
      wind = false

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

    wallDispl = 0

    avr.drawLoop 40, ->
      wallDispl = if wind or $("#moveRight").is(':checked') then 20 else 0

      # Calculating new velocities
      c.pass(p.velocity, 'front velocities', {
        back: 'back velocities'
        particles: 'back particles'
        pressures: 'auto pressures'
        viscosity: 'auto viscosity'
      }, ({prog}) ->
        vis.sendUniform prog
        prog.sendFloat 'wallDispl', wallDispl
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

      avr.clear()

      vis.visualize(AVR.Axes)

      vis.visualize(AVR.Particles, {
        positions: c.getBuffer('front particles')
      })

      #vis.visualize(AVR.Vectors, {
        #positions: c.getBuffer('front particles')
        #vectors: c.getBuffer('front velocities')
      #})

      vis.next()
      c.swapBuffers()
