precision mediump float;
uniform sampler2D sampler;
varying vec2 index;

float test = $hi;

void main() {
  vec2 _ = index;
  gl_FragColor = texture2D(sampler, index);
}

