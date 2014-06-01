precision mediump float;
varying vec2 index;

float shrinkX = 0.3;
float shrinkY = 0.3;
float shrinkZ = 0.3;

float seed = 1.;
float random() {
  return fract((seed += index.y) * 523.8223652729 * index.x) + 0.1;
}

void main() {
  gl_FragColor = vec4(index.x, 1., index.y, 1.) * $factor;
  /*gl_FragColor = vec4(random(), random(), random(), 1.) * $factor;*/
  /*if (index.y < 0.5)*/
    /*gl_FragColor = vec4(index.x, 0.3, index.y * 2., 1.);*/
  /*else*/
    /*gl_FragColor = vec4(index.x, 0.8, index.y * 2. - 1., 1.);*/
}
