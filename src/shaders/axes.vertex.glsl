attribute vec3 vertex;

$include "shaders/transform.glsl"

void main() {
  vec3 position = vertex - 0.5;
  gl_Position = vec4(processPos(position), 1.);
  gl_Position = perspective(gl_Position.xyz);
}
