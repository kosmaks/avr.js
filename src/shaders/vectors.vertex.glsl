attribute vec3 vertex;
uniform sampler2D positions;
uniform sampler2D colors;
uniform sampler2D vectors;
uniform float scale;
varying vec3 index;
/*varying vec3 position;*/
varying vec3 realPos;

$include "shaders/transform.glsl"

void main() {
  index = vertex;
  vec3 position = texture2D(positions, index.xy).xyz;
  if (vertex.z > 0.5) {
    vec3 vector = texture2D(vectors, index.xy).xyz;
    position += vector * scale;
  }
  realPos = position;

  gl_PointSize = 3.;
  gl_Position = vec4(position, 1.) / $factor;
  gl_Position = gl_Position - 0.5;
  gl_Position.w = 1.;

  gl_Position = vec4(processPos(gl_Position.xyz), 1.);
  gl_Position = perspective(gl_Position.xyz);
}
