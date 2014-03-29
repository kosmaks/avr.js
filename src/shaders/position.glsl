precision mediump float;
uniform sampler2D back;
uniform sampler2D velocities;
varying vec2 index;

void main() {
  vec3 prevPos = texture2D(back, index).xyz;
  vec3 velocity = texture2D(velocities, index).xyz;
  vec3 result = prevPos + velocity;
  gl_FragColor = vec4(result, 1.);
}
