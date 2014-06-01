window.AVR = {}

class AVR.GLContext
  constructor: (@avr, opts...) ->
    throw new Error "AVR context is not specified" unless @avr?
    @gl = @avr.gl
    @initialize.apply this, opts if @initialize?

class AVR.Program extends AVR.GLContext

  sendFloat: (name, value) -> @gl.uniform1f @uniformLoc(name), value

  sendInt: (name, value) -> @gl.uniform1i @uniformLoc(name), value

  sendFloat2: (name, value) -> @gl.uniform2f @uniformLoc(name), value[0], value[1]

  sendFloat3: (name, value) -> @gl.uniform3f @uniformLoc(name), value[0], value[1], value[2]

  drawBuffer: (buffer, {type, attrib, vars} = {}) ->
    type   ?= @gl.POINTS
    attrib ?= 'vertex'
    vars   ?= 3
    @gl.bindBuffer @gl.ARRAY_BUFFER, buffer
    loc = @attribLoc attrib
    @gl.enableVertexAttribArray loc
    @gl.vertexAttribPointer loc, vars, @gl.FLOAT, false, 0, 0
    @gl.drawArrays type, 0, (buffer.length / vars)

  drawDisplay: ({attrib} = {}) ->
    @drawBuffer @avr.display(), type: @gl.TRIANGLE_STRIP, attrib: attrib, vars: 2

  use: (scope) ->
    prevProg = @gl.getParameter @gl.CURRENT_PROGRAM
    @gl.useProgram @program
    scope? this
    @gl.useProgram prevProg

  initialize: ({vertex, fragment}) ->
    @program = @gl.createProgram()
    @gl.attachShader @program, @createShader(@gl.VERTEX_SHADER, vertex)
    @gl.attachShader @program, @createShader(@gl.FRAGMENT_SHADER, fragment)
    @gl.linkProgram @program
    @die "", @gl.getProgramInfoLog(@program)

  createShader: (type, src) ->
    shader = @gl.createShader type
    @gl.shaderSource shader, src
    @gl.compileShader shader
    @die src, @gl.getShaderInfoLog(shader)
    shader

  uniformLoc: (name) -> @gl.getUniformLocation @program, name

  attribLoc: (name) -> @gl.getAttribLocation @program, name

  die: (prog, str) -> if str.length > 0
    if prog.length > 0
      i = 1
      prog = prog.split("\n").map((x) -> "#{i++}: #{x}").join("\n")
      console.log prog
    throw new Error str

class AVR.Framebuffer extends AVR.GLContext

  use: (scope) ->
    prevBuf = @gl.getParameter @gl.FRAMEBUFFER_BINDING
    @gl.bindFramebuffer @gl.FRAMEBUFFER, @fb
    scope? this
    @gl.bindFramebuffer @gl.FRAMEBUFFER, prevBuf

  clear: ->
    @avr.clear viewport: @size

  activeTexture: (id = 0) ->
    @avr.useTexture @texture, id

  getPixels: ->
    buffer = null
    @use =>
      buffer = new Uint8Array 4 * @size[0] * @size[1]
      @gl.readPixels 0, 0, @size[0], @size[1], @gl.RGBA, @gl.UNSIGNED_BYTE, buffer
    buffer

  initialize: ({@attach, @size, @format, @type, @data}) ->
    @attach ?= @gl.COLOR_ATTACHMENT0
    @size   ?= [128, 128]
    @format ?= @gl.RGBA
    @type   ?= @gl.FLOAT
    @data   ?= null

    @texture = @gl.createTexture()
    @gl.bindTexture @gl.TEXTURE_2D, @texture
    @gl.texParameteri @gl.TEXTURE_2D, @gl.TEXTURE_MAG_FILTER, @gl.NEAREST
    @gl.texParameteri @gl.TEXTURE_2D, @gl.TEXTURE_MIN_FILTER, @gl.NEAREST
    @gl.texImage2D @gl.TEXTURE_2D, 0, @format, @size[0], @size[1], 0, @format, @type, @data

    @fb = @gl.createFramebuffer()
    @gl.bindFramebuffer @gl.FRAMEBUFFER, @fb
    @gl.framebufferTexture2D @gl.FRAMEBUFFER, @attach, @gl.TEXTURE_2D, @texture, 0
    @gl.bindFramebuffer @gl.FRAMEBUFFER, null

class AVR.Context

  constructor: (@el) -> if @el?
    @gl = el.getContext 'experimental-webgl'
    @gl.getExtension 'OES_texture_float' if @ready()
    @gl.enable @gl.DEPTH_TEST

  ready: -> @gl?

  createBuffer: (verts) ->
    buffer = @gl.createBuffer()
    @gl.bindBuffer @gl.ARRAY_BUFFER, buffer
    @gl.bufferData @gl.ARRAY_BUFFER, new Float32Array(verts), @gl.STATIC_DRAW
    buffer.length = verts.length
    buffer

  createProgram: (opts = {}) -> new AVR.Program this, opts

  createFramebuffer: (opts = {}) -> new AVR.Framebuffer this, opts

  createDisplayProgram: (opts = {}) ->
    opts.vertex = """
    attribute vec2 vertex;
    varying vec2 index;

    void main() {
      index.x = (vertex.x > 0.) ? 1. : 0.;
      index.y = (vertex.y > 0.) ? 1. : 0.;
      gl_Position = vec4(vertex, 0., 1.);
    }
    """
    @createProgram opts

  loadProgram: ({vertexUrl, fragmentUrl}, defines = {}, cb) ->
    $.get vertexUrl, {}, (vertex) =>
      $.get fragmentUrl, {}, (fragment) =>
        res = @createProgram({
          fragment: @sourceReplace(fragment, defines),
          vertex: @sourceReplace(vertex, defines)
        })
        res.vertexSource = vertex
        res.fragmentSource = fragment
        cb? res

  loadDisplayProgram: (fragmentUrl, defines = {}, cb) ->
    $.get fragmentUrl, {}, (fragment) =>
      res = @createDisplayProgram({
        fragment: @sourceReplace(fragment, defines)
      })
      res.fragmentSource = fragment
      cb? res

  loadPrograms: (progs = {}, defines = {}, cb) ->
    count = 0
    count++ for _, _ of progs
    result = {}
    for nameIter, info of progs
      ((name) =>
        loader = if typeof(info) == "object" \
                 then 'loadProgram' \
                 else 'loadDisplayProgram'
        @[loader] info, defines, (prog) ->
          result[name] = prog
          count -= 1
          cb? result if count <= 0
      )(nameIter)

  sourceReplace: (source, defines = {}) ->
    result = source
    for name, value of defines
      re = new RegExp("\\$#{name}", 'g')
      result = result.replace(re, value)
    result

  display: -> @displayBuf ?= @createBuffer [-1, -1, 1, -1, -1, 1, 1, 1]

  clear: ({viewport, color} = {}) ->
    viewport ?= [@el.width, @el.height]
    color    ?= [0.0, 0.0, 0.0, 0]
    @gl.viewport 0, 0, viewport[0], viewport[1]
    @gl.clearColor color[0], color[1], color[2], color[3]
    @gl.clear @gl.COLOR_BUFFER_BIT

  useTexture: (tex, id = 0) ->
    @gl.activeTexture @gl["TEXTURE#{id}"]
    @gl.bindTexture @gl.TEXTURE_2D, tex
    id

  drawLoop: (time, cb) ->
    setInterval cb, time
