class AVR.Visual extends AVR.GLContext
  init: ->
  draw: (options) ->

class AVR.Axes extends AVR.Visual
  init: ->
    @axesBuf = [
      0, 0, 0,
      1, 0, 0, # x axis
      1, 0, 0,
      1, 1, 0, # y axis
      1, 0, 0,
      1, 0, 1, # z axis
    ]
    @axesBuf = @avr.createBuffer(@axesBuf)
    @avr.loadProgram {
      vertexUrl: "shaders/axes.vertex.glsl"
      fragmentUrl: "shaders/axes.fragment.glsl"
    }, (prog) =>
      @prog = prog

  draw: ->
    @prog?.use (prog) ->
      prog.drawBuffer @axesBuf, vars:3, type: @avr.gl.LINES


visualizers = {}
AVR.Context::visualize = (vis, options = {}) ->
  inst = visualizers[vis]
  unless inst?
    inst = visualizers[vis] = new vis this
    inst.init()
  inst.draw(options)
