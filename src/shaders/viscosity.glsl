precision mediump float;
varying vec2 index;
uniform sampler2D viscosity;
uniform sampler2D velocities;
uniform sampler2D densities;
uniform sampler2D particles;
uniform sampler2D grid;
uniform sampler2D accessor;

#define UV(v) (vec2(v.x / $sizex, v.y / $sizey))
#define SCALE(x) ((x) * $scale)

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

void main() {
  vec3 prevViscosity = texture2D(viscosity, index).xyz;
  vec3 curPart = texture2D(particles, index).xyz * $scale;
  vec3 curVelocity = texture2D(velocities, index).xyz;
  float curDensity = texture2D(densities, index).y;
  vec3 neiDescriptor = texture2D(accessor, index).xyz;

  vec3 result = vec3(0., 0., 0.);
  float coef = $m * (45. / ($pi * pow(SCALE($h), 6.)));

  if (neiDescriptor.x >= 0.)
    for (float x = 0.; x >= 0.; x += 1.) {
      if (x >= neiDescriptor.z) break;

      vec2 gridIndex = UV(incBy(neiDescriptor.xy, x));
      vec2 neiIndex = texture2D(grid, gridIndex).xy;
      vec3 neiPart = texture2D(particles, neiIndex).xyz * $scale;
      float dist = distance(curPart, neiPart);
      if (dist >= SCALE($h)) continue;

      vec3 neiVelocity = texture2D(velocities, neiIndex).xyz;
      float neiDensity = texture2D(densities, index).y;
      if (abs(neiDensity) > 0.)
        result += coef * (SCALE($h) - dist) * (neiVelocity - curVelocity) / neiDensity;
    }

  if (abs(curDensity) > 0.)
    result *= $u / curDensity;


  gl_FragColor = vec4(
    prevViscosity + result,
    1.
  );
}
