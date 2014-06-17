uniform float time;
uniform vec2 mouse;
uniform vec3 rotation;

#define TOUCH_SPREAD (0.05)

float angle = (rotation.y / 2.) * $pi / 180.;

vec3 processPos(vec3 src) {
  mat3 rot = mat3(
    cos(angle), 0., sin(angle),
    0., 1., 0.,
    -sin(angle), 0., cos(angle)
  );

  return rot * src;
}

vec4 perspective(vec3 src) {
  return vec4(src, src.z + 1.3);
}

bool mouseTouch(vec3 part) {
  if (mouse.x < -1.5) { return false; }
  else {
    vec4 persp = perspective(processPos(part / $factor - 0.5));
    persp /= persp.w;
    return (abs(persp.x - mouse.x) < TOUCH_SPREAD &&
            abs(persp.y - mouse.y) < TOUCH_SPREAD);
  }
}
