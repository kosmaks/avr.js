<- (window.onload=)

avs = new AVS document.getElementById \display

size     = [16, 16]
sizeM    = size[0] * size[1]
h        = 1.0
m        = 1
k        = 0.01
u        = 1
restDens = 1.0

sizex     = size[0].to-fixed 8
sizey     = size[1].to-fixed 8
h_        = h.to-fixed 8
m_        = m.to-fixed 8
k_        = k.to-fixed 8
u_        = u.to-fixed 8
restDens_ = restDens.to-fixed 8

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
\#define TO_PIX2(x, y) vec2(X_TO_PIX(x), Y_TO_PIX(y))
\#define TO_TEX2(x, y) vec2(X_TO_TEX(x), Y_TO_TEX(y))

\#define FLOOR_EQ(x, y) (floor(x) == floor(y))
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

repr-prog = avs.create-program {
  vertex: tex-vertex
  fragment: """
  precision mediump float;
  uniform sampler2D sampler;
  varying vec2 index;

  void main() {
    gl_FragColor = texture2D(sampler, index) / 100.;
  }
  """
}

fill-prog = avs.create-program {
  vertex: tex-vertex
  fragment: """
  precision mediump float;
  varying vec2 index;

  void main() {
    gl_FragColor = vec4(
      index.x * 100.,
      index.y * 100.,
      0.,
      1.
    );
  }
  """
}

