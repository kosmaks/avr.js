precision mediump float;
varying vec2 index;
uniform sampler2D particles;
uniform sampler2D grid;
uniform vec3 cmpCell;

#define EQ(x, y) (abs(x - y) < 0.001)
#define UV(v) (vec2(v.x / $sizex, v.y / $sizey))
#define WHILE_TRUE for(int _ = 1; _ > 0; _++)

#define MAX (1000)

float debug = 0.;

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

vec2 searchFor(float target) {
  vec2 cursor = floor(vec2($sizex / 2., $sizey / 2.));
  float value = texture2D(grid, UV(cursor)).w;
  bool found = false;
  float step = $count / 2.;

  for (float power = 2.; power > 0.; power += 1.) {
    if (EQ(value, target)) {
      found = true;
      break;
    }

    if (step < 1.) {
      break;
    }

    step = $count / pow(2., power);
    cursor = incBy(cursor, step * sign(target - value));
    value = texture2D(grid, UV(cursor)).w;
  }

  if (found) {
    vec2 lastSuccess = cursor;

    for (float shift = 1.; shift > 0.; shift += 1.) {
      vec2 test = incBy(cursor, -shift);

      value = texture2D(grid, UV(test)).w;
      if (EQ(value, target)) {
        lastSuccess = test;
      } else {
        break;
      }
    }

    return lastSuccess;
  }

  return vec2(-1., -1.);
}

void main() {
  vec4 curPart = texture2D(particles, index);
  vec3 curCell = floor(curPart.xyz / $h).xyz + cmpCell;

  if (curCell.x < 0. || 
      curCell.y < 0. || 
      curCell.z < 0. ||
      curCell.x >= $grid_size || 
      curCell.y >= $grid_size || 
      curCell.z >= $grid_size) {
    gl_FragColor = vec4(-1., -1., 0., 1.);
    return;
  }

  float key = curCell.x 
            + curCell.y * $grid_size 
            + curCell.z * $grid_size * $grid_size;

  vec2 start = searchFor(key);

  float count = 0.;
  if (start.x >= 0. && start.y >= 0.) {
    float last = 1.;
    for (float shift = 0.; shift >= 0.; shift += 1.) {
      vec2 uv = UV(incBy(start, shift));
      vec4 value = texture2D(grid, uv);
      last = value.w;
      if (!EQ(value.w, key)) break;
      count = shift;
    }
  } else {
    count = -1.;
  }

  gl_FragColor = vec4(start, count + 1., 1.);
  /*gl_FragColor = vec4(UV(start), (debug) / pow($grid_size, 3.), 1.);*/
}
