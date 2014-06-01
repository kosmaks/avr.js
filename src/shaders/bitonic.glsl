precision mediump float;
varying vec2 index;

uniform float spread;
uniform int isSort;
uniform sampler2D target;

void main() {
  vec2 real = floor(vec2(index.x * $sizex, index.y * $sizey));
  float realIndex = real.x + real.y * $sizex;
  bool even = mod(realIndex, spread) < (spread / 2.);
  float minus = even ? 1. : -1.;

  float mid = (spread - 1.) / 2.;
  float shift;

  if (isSort != 0) {
    shift = 2. * abs(mod(realIndex, spread) - mid);
  } else {
    shift = ceil(mid);
  }

  float wide = real.x + shift * minus;
  vec2 delta = vec2(
    0.5 / $sizex,
    0.5 / $sizey
  );

  vec2 i = index;
  vec2 j = vec2(
    mod(wide, $sizex) / $sizex,
    (real.y + floor(wide / $sizex)) / $sizey
  ) + delta;

  vec4 a = texture2D(target, i);
  vec4 b = texture2D(target, j);

  if (abs(a.w - b.w) < 0.00001) 
    gl_FragColor = a;
  else
    gl_FragColor = (even == (a.w < b.w)) ? a : b;
}
