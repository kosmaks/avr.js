precision mediump float;
varying vec2 index;
uniform sampler2D viscosity;
uniform sampler2D velocities;
uniform sampler2D densities;
uniform sampler2D particles;
uniform sampler2D grid;
uniform sampler2D accessor;

$include "shaders/grid_helpers.glsl"

float coef = $m * (45. / ($pi * pow(H, 6.)));
vec3 curPart, curVelocity;
float curDensity;
vec3 debug = vec3(0., 0., 0.);

vec3 handleNeighbour(vec3 neiPart, vec3 neiVelocity, float neiDensity) {
  float dist = distance(curPart, neiPart);
  if (dist < H && neiDensity != 0.) {
    return coef * (H - dist) * (neiVelocity - curVelocity) / neiDensity;
  }
  return vec3(0., 0., 0.);
}


void main() {
  vec3 prevViscosity = texture2D(viscosity, index).xyz;
  curPart = texture2D(particles, index).xyz * $scale;
  curVelocity = texture2D(velocities, index).xyz;
  curDensity = texture2D(densities, index).y;
  vec3 neiDescriptor = texture2D(accessor, index).xyz;

  vec3 result = vec3(0., 0., 0.);

  if (neiDescriptor.z > 0.)
    for (float x = 0.; x >= 0.; x += 1.) {
      if (x >= neiDescriptor.z || x >= $max_part) break;

      vec2 gridIndex = UV(incBy(neiDescriptor.xy, x));
      vec2 neiIndex = texture2D(grid, gridIndex).xy;
      vec3 neiPart = texture2D(particles, neiIndex).xyz * $scale;
      float neiDensity = texture2D(densities, neiIndex).y;
      vec3 neiVelocity = texture2D(velocities, neiIndex).xyz;
      /*debug = neiPart / $scale / $factor;*/

      vec3 yNeg = vec3(1., -1., 1.);
      result += handleNeighbour(neiPart, neiVelocity, neiDensity);
      result += handleNeighbour(
        project(neiPart, vec3(0., $lobound * $scale, 0.), vec3(0., 1., 0.)), 
        neiVelocity * yNeg, 
        neiDensity
      );
    }

  if (curDensity != 0.)
    result *= $u / curDensity;

  gl_FragColor = vec4(
    prevViscosity + result,
    /*curPart / $scale / $factor,*/
    /*debug,*/
    /*0.,*/
    /*0.,*/
    1.
  );
}
