precision mediump float; 
uniform sampler2D particles;
varying vec2 index;

void main() {
  vec3 curPart = texture2D(particles, index).xyz;
  int count = 0;
  float result = 0.;

  float coef = 315. / (64. * 3.14 * $h9);

  for (float x = 0.; x < $sizex; x += 1.) {
    for (float y = 0.; y < $sizey; y += 1.) {

      vec3 neiPart = texture2D(particles, vec2(
                       x / $sizex,
                       y / $sizey
                     )).xyz;
      float dist = distance(curPart, neiPart);

      if (dist >= $h) continue;

      float length2 = pow(dist, 2.);
      
      result += $m * coef * pow($h2 - length2, 3.);
    }
  }

  gl_FragColor = vec4(result / 4000000., result, 0., 1.);
}
