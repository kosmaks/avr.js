attribute vec2 vertex;
uniform sampler2D positions;
uniform sampler2D colors;
varying vec2 index;

void main() {
  index = vertex.xy;
  gl_PointSize = 5.;
  gl_Position = texture2D(positions, index) / $factor;
  gl_Position = gl_Position - 0.5;
  /*gl_Position.xyz = vec3(vertex.xy, 0.);*/
  gl_Position.w = gl_Position.z + 1.;
  /*vec4 position = vertex / 255.;*/
  /*float indexFloat = position.w * $rect;*/
  /*float indexY = floor(indexFloat / $discr);*/
  /*float indexX = indexFloat - indexY * $discr;*/

  /*if (indexY > $discr) {*/
    /*indexX = indexY * $discr - ($discr * $discr);*/
    /*indexY = $discr;*/
  /*}*/

  /*index = vec2(indexX, indexY) / $discr;*/

  /*gl_PointSize = 5.;*/
  /*gl_Position = vec4(vertex.xyz / 127.5 - 1., vertex.z / 255. + 1.);*/
}
