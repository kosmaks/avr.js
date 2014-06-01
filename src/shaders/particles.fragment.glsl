precision mediump float;
uniform sampler2D colors;
varying vec2 index;

void main() {
  gl_FragColor = abs(texture2D(colors, index)) * 10000.;
  /*gl_FragColor.x = index.x;*/
  /*gl_FragColor.y = 0.;*/
  /*gl_FragColor.z = 0.;//index.x;*/
  gl_FragColor.w = 1.;
}
