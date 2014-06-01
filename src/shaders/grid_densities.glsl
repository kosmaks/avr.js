precision mediump float;
varying vec2 index;
uniform sampler2D particles;
uniform sampler2D grid;
uniform sampler2D accessor;
uniform sampler2D densities;

#define UV(v) (vec2(v.x / $sizex, v.y / $sizey))

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
  float prevDensity = texture2D(densities, index).y;
  vec3 curPart = texture2D(particles, index).xyz;
  vec3 neiDescriptor = texture2D(accessor, index).xyz;


  float result = 0.;
  float coef = 315. / (64. * 3.14 * $h9);

  if (neiDescriptor.x >= 0.)
    for (float x = 0.; x >= 0.; x += 1.) {
      if (x >= neiDescriptor.z) break;

      vec2 gridIndex = UV(incBy(neiDescriptor.xy, x));
      vec2 neiIndex = texture2D(grid, gridIndex).xy;
      vec3 neiPart = texture2D(particles, neiIndex).xyz;

      float dist = distance(curPart, neiPart);

      if (dist >= $h) continue;

      float length2 = pow(dist, 2.);
      result += $m * coef * pow($h2 - length2, 3.);
    }

  gl_FragColor = vec4(
    /*0.,*/
    (prevDensity + result) / 100.,
    prevDensity + result,
    0.,
    1.
  );
}
