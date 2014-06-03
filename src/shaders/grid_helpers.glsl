#define PRES(x) ($k * (x - $r0))
#define UV(v) (vec2((v).x / $sizex, (v).y / $sizey))
#define SCALE(x) ((x) * $scale)

const float H = SCALE($h);
const vec3 vec3zero = vec3(0., 0., 0.);
const vec3 vec3one = vec3(1., 1., 1.);

vec2 incBy(vec2 source, float value) {
  source = floor(source);
  float wide = source.x + value;
  vec2 res = vec2(
    mod(wide, $sizex),
    source.y + floor(wide / $sizex)
  );
  if (res.y >= $sizey) return vec2(0., 0.);
  return res;
}

vec3 project(vec3 target, vec3 source, vec3 d) {
  vec3 temp = target - source;
  temp *= vec3(-1., -1., -1.) * d + vec3one * (1. - d);
  return temp + source;
}
