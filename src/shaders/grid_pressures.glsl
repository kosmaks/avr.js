precision mediump float;
uniform sampler2D particles;
uniform sampler2D pressures;
uniform sampler2D grid;
uniform sampler2D accessor;
uniform sampler2D densities;
varying vec2 index;

$include "shaders/grid_helpers.glsl"

float coef = - 45. / ($pi * pow(H, 6.));
vec3 curPart;
float curDens, curPres;
float debug = 0.;

vec3 handleNeighbour(vec3 neiPart, float neiDens) {
  float dist = distance(curPart, neiPart);
  if (dist < H && abs(neiDens) > 0. && abs(dist) > 0.0001) {
    float neiPres = PRES(neiDens) / pow(neiDens, 2.);
    vec3 scaled = (curPart - neiPart) / dist;
    return $m 
         * (curPres + neiPres) 
         * (coef * pow(H - dist, 2.) * scaled); 
  }

  return vec3(0., 0., 0.);
}

void main() {
  vec3 neiDescriptor = texture2D(accessor, index).xyz;
  vec3 prevPressure = texture2D(pressures, index).xyz;

  curPart = texture2D(particles, index).xyz * $scale;
  curDens = texture2D(densities, index).y;
  curPres = PRES(curDens) / pow(curDens, 2.);

  vec3 result = vec3(0., 0., 0.);

  if (neiDescriptor.z > 0.)
    for (float x = 0.; x >= 0.; x += 1.) {
      if (x >= neiDescriptor.z || x >= $max_part) break;

      vec2 gridIndex = UV(incBy(neiDescriptor.xy, x));
      vec2 neiIndex = texture2D(grid, gridIndex).xy;
      vec3 neiPart = texture2D(particles, neiIndex).xyz * $scale;
      float neiDens = texture2D(densities, neiIndex).y;

      result += handleNeighbour(neiPart, neiDens);
      result += handleNeighbour(
        project(neiPart, vec3(0., $lobound * $scale, 0.), vec3(0., 1., 0.)), 
        neiDens
      );
    }

  gl_FragColor = vec4(
    prevPressure + result,
    1.
  );
  /*gl_FragColor = vec4(*/
    /*prevPressure.x + (debug / 100.),*/
    /*[>prevPressure.x + float(count),<]*/
    /*[>prevPressure.x + neiDescriptor.x,<]*/
    /*0., 0., 1.*/
    /*[>.<]*/
  /*);*/
}
