precision mediump float;
varying vec3 position;

void main() {
  gl_FragColor = vec4(position.z * 0.5, position.z * 0.5, 1., 1.);
}
