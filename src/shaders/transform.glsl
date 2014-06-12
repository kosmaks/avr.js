uniform float time;

float angle = (time / 2.) * $pi / 180.;

mat3 rot = mat3(
  cos(angle), 0., sin(angle),
  0., 1., 0.,
  -sin(angle), 0., cos(angle)
);

vec3 processPos(vec3 src) {
  return rot * src;
}

vec4 perspective(vec3 src) {
  return vec4(src, src.z + 1.2);
}
