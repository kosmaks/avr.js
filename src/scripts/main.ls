<- (window.onload=)

const el = document.get-element-by-id \display
const gl = el.get-context \experimental-webgl
gl.viewport-width = el.width
gl.viewport-height = el.height

gl.get-extension \OES_texture_float

const id-vertex-shader = '''
attribute vec2 vertex;
void main(void) { gl_Position = vec4(vertex, 0.0, 1.0); }
'''

const red-vertex-shader = '''
void main(void) { gl_FragColor = vec4(1.0, 0.4, 0.1, 1.0); }
'''

# Create vertex buffer object
create-buffer = (verts) ->
  buffer = gl.create-buffer!
  gl.bind-buffer gl.ARRAY_BUFFER, buffer
  gl.buffer-data gl.ARRAY_BUFFER, new Float32Array(verts), gl.STATIC_DRAW
  buffer.length = verts.length
  buffer

# Creates gpu program
create-program = ({vertex = id-vertex-shader, fragment = red-vertex-shader} = {}) ->
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
create-framebuffer = ({attach = gl.COLOR_ATTACHMENT0, \
                       size = [128, 128], \
                       format = gl.RGB, \
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
const display = create-buffer [ -1, -1, 1, -1, -1, 1, 1, 1 ]

# Scoped function for programs
use-program = (program, cb) ->
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

    draw-display: ({attrib = 'vertex'} = {}) ->
      funcs.draw-buffer display, type: gl.TRIANGLE_STRIP, attrib: attrib, vars: 2
  }
  cb funcs
  gl.use-program curr-program

# Scoped function to switch framebuffers
use-framebuffer = (fb, cb) ->
  curr-fb = gl.get-parameter gl.FRAMEBUFFER_BINDING
  gl.bind-framebuffer gl.FRAMEBUFFER, fb
  cb {
    viewport: -> gl.viewport 0, 0, fb.size[0], fb.size[1]
    clear: -> clear (viewport: fb.size) <<< it
  }
  gl.bind-framebuffer gl.FRAMEBUFFER, curr-fb

# Alias for bind-texture
use-texture = (tex, id = 0) ->
  gl.active-texture gl."TEXTURE#id"
  gl.bind-texture gl.TEXTURE_2D, tex
  id

# Read pixels from framebuffer
read-pixels = (fb) ->
  pixels = new Uint8Array 4 * fb.size[0] * fb.size[1]
  use-framebuffer fb, ->
    gl.read-pixels 0, 0, fb.size[0], fb.size[1], gl.RGBA, gl.UNSIGNED_BYTE, pixels
  pixels

# Clears screen
clear = ({viewport = [gl.viewport-width, gl.viewport-height],\
          color = [0.1, 0.1, 0.1, 1.0]} = {}) ->
  gl.viewport 0, 0, viewport[0], viewport[1]
  gl.clear-color color[0], color[1], color[2], color[3]
  gl.clear gl.COLOR_BUFFER_BIT

# Reverse version of set-interval
draw-loop = (delay, cb) ->
  frames = 0
  start = (new Date).get-time!
  fps = document.create-element \div
  fps.set-attribute \style 'position: fixed; top: 0; left: 0; padding: 5px; background: white; color: black; opacity: 0.5;'
  document.body.append-child fps
  set-interval (->
    cb()
    frames += 1
    end = (new Date).get-time!
    fps.innerHTML = "FPS: " + Math.round(frames / ((end - start) / 1000))
  ), delay

# Rendering pass to framebuffer
pass = (program, fb, args={}, cb) ->
  buf <- use-framebuffer fb
  prog <- use-program program
  i = 0
  for k, v of args
    prog.send-int k, use-texture v, i
    i += 1
  buf.clear!
  cb? buf: buf, prog: prog
  prog.draw-display!

#
# Main program
#

size = [128, 128]
sizeM = size[0] * size[1]
sizex = "#{size[0]}.0"
sizey = "#{size[1]}.0"
h     = 0.0002
m     = 1

tex-vertex = """
  attribute vec2 vertex;
  varying vec2 index;

  void main() {
    index.x = (vertex.x > 0.) ? 1. : 0.;
    index.y = (vertex.y > 0.) ? 1. : 0.;
    gl_Position = vec4(vertex, 0., 1.);
  }
  """

helper = """
  precision mediump float;
  \#define AT(arr, x, y) texture2D(arr, vec2(x / #sizex, y / #sizey)
"""

main-prog = create-program {
  vertex: tex-vertex
  fragment: """
  precision mediump float;
  uniform sampler2D sampler;
  varying vec2 index;

  void main() {
    gl_FragColor = texture2D(sampler, index);
    gl_FragColor.w = 1.;
  }
  """
}

points-prog = create-program {
  vertex: """
  attribute vec2 vertex;

  void main() {
    gl_PointSize = 3.;
    gl_Position = vec4((vertex / 127.5) - 1., 0., 1.);
  }
  """
  fragment: """
  void main() {
    gl_FragColor = vec4(0.1, 0.4, 1., 1.);
  }
  """
}

fill-prog = create-program {
  vertex: tex-vertex
  fragment: """
  precision mediump float;
  varying vec2 index;

  void main() {
    gl_FragColor = vec4(
      index.x,
      mod(10. * index.x, 3.) / 3.,
      0.,
      1.
    );
  }
  """
}

convert-prog = create-program {
  vertex: tex-vertex
  fragment: """
  #helper
  varying vec2 index;
  uniform sampler2D fill;

  void main() {
    vec2 pos = texture2D(fill, index).xy;
    gl_FragColor.x = pos.x + pos.y * #sizex;
    gl_FragColor.y = 0.;
    gl_FragColor.z = 0.;
    gl_FragColor.w = 1.;
  }
  """
}

bitonic-helper = """
\#define X_TO_TEX(val) (val / #sizex)
\#define Y_TO_TEX(val) (val / #sizey)
\#define X_TO_PIX(val) floor(val * #sizex)
\#define Y_TO_PIX(val) floor(val * #sizey)

\#define TO_PIX(vec) vec2(X_TO_PIX(vec.x), Y_TO_PIX(vec.y))
\#define TO_TEX(vec) vec2(X_TO_TEX(vec.x), Y_TO_TEX(vec.y))

vec2 coordShift(float shift, vec2 src) {
  vec2 index = TO_PIX(src);
  float wide = index.x + shift;
  float indexX = mod(wide, #sizex);
  float indexY = index.y + floor(wide / #sizex);
  if (indexY > #sizey) indexY -= #sizey;
  else if (indexY < 0.) indexY += #sizey;
  return TO_TEX(vec2(indexX, indexY));
}

\#define DIR_CMP(forward, a, b) (forward == (a < b) ? a : b)
"""

bitonic-sort-prog = create-program {
  vertex: tex-vertex
  fragment: """
  #helper
  #bitonic-helper

  varying vec2 index;
  uniform float spread;
  uniform sampler2D src;
  vec2 current = texture2D(src, index).xy;

  void main() {
    bool even = mod(floor(#sizex * index.x / spread), 2.) == 0.;
    vec2 bCoord = coordShift((even ? 1. : -1.) * spread, index);

    float a = current.y;
    float b = texture2D(src, bCoord).y;

    // fill result
    gl_FragColor.x = current.x;
    gl_FragColor.y = DIR_CMP(even, a, b);
    gl_FragColor.z = 0.;
    gl_FragColor.w = 1.;
  }
  """
}

bitonic-merge-prog = create-program {
  vertex: tex-vertex
  fragment: """
  #helper
  #bitonic-helper
  
  varying vec2 index;
  uniform sampler2D src;
  uniform float count;
  vec2 current = texture2D(src, index).xy;

  float blockSize = #sizeM. / count;

  void main() {
    vec2 native = TO_PIX(index);
    float curr = native.x + native.y * #sizex;
    bool even = mod(floor(curr / (blockSize / 2.)), 2.) == 0.;

    float shift = (blockSize - 1.) - (2. * mod(curr, blockSize));
    vec2 bCoord = coordShift(shift, index);

    float a = current.y;
    float b = texture2D(src, bCoord).y;

    // fill result
    gl_FragColor.x = current.x;
    gl_FragColor.y = DIR_CMP(even, a, b);
    gl_FragColor.z = 0.;
    gl_FragColor.w = 1.;
  }
  """
}

bitonic-sort = (back-buf, front-buf) ->
  b = [back-buf, front-buf]
  merge = sizeM / 2
  while merge >= 1
    pass bitonic-merge-prog, b[1], src: b[0].texture, (b) ->
      b.prog.send-float \count merge
    b = [b[1], b[0]]

    sort = sizeM / merge / 4
    while sort >= 1
      pass bitonic-sort-prog, b[1], src: b[0].texture, (b) ->
        b.prog.send-float \spread sort
      b = [b[1], b[0]]

      sort /= 2
    merge /= 2
  b[0]

back-buf  = create-framebuffer size: size
front-buf = create-framebuffer size: size

<- draw-loop 16

use-program main-prog, (prog) ->

  # initial data
  pass fill-prog, back-buf
  #pass convert-prog, part-buf, fill: fill-buf.texture
  #pass bitonic-sort-prog, part-buf, src: fill-buf.texture, (b) ->

  # sort array
  res-buf = bitonic-sort back-buf, front-buf

  # debug with colors
  to-debug = res-buf
  clear!
  use-texture to-debug.texture
  prog.draw-display!

  # debug with points
  #pixels = read-pixels to-debug
  #points <- use-program points-prog
  #points.draw-buffer (create-buffer pixels), vars: 4
