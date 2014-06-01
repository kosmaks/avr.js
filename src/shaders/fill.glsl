precision mediump float;
varying vec2 index;

float shrinkX = 0.3;
float shrinkY = 0.3;
float shrinkZ = 0.3;

float seed = 1.;
float random() {
  return fract((seed += index.y) * 523.8223652729 * index.x);
}

void main() {
  /*gl_FragColor = vec4(index.x, 0., index.y, 1.)*/
               /** $factor;*/
  gl_FragColor = vec4(random(), random(), random(), 1.)
               * $factor;
}
