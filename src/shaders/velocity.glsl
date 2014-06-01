precision mediump float;
uniform sampler2D back;
uniform sampler2D particles;
varying vec2 index;

vec3 gravity = vec3(0.00, -0.1, 0.00);

void main() {
  vec3 curPos = texture2D(particles, index).xyz;
  vec3 prevVel = texture2D(back, index).xyz;
  vec3 result = prevVel + gravity;

  curPos += result;
  if (curPos.x < $lobound || curPos.x > $hibound) result.x *= -0.0;
  if (curPos.y < $lobound || curPos.y > $hibound) result.y *= -0.5;
  if (curPos.z < $lobound || curPos.z > $hibound) result.z *= -0.0;

  gl_FragColor = vec4(result, 1.);
}
