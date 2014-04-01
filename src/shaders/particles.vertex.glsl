attribute vec3 vertex;
varying vec3 position;

void main() {
  position = vertex / 255.;
  gl_PointSize = 5.;
  gl_Position = vec4(vertex / 127.5 - 1., vertex.z / 255. + 1.);
}
