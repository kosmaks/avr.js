precision mediump float;
uniform sampler2D particles;
uniform sampler2D pressures;
uniform sampler2D grid;
uniform sampler2D accessor;
uniform sampler2D densities;
varying vec2 index;

#define PRES(x) ($k * (x - $r0))
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
  vec3 curPart = texture2D(particles, index).xyz;
  vec3 neiDescriptor = texture2D(accessor, index).xyz;
  vec3 prevPressure = texture2D(pressures, index).xyz;
  float curDens = texture2D(densities, index).y;
  float curPres = PRES(curDens) / pow(curDens, 2.);

  int count = 0;
  float coef = - 45. / ($pi * $h6);
  vec3 result = vec3(0., 0., 0.);

  if (neiDescriptor.x >= 0.)
    for (float x = 0.; x >= 0.; x += 1.) {
      if (x >= neiDescriptor.z) break;

      vec2 gridIndex = UV(incBy(neiDescriptor.xy, x));
      vec2 neiIndex = texture2D(grid, gridIndex).xy;
      vec3 neiPart = texture2D(particles, neiIndex).xyz;

      float dist = distance(curPart, neiPart);

      if (dist >= $h || abs(dist) < 0.00001) continue;

      float neiDens = texture2D(densities, neiIndex).y;
      if (abs(neiDens) < 0.0001) continue;

      float neiPres = PRES(neiDens) / pow(neiDens, 2.);
      vec3 scaled = (curPart - neiPart) / dist;
      
      result += $m 
              * (curPres + neiPres) 
              * (coef * pow($h - dist, 2.) * scaled); 
    }

  gl_FragColor = vec4(
    prevPressure + result,
    1.
  );
}
