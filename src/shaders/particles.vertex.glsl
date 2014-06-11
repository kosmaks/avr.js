attribute vec2 vertex;
uniform sampler2D positions;
uniform sampler2D colors;
uniform float time;
varying vec2 index;
/*varying vec3 position;*/
varying vec3 realPos;

float angle = (time / 2.) * $pi / 180.;
mat3 rot = mat3(
  cos(angle), 0., sin(angle),
  0., 1., 0.,
  -sin(angle), 0., cos(angle)
);

void main() {
  index = vertex.xy;
  gl_PointSize = 3.;
  gl_Position = texture2D(positions, index) / $factor;
  realPos = gl_Position.xyz * $factor;
  gl_Position = gl_Position - 0.5;
  gl_Position.w = 1.;

  gl_Position = vec4(rot * gl_Position.xyz, 1.);
  gl_Position.w = gl_Position.z + 1.;

  /*position = gl_Position.xyz;*/
}
