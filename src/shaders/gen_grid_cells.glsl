precision mediump float;
varying vec2 index;

uniform sampler2D particles;

void main() {
  vec3 curPart = texture2D(particles, index).xyz;
  vec3 curCell = floor(curPart / $h);
  float key = curCell.x 
            + curCell.y * $grid_size 
            + curCell.z * $grid_size * $grid_size;

  gl_FragColor = vec4(
    index,
    key / pow($grid_size, 3.),
    key
  );
}
