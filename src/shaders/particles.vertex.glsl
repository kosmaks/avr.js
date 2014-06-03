attribute vec2 vertex;
uniform sampler2D positions;
uniform sampler2D colors;
varying vec2 index;
varying vec3 position;

void main() {
  index = vertex.xy;
  gl_PointSize = 3.;
  gl_Position = texture2D(positions, index) / $factor;
  gl_Position = gl_Position - 0.5;
  /*gl_Position.x /= 3.;*/
  /*gl_Position.y /= 3.;*/
  /*gl_Position.z /= 3.;*/
  /*gl_Position.xyz = vec3(vertex.xy, 0.);*/
  gl_Position.w = gl_Position.z + 1.;
  position = gl_Position.xyz;
}
