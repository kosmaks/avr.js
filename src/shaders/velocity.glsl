precision mediump float;
uniform sampler2D back;
uniform sampler2D particles;
uniform sampler2D pressures;
uniform sampler2D viscosity;
varying vec2 index;

vec3 gravity = vec3(0.0, -0.098, 0.00);

void main() {
  vec3 curPos = texture2D(particles, index).xyz;
  vec3 prevVel = texture2D(back, index).xyz;
  vec3 curPressure = texture2D(pressures, index).xyz;
  vec3 curViscosity = texture2D(viscosity, index).xyz;

  vec3 result = prevVel;
  result += gravity;
  result -= curPressure;
  result += curViscosity;


  curPos += result;
  if (curPos.x < $lobound || curPos.x > $hibound) result.x *= -0.1;
  if (curPos.y < $lobound/* || curPos.y > $hibound*/) result.y *= -0.1;
  if (curPos.z < $lobound || curPos.z > $hibound) result.z *= -0.1;

  /*result += 0. - curPressure + curViscosity;*/

  gl_FragColor = vec4(result, 1.);
}
