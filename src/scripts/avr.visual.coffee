class AVR.Visual extends AVR.GLContext
  initialize: (opts) ->
    @visualizers = {}
    @time = 0
    @rotation = [0, 0, 0]
    @rotSpeed = [0, 0, 0]
    @rotAccel = [0, 0, 0]
    @mouseUp()

    @maxRotationSpeed = opts.maxRotationSpeed ? 10
    @constants = opts.constants ? {}

    $(@avr.el).mousedown((e) => @mouseDown [e.offsetX, e.offsetY])
              .mousemove((e) => @mouseMove [e.offsetX, e.offsetY])
              .mouseup(=> @mouseUp())


  visualize: (type, options={}) ->
    inst = @visualizers[type]
    unless inst?
      inst = @visualizers[type] = new type @avr, {
        visual: this
        constants: @constants
      }
    inst.draw(options)

  sendUniform: (prog) ->
    prog.sendFloat2 'mouse', @mousePos
    prog.sendFloat 'time', @time
    prog.sendFloat3 'rotation', @rotation

  beginRotate: (vec) -> @rotAccel = vec
  endRotate: -> @rotAccel = [0, 0, 0]
  rotateAccel: (vec) -> for i in [0..2]
    @rotAccel[i] += vec[i]

  mouseDown: (pos) ->
    @mouseMoving = true
    @mouseMove(pos)

  mouseMove: (pos) -> if @mouseMoving
    h = $(@avr.el).height()
    @mousePos = [
      2 * pos[0] / $(@avr.el).width() - 1,
      2 * (h - pos[1]) / h - 1
    ]

  mouseUp: -> 
    @mouseMoving = false
    @mousePos = [-2, -2]

  next: ->
    @time += 1
    for i in [0..2]
      accel = @rotAccel[i]
      if accel != 0
        speed = @rotSpeed[i] + accel
        @rotSpeed[i] = @clamp(speed, -@maxRotationSpeed, @maxRotationSpeed)
      else
        @rotSpeed[i] -= @sign(@rotSpeed[i])
      @rotation[i] += @rotSpeed[i]

  sign: (x) -> if x < 0 then -1 else if x > 0 then 1 else 0
  clamp: (x, l, h) -> if x < l then l else if x > h then h else x

class AVR.Axes extends AVR.GLContext
  initialize: ({@visual}) ->
    axesBuf = [
      0, 0, 0,
      1, 0, 0, # x axis
      0, 0, 0,
      0, 1, 0, # y axis
      0, 0, 0,
      0, 0, 1, # z axis
    ]
    @axesBuf = @avr.createBuffer(axesBuf)
    @avr.loadProgram {
      vertexUrl: "shaders/axes.vertex.glsl"
      fragmentUrl: "shaders/axes.fragment.glsl"
    }, {}, (prog) =>
      @prog = prog

  draw: ->
    @prog?.use (prog) =>
      @visual.sendUniform prog
      prog.drawBuffer @axesBuf, vars:3, type: @avr.gl.LINES

class AVR.Particles extends AVR.GLContext
  initialize: ({@visual, constants}) ->
    @buffers = {}
    @avr.loadProgram {
      vertexUrl: "shaders/particles.vertex.glsl"
      fragmentUrl: "shaders/particles.fragment.glsl"
    }, constants, (prog) =>
      @prog = prog

  draw: (options) ->
    @prog?.use (prog) =>
      @visual.sendUniform prog
      prog.sendInt('positions', options.positions.activeTexture(0))
      prog.drawBuffer @getBuffer(options.positions.size), {
        vars:3, 
        type: @avr.gl.POINTS
      }

  getBuffer: (size) ->
    key = "#{size[0]}_#{size[1]}"
    buf = @buffers[key]
    unless buf?
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
      buf = @avr.createBuffer(partsBuf)
      @buffers[buf]
    buf

class AVR.Vectors extends AVR.GLContext
  initialize: ({@visual, constants}) ->
    @buffers = {}
    @avr.loadProgram {
      vertexUrl: "shaders/vectors.vertex.glsl"
      fragmentUrl: "shaders/vectors.fragment.glsl"
    }, constants, (prog) =>
      @prog = prog

  draw: (options) ->
    @prog?.use (prog) =>
      @visual.sendUniform prog
      prog.sendInt('positions', options.positions.activeTexture(0))
      prog.sendInt('vectors', options.vectors.activeTexture(1))
      prog.sendFloat('scale', options.scale ? 3)
      prog.drawBuffer @getBuffer(options.positions.size), {
        vars:3, 
        type: @avr.gl.LINES
      }

  getBuffer: (size) ->
    key = "#{size[0]}_#{size[1]}"
    buf = @buffers[key]
    unless buf?
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
          partsBuf.push(
            deltaI * i + (deltaI / 2.0),
            deltaJ * j + (deltaJ / 2.0),
            1
          )
      buf = @avr.createBuffer(partsBuf)
      @buffers[buf]
    buf

AVR.Context::createVisual = (opts={}) -> new AVR.Visual this, opts
