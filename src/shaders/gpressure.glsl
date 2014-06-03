precision mediump float;
uniform sampler2D particles;
uniform sampler2D densities;
varying vec2 index;

$include "shaders/grid_helpers.glsl"

void main() {
  vec3 curPart = texture2D(particles, index).xyz * $scale;
  float curDens = texture2D(densities, index).y;
  float curPres = PRES(curDens) / pow(curDens, 2.);
  int count = 0;
  bool broke = false;

  float coef = - 45. / ($pi * pow(H, 6.));
  vec3 result = vec3(0., 0., 0.);

  for (float x = 0.; x < $sizex; x += 1.) {
    for (float y = 0.; y < $sizey; y += 1.) {

      vec2 neiPos = vec2(x / $sizex, y / $sizey);
      vec3 neiPart = texture2D(particles, neiPos).xyz * $scale;
      float dist = distance(curPart, neiPart);

      if (dist >= H || abs(dist) < 0.00001) continue;

      float neiDens = texture2D(densities, neiPos).y;
      /*if (abs(neiDens) < 0.0001) continue;*/

      float neiPres = PRES(neiDens) / pow(neiDens, 2.);
      vec3 scaled = (curPart - neiPart) / dist;

      count += 1;
      
      result += $m 
              * (curPres + neiPres) 
              * (coef * pow(H - dist, 2.) * scaled); 
    }

    if (broke) break;
  }

  /*gl_FragColor = vec4(float(count), 0., 0., 1.);*/
  /*gl_FragColor = vec4(curPart, 1.);*/
  gl_FragColor = vec4(result, 1.);
}
