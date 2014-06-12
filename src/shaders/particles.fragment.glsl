precision mediump float;
uniform sampler2D colors;
varying vec3 index;
varying vec3 position;
varying vec3 realPos;

const vec3 lse = vec3(0.0, 1.5, 0.0);
const vec3 lightSource = vec3(0., 2., 0.);

void main() {
  if (realPos.x < $lobound ||
      realPos.x > $hibound ||
      realPos.y < $lobound ||
      realPos.y > $hibound ||
      realPos.z < $lobound ||
      realPos.z > $hibound) {
    gl_FragColor = vec4(0., 0., 0., 0.);
    return;
  }

  gl_FragColor = texture2D(colors, index.xy) / $factor;
  /*vec3 result = vec3(index.x, 0.5, index.y);*/
  /*gl_FragColor = vec4(result, 0.7);*/

  /*gl_FragColor = (index.z > 0.5)*/
               /*? vec4(1.0, 0.0, 0.0, 0.0)*/
               /*: vec4(0.0, 0.0, 1.0, 1.0);*/
}
