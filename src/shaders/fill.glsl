precision mediump float;
varying vec2 index;

void main() {
  gl_FragColor = vec4(index.x, 0.5 + 0.5 * index.y, index.y, 1.) 
               * $factor;
  gl_FragColor.w = 1.;
}
