precision mediump float;
uniform sampler2D colors;
varying vec2 index;
varying vec3 position;

const vec3 lse = vec3(0.0, 1.5, 0.0);
const vec3 lightSource = vec3(0., 2., 0.);

void main() {
  /*gl_FragColor = texture2D(colors, index);*/
  /*gl_FragColor.y /= 1000000.;*/
  gl_FragColor = texture2D(colors, index) / $factor;
  /*gl_FragColor.x = gl_FragColor.y < 0. ? 1. : 0.;*/
  /*gl_FragColor.z = 0.;*/
  /*gl_FragColor.x = 0.;*/
  vec3 normal = vec3(0., 1., 0.);
  vec3 directionToLse = normalize(lse - position);

  float diffuseDot = max(dot(directionToLse, normal), 0.);

  vec3 reflectionEye = reflect(-directionToLse, normal);
  vec3 surfaceToViewerEye = normalize(-position);
  float specularDot = max(dot(reflectionEye, surfaceToViewerEye), 0.);
  float specularFactor = pow(specularDot, 2.0);

  vec3 ambient = vec3(0.5, 0.5, 0.5);

  vec3 result = vec3(0.0, 0.2, 1.);
  result *= (
    ambient + 
    diffuseDot * lightSource +
    specularFactor * lightSource
  );
  gl_FragColor = vec4(result, 0.7);
}
