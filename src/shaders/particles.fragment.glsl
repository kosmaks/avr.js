precision mediump float;
uniform sampler2D colors;
varying vec2 index;

void main() {
  gl_FragColor = texture2D(colors, index) / 10000000.;
  /*gl_FragColor = texture2D(colors, index) / $factor;*/
  /*gl_FragColor.x = gl_FragColor.y < 0. ? 1. : 0.;*/
  /*gl_FragColor.z = 0.;*/
  /*gl_FragColor.w = 1.;*/
  /*gl_FragColor = vec4(0.4, 0.8, 1., 1.);*/
}
