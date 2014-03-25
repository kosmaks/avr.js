<- (window.onload=)

avs = new AVS document.getElementById \display

size = [2, 8]
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

\#define X_TO_TEX(val) (val / #sizex)
\#define Y_TO_TEX(val) (val / #sizey)
\#define X_TO_PIX(val) floor(val * #sizex)
\#define Y_TO_PIX(val) floor(val * #sizey)

\#define TO_PIX(vec) vec2(X_TO_PIX(vec.x), Y_TO_PIX(vec.y))
\#define TO_TEX(vec) vec2(X_TO_TEX(vec.x), Y_TO_TEX(vec.y))
"""

main-prog = avs.create-program {
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

points-prog = avs.create-program {
  vertex: """
  attribute vec2 vertex;

  void main() {
    gl_PointSize = 5.;
    gl_Position = vec4((vertex / 127.5) - 1., 0., 1.);
  }
  """
  fragment: """
  void main() {
    gl_FragColor = vec4(0.1, 0.4, 1., 1.);
  }
  """
}

fill-prog = avs.create-program {
  vertex: tex-vertex
  fragment: """
  precision mediump float;
  varying vec2 index;

  void main() {
    vec2 native = floor(vec2(index.x * #sizex, index.y * #sizey));
    gl_FragColor = vec4(
      (1. - index.x),
      (1. - index.y),
      0.,
      1.
    );
  }
  """
}

convert-prog = avs.create-program {
  vertex: tex-vertex
  fragment: """
  #helper
  varying vec2 index;
  uniform sampler2D src;

  void main() {
    vec2 pos = TO_PIX(texture2D(src, index).xy);
    gl_FragColor.x = pos.x + pos.y * #sizex;
    gl_FragColor.y = 0.;
    gl_FragColor.z = 0.;
    gl_FragColor.w = 1.;
  }
  """
}

bitonic-helper = """

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

bitonic-sort-prog = avs.create-program {
  vertex: tex-vertex
  fragment: """
  #helper
  #bitonic-helper

  varying vec2 index;
  uniform float spread;
  uniform sampler2D src;
  vec4 current = texture2D(src, index);

  void main() {
    vec2 native = TO_PIX(index);
    float curr = native.x + native.y * #sizex;
    
    bool even = mod(floor(curr / spread), 2.) == 0.;
    vec2 bCoord = coordShift((even ? 1. : -1.) * spread, index);

    float a = current.x;
    float b = texture2D(src, bCoord).x;

    // fill result
    gl_FragColor = current;
    gl_FragColor.x = DIR_CMP(even, a, b);
  }
  """
}

bitonic-merge-prog = avs.create-program {
  vertex: tex-vertex
  fragment: """
  #helper
  #bitonic-helper
  
  varying vec2 index;
  uniform sampler2D src;
  uniform float count;
  vec4 current = texture2D(src, index);

  float blockSize = #sizeM. / count;

  void main() {
    vec2 native = TO_PIX(index);
    float curr = native.x + native.y * #sizex;
    bool even = mod(floor(curr / (blockSize / 2.)), 2.) == 0.;

    float shift = (blockSize - 1.) - (2. * mod(curr, blockSize));
    vec2 bCoord = coordShift(shift, index);

    float a = current.x;
    float b = texture2D(src, bCoord).x;

    // fill result
    gl_FragColor = current;
    gl_FragColor.x = DIR_CMP(even, a, b);
  }
  """
}

pass-bitonic = (back-buf, front-buf) ->
  b = [back-buf, front-buf]
  merge = sizeM / 2
  while merge >= 1
    avs.pass bitonic-merge-prog, b[1], src: b[0].texture, (b) ->
      b.prog.send-float \count merge
    b = [b[1], b[0]]

    sort = sizeM / merge / 4
    while sort >= 1
      avs.pass bitonic-sort-prog, b[1], src: b[0].texture, (b) ->
        b.prog.send-float \spread sort
      b = [b[1], b[0]]

      sort /= 2
    merge /= 2
  b[0]

back-buf  = avs.create-framebuffer size: size
front-buf = avs.create-framebuffer size: size

#<- avs.draw-loop 16

avs.pass fill-prog, back-buf
avs.pass convert-prog, front-buf, src: back-buf.texture

# sort array
sorted-buf = pass-bitonic front-buf, back-buf

# debug
avs.use-program main-prog, (prog) ->
  # debug with colors
  to-debug = sorted-buf
  avs.clear!
  avs.use-texture to-debug.texture
  prog.draw-display!

  # debug with points
  pixels = avs.pretty-print to-debug
  points <- avs.use-program points-prog
  points.draw-buffer (avs.create-buffer pixels), vars: 4
