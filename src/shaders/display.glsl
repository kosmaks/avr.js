precision mediump float;
uniform sampler2D sampler;
varying vec2 index;

void main() {
  gl_FragColor = texture2D(sampler, index);
}

