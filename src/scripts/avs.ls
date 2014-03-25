class window.AVS
  el = 0
  gl = 0

  const id-vertex-shader = '''
  attribute vec2 vertex;
  void main(void) { gl_Position = vec4(vertex, 0.0, 1.0); }
  '''

  const red-vertex-shader = '''
  void main(void) { gl_FragColor = vec4(1.0, 0.4, 0.1, 1.0); }
  '''

  (element) -> if element?
    el := element
    gl := el.get-context \experimental-webgl
    if gl?
      gl.viewport-width = el.width
      gl.viewport-height = el.height
      gl.get-extension \OES_texture_float

  ready: -> gl?

  gl: -> gl

  # Create vertex buffer object
  create-buffer: (verts) ->
    buffer = gl.create-buffer!
    gl.bind-buffer gl.ARRAY_BUFFER, buffer
    gl.buffer-data gl.ARRAY_BUFFER, new Float32Array(verts), gl.STATIC_DRAW
    buffer.length = verts.length
    buffer

  # Creates gpu program
  create-program: ({vertex = id-vertex-shader, fragment = red-vertex-shader} = {}) ->
    die = (str) -> if str.length > 0 => throw new Error str
    create-shader = (type, src) ->
      shader = gl.create-shader type
      gl.shader-source shader, src
      gl.compile-shader shader
      die gl.get-shader-info-log shader
      shader

    program = gl.create-program!
    if vertex?
      gl.attach-shader program, create-shader gl.VERTEX_SHADER, vertex
    if fragment?
      gl.attach-shader program, create-shader gl.FRAGMENT_SHADER, fragment
    gl.link-program program
    die gl.get-program-info-log program
    program

  # Create framebuffer with texture inside
  create-framebuffer: ({attach = gl.COLOR_ATTACHMENT0, \
                         size = [128, 128], \
                         format = gl.RGBA, \
                         type = gl.FLOAT, \
                         data = null} = {}) ->
    tex = gl.create-texture!
    gl.bind-texture gl.TEXTURE_2D, tex
    gl.tex-parameteri gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST
    gl.tex-parameteri gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST
    gl.tex-image2D gl.TEXTURE_2D, 0, format, size[0], size[1], 0, format, type, data

    fb = gl.create-framebuffer!
    gl.bind-framebuffer gl.FRAMEBUFFER, fb
    gl.framebuffer-texture2D gl.FRAMEBUFFER, attach, gl.TEXTURE_2D, tex, 0
    gl.bind-framebuffer gl.FRAMEBUFFER, null

    fb.texture = tex
    fb.size = size
    fb.attach = attach
    fb

  # Box from -1 to 1
  display: -> @display-buf ?= @create-buffer [ -1, -1, 1, -1, -1, 1, 1, 1 ]

  # Scoped function for programs
  use-program: (program, cb) ->
    curr-program = gl.get-parameter gl.CURRENT_PROGRAM
    uniform = (name) -> gl.get-uniform-location program, name

    gl.use-program program
    funcs = {
      send-float: (name, value) -> gl.uniform1f uniform(name), value
      send-int: (name, value) -> gl.uniform1i uniform(name), value
      send-float2: (name, values) -> gl.uniform2f uniform(name), values[0], values[1]

      draw-buffer: (buffer, {type = gl.POINTS, attrib = 'vertex', vars = 3} = {}) ->
        gl.bind-buffer gl.ARRAY_BUFFER, buffer
        loc = gl.get-attrib-location program, attrib
        gl.enable-vertex-attrib-array loc
        gl.vertex-attrib-pointer loc, vars, gl.FLOAT, false, 0, 0
        gl.draw-arrays type, 0, (buffer.length / vars)

      draw-display: ({attrib = 'vertex'} = {}) ~>
        funcs.draw-buffer @display(), type: gl.TRIANGLE_STRIP, attrib: attrib, vars: 2
    }
    cb funcs
    gl.use-program curr-program

  # Scoped function to switch framebuffers
  use-framebuffer: (fb, cb) ->
    curr-fb = gl.get-parameter gl.FRAMEBUFFER_BINDING
    gl.bind-framebuffer gl.FRAMEBUFFER, fb
    cb {
      viewport: -> gl.viewport 0, 0, fb.size[0], fb.size[1]
      clear: ~> @clear (viewport: fb.size) <<< it
    }
    gl.bind-framebuffer gl.FRAMEBUFFER, curr-fb

  # Alias for bind-texture
  use-texture: (tex, id = 0) ->
    gl.active-texture gl."TEXTURE#id"
    gl.bind-texture gl.TEXTURE_2D, tex
    id

  # Read pixels from framebuffer
  read-pixels: (fb) ->
    pixels = new Uint8Array 4 * fb.size[0] * fb.size[1]
    @use-framebuffer fb, ->
      gl.read-pixels 0, 0, fb.size[0], fb.size[1], gl.RGBA, gl.UNSIGNED_BYTE, pixels
    pixels

  # Clears screen
  clear: ({viewport = [gl.viewport-width, gl.viewport-height],\
            color = [0.1, 0.1, 0.1, 1.0]} = {}) ->
    gl.viewport 0, 0, viewport[0], viewport[1]
    gl.clear-color color[0], color[1], color[2], color[3]
    gl.clear gl.COLOR_BUFFER_BIT

  # Reverse version of set-interval
  draw-loop: (delay, cb) ->
    frames = 0
    start = (new Date).get-time!
    fps = document.create-element \div
    fps.set-attribute \style 'position: fixed; 
                              top: 0; 
                              left: 0; 
                              padding: 5px; 
                              background: white; 
                              color: black; 
                              opacity: 0.5;'
    document.body.append-child fps
    set-interval (->
      cb()
      frames += 1
      end = (new Date).get-time!
      fps.innerHTML = "FPS: " + Math.round(frames / ((end - start) / 1000))
    ), delay

  # Rendering pass to framebuffer
  pass: (program, fb, args={}, cb) ->
    buf <~ @use-framebuffer fb
    prog <~ @use-program program
    i = 0
    for k, v of args
      prog.send-int k, @use-texture v, i
      i += 1
    buf.clear!
    cb? buf: buf, prog: prog
    prog.draw-display!

  pretty-print: (fb) ->
    pixels = @read-pixels fb
    out = "-- Framebuffer: #{fb.size[0]}x#{fb.size[1]} --"
    step = 0
    for x in [0 to pixels.length]
      if (x / 4) % fb.size[0] == 0
        console.log out
        out = ""

      if step == 0
        out += "["
      out += (pixels[x] / 255).to-fixed 2
      out += if step == 3
        step = 0
        "] "
      else
        step += 1
        ", "
    console.log "---"
    pixels
