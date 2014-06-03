precision mediump float;
varying vec2 index;
uniform sampler2D particles;
uniform sampler2D grid;
uniform sampler2D accessor;
uniform sampler2D densities;

$include "shaders/grid_helpers.glsl"

float coef = 315. / (64. * 3.14 * pow(SCALE($h), 9.));
float h2 = pow(H, 2.);
vec3 curPart;

float debug = 0.;

float handleNeighbour(vec3 neiPart) {
  float dist = distance(curPart, neiPart);
  if (dist < H) {
    debug = 1.;
    float length2 = pow(dist, 2.);
    return $m * coef * pow(h2 - length2, 3.);
  }
  return 0.;
}

void main() {
  float prevCount = texture2D(densities, index).x;
  float prevDensity = texture2D(densities, index).y;
  vec3 neiDescriptor = texture2D(accessor, index).xyz;

  curPart = texture2D(particles, index).xyz * $scale;

  float result = 0.;

  if (neiDescriptor.z > 0.)
    for (float x = 0.; x >= 0.; x += 1.) {
      if (x >= neiDescriptor.z || x >= $max_part) break;

      vec2 gridIndex = UV(incBy(neiDescriptor.xy, x));
      vec2 neiIndex = texture2D(grid, gridIndex).xy;
      vec3 neiPart = texture2D(particles, neiIndex).xyz * $scale;

      result += handleNeighbour(neiPart);
      result += handleNeighbour(
        project(neiPart, vec3(0., $lobound * $scale, 0.), vec3(0., 1., 0.))
      );
    }

  /*float prevDebug = texture2D(densities, index).x;*/
  gl_FragColor = vec4(
    0.,
    /*prevDebug + debug,*/
    prevDensity + result,
    0.,
    1.
  );
}