zero-prog = avs.create-program {
  vertex: tex-vertex
  fragment: """
  precision mediump float;
  varying vec2 index;

  void main() {
    vec2 _ = index;
    gl_FragColor = vec4(0., 0., 0., 1.);
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

density-prog = avs.create-program {
  vertex: tex-vertex
  fragment: """
  #helper
  uniform sampler2D particles;
  varying vec2 index;

  void main() {
    vec2 curPart = texture2D(particles, index).xy;
    float density = 0.;
    float h9 = #{Math.pow(h, 9).to-fixed(8)};
    float h2 = #{Math.pow(h, 2).to-fixed(8)};
    float k = #m_ * 315. / (64. * 3.14 * h9);

    vec2 curPix = TO_PIX(index);

    for (float x = 0.; x < #sizex; ++x)
    for (float y = 0.; y < #sizey; ++y) {
      if (FLOOR_EQ(x, curPix.x) && FLOOR_EQ(y, curPix.y)) continue;
      vec2 pos = TO_TEX2(x, y);
      vec2 neiPart = texture2D(particles, pos).xy;
      float dist = distance(neiPart, curPart);
      if (dist > #h_) continue;

      density += k * pow(h2 - pow(dist, 2.), 3.);
    }

    gl_FragColor = vec4(density, 0., 0., 1.);
  }
  """
}

pressure-prog = avs.create-program {
  vertex: tex-vertex
  fragment: """
  #helper
  uniform sampler2D particles;
  uniform sampler2D densities;
  varying vec2 index;

  void main() {
    vec2 curPart = texture2D(particles, index).xy;
    float curDens = texture2D(densities, index).x;

    vec2 gradP = vec2(0., 0.);
    float h6 = #{Math.pow(h, 6).to-fixed(8)};
    float k = #m_ * (-45. / (3.14 * h6));

    vec2 curPix = TO_PIX(index);
    float curPres = #k_ * (curDens - #restDens_);

    for (float x = 0.; x < #sizex; ++x)
    for (float y = 0.; y < #sizey; ++y) {
      if (FLOOR_EQ(x, curPix.x) && FLOOR_EQ(y, curPix.y)) continue;
      vec2 pos = TO_TEX2(x, y);
      vec2 neiPart = texture2D(particles, pos).xy;
      float dist = distance(neiPart, curPart);
      if (dist > #h_) continue;

      float neiDens = texture2D(densities, pos).x;
      float neiPres = #k_ * (neiDens - #restDens_);

      if (curDens == 0. || neiDens == 0. || dist == 0.) continue; 

      vec2 mgradW = k * pow(#h_ - dist, 2.) * (curPart - neiPart) / dist;
      vec2 grapPi = ((curPres / pow(curDens, 2.)) + (neiPres / pow(neiDens, 2.))) * mgradW;

      gradP += grapPi;
    }

    gl_FragColor = vec4(gradP, 0., 1.);
  }
  """
}

viscosity-prog = avs.create-program {
  vertex: tex-vertex
  fragment: """
  #helper
  uniform sampler2D velocities;
  uniform sampler2D densities;
  uniform sampler2D particles;
  varying vec2 index;

  void main() {
    vec2 curVel = texture2D(velocities, index).xy;
    vec2 curPart = texture2D(particles, index).xy;
    float curDens = texture2D(densities, index).x;

    vec2 gradU = vec2(0., 0.);
    float h6 = #{Math.pow(h, 6).to-fixed(8)};
    float k = #m_ * (45. / (3.14 * h6));

    vec2 curPix = TO_PIX(index);
    float curPres = #k_ * (curDens - #restDens_);

    for (float x = 0.; x < #sizex; ++x)
    for (float y = 0.; y < #sizey; ++y) {
      if (FLOOR_EQ(x, curPix.x) && FLOOR_EQ(y, curPix.y)) continue;
      vec2 pos = TO_TEX2(x, y);
      vec2 neiPart = texture2D(particles, pos).xy;
      float dist = distance(neiPart, curPart);
      if (dist > #h_) continue;

      vec2 neiVel = texture2D(velocities, pos).xy;
      float neiDens = texture2D(densities, pos).x;
      float neiPres = #k_ * (neiDens - #restDens_);

      if (neiDens != 0.)
        gradU += k * (#h_ - dist) * (neiVel - curVel) / neiDens;
    }

    if (curDens == 0.)
      gradU = vec2(0., 0.);
    else
      gradU *= #u_ / curDens;

    gl_FragColor = vec4(gradU, 0., 1.);
  }
  """
}

velocity-prog = avs.create-program {
  vertex: tex-vertex
  fragment: """
  #helper
  uniform sampler2D backbuf;
  uniform sampler2D pressures;
  uniform sampler2D viscosities;
  uniform sampler2D particles;
  varying vec2 index;

  vec2 gravity = vec2(0.0000, -0.002);

  void main() {
    vec2 velocity = texture2D(backbuf, index).xy;
    vec2 part     = texture2D(particles, index).xy;
    vec2 gradP    = texture2D(pressures, index).xy;
    vec2 gradU    = texture2D(viscosities, index).xy;

    velocity += gravity;
    velocity -= gradP;
    velocity += gradU;

    if (part.x + velocity.x > 1.0 || part.x + velocity.x < 0.0) velocity.x *= 0.;
    if (part.y + velocity.y > 1.0 || part.y + velocity.y < 0.0) velocity.y *= 0.;

    gl_FragColor = vec4(velocity, 0., 1.);
  }
  """
}

particles-prog = avs.create-program {
  vertex: tex-vertex
  fragment: """
  #helper
  uniform sampler2D backbuf;
  uniform sampler2D velocities;
  varying vec2 index;

  void main() {
    vec2 position = texture2D(backbuf, index).xy;
    vec2 velocity = texture2D(velocities, index).xy;

    position += velocity;
    position.x = min(1.0, position.x);
    position.x = max(0.0, position.x);
    position.y = min(1.0, position.y);
    position.y = max(0.0, position.y);

    gl_FragColor = vec4(position, 0., 1.);
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

part = {
  back: avs.create-framebuffer(size: size)
  front: avs.create-framebuffer(size: size)
}

vel = {
  back: avs.create-framebuffer(size: size)
  front: avs.create-framebuffer(size: size)
}

density-buf   = avs.create-framebuffer size: size
pressure-buf  = avs.create-framebuffer size: size
viscosity-buf = avs.create-framebuffer size: size
repr-buf      = avs.create-framebuffer size: size

avs.pass fill-prog, part.back
avs.pass zero-prog, vel.back

trig = false

#avs.draw-loop 16 ->
document.getElementById(\next).onclick = ->

  trig := not trig
  back = if trig then \back else \front
  front = if trig then \front else \back

  avs.pass density-prog, density-buf, {
    particles: part[back].texture
  }

  avs.pass pressure-prog, pressure-buf, {
    particles: part[back].texture,
    densities: density-buf.texture
  }

  avs.pass viscosity-prog, viscosity-buf, {
    velocities: vel[back].texture,
    particles: part[back].texture,
    densities: density-buf.texture
  }

  avs.pass velocity-prog, vel[front], {
    backbuf: vel[back].texture,
    particles: part[back].texture,
    pressures: pressure-buf.texture,
    viscosities: viscosity-buf.texture,
  }

  avs.pass particles-prog, part[front], {
    backbuf: part[back].texture,
    velocities: vel[front].texture,
  }

  avs.pass repr-prog, repr-buf, {
    sampler: part[front].texture,
  }

  #avs.pass convert-prog, front-buf, src: back-buf.texture
  # sort array
  #sorted-buf = pass-bitonic front-buf, back-buf

  # debug
  avs.use-program main-prog, (prog) ->
    # debug with colors
    #to-debug = back-buf
    #to-debug = viscosity-buf
    avs.clear!
    #avs.use-texture to-debug.texture
    #prog.draw-display!

    # debug with points
    #pixels = avs.pretty-print repr-buf
    pixels = avs.read-pixels repr-buf
    points <- avs.use-program points-prog
    points.draw-buffer (avs.create-buffer pixels), vars: 4
