precision mediump float;
varying vec2 index;

void main() {
  float realX = index.x * $sizex;
  float realY = index.y * $sizey;
  float i = realY * $sizex + realX;
  float side = floor(pow($count, 1./3.));

  gl_FragColor.x = floor(i / side / side);
  gl_FragColor.y = floor(i / side) - side * gl_FragColor.x;
  gl_FragColor.z = i - side * gl_FragColor.y - side * side * gl_FragColor.x;

  gl_FragColor *= $factor / side;
  gl_FragColor.w = 1.;
}
