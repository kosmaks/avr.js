precision mediump float;
uniform sampler2D sampler;
varying vec2 index;

void main() {
  vec3 data = texture2D(sampler, index).xyz / $factor;
  gl_FragColor = vec4(data, 1.);
}
