// Generated by LiveScript 1.2.0
(function(){
  (function(it){
    return window.onload = it;
  })(function(){
    var avs, size, sizeM, sizex, sizey, h, m, texVertex, helper, mainProg, pointsProg, fillProg, convertProg, bitonicHelper, bitonicSortProg, bitonicMergeProg, passBitonic, backBuf, frontBuf;
    avs = new AVS(document.getElementById('display'));
    size = [16, 16];
    sizeM = size[0] * size[1];
    sizex = size[0] + ".0";
    sizey = size[1] + ".0";
    h = 0.0002;
    m = 1;
    texVertex = "attribute vec2 vertex;\nvarying vec2 index;\n\nvoid main() {\n  index.x = (vertex.x > 0.) ? 1. : 0.;\n  index.y = (vertex.y > 0.) ? 1. : 0.;\n  gl_Position = vec4(vertex, 0., 1.);\n}";
    helper = "precision mediump float;\n#define AT(arr, x, y) texture2D(arr, vec2(x / " + sizex + ", y / " + sizey + ")\n\n#define X_TO_TEX(val) (val / " + sizex + ")\n#define Y_TO_TEX(val) (val / " + sizey + ")\n#define X_TO_PIX(val) floor(val * " + sizex + ")\n#define Y_TO_PIX(val) floor(val * " + sizey + ")\n\n#define TO_PIX(vec) vec2(X_TO_PIX(vec.x), Y_TO_PIX(vec.y))\n#define TO_TEX(vec) vec2(X_TO_TEX(vec.x), Y_TO_TEX(vec.y))";
    mainProg = avs.createProgram({
      vertex: texVertex,
      fragment: "precision mediump float;\nuniform sampler2D sampler;\nvarying vec2 index;\n\nvoid main() {\n  gl_FragColor = texture2D(sampler, index);\n  gl_FragColor.w = 1.;\n}"
    });
    pointsProg = avs.createProgram({
      vertex: "attribute vec2 vertex;\n\nvoid main() {\n  gl_PointSize = 5.;\n  gl_Position = vec4((vertex / 127.5) - 1., 0., 1.);\n}",
      fragment: "void main() {\n  gl_FragColor = vec4(0.1, 0.4, 1., 1.);\n}"
    });
    fillProg = avs.createProgram({
      vertex: texVertex,
      fragment: "precision mediump float;\nvarying vec2 index;\n\nvoid main() {\n  vec2 native = floor(vec2(index.x * " + sizex + ", index.y * " + sizey + "));\n  gl_FragColor = vec4(\n    (1. - index.x),\n    (1. - index.y),\n    0.,\n    1.\n  );\n}"
    });
    convertProg = avs.createProgram({
      vertex: texVertex,
      fragment: "" + helper + "\nvarying vec2 index;\nuniform sampler2D src;\n\nvoid main() {\n  vec2 pos = TO_PIX(texture2D(src, index).xy);\n  gl_FragColor.x = pos.x + pos.y * " + sizex + ";\n  gl_FragColor.y = 0.;\n  gl_FragColor.z = 0.;\n  gl_FragColor.w = 1.;\n}"
    });
    bitonicHelper = "\nvec2 coordShift(float shift, vec2 src) {\n  vec2 index = TO_PIX(src);\n  float wide = index.x + shift;\n  float indexX = mod(wide, " + sizex + ");\n  float indexY = index.y + floor(wide / " + sizex + ");\n  if (indexY > " + sizey + ") indexY -= " + sizey + ";\n  else if (indexY < 0.) indexY += " + sizey + ";\n  return TO_TEX(vec2(indexX, indexY));\n}\n\n#define DIR_CMP(forward, a, b) (forward == (a < b) ? a : b)";
    bitonicSortProg = avs.createProgram({
      vertex: texVertex,
      fragment: "" + helper + "\n" + bitonicHelper + "\n\nvarying vec2 index;\nuniform float spread;\nuniform sampler2D src;\nvec4 current = texture2D(src, index);\n\nvoid main() {\n  vec2 native = TO_PIX(index);\n  float curr = native.x + native.y * " + sizex + ";\n  \n  bool even = mod(floor(curr / spread), 2.) == 0.;\n  vec2 bCoord = coordShift((even ? 1. : -1.) * spread, index);\n\n  float a = current.x;\n  float b = texture2D(src, bCoord).x;\n\n  // fill result\n  gl_FragColor = current;\n  gl_FragColor.x = DIR_CMP(even, a, b);\n}"
    });
    bitonicMergeProg = avs.createProgram({
      vertex: texVertex,
      fragment: "" + helper + "\n" + bitonicHelper + "\n\nvarying vec2 index;\nuniform sampler2D src;\nuniform float count;\nvec4 current = texture2D(src, index);\n\nfloat blockSize = " + sizeM + ". / count;\n\nvoid main() {\n  vec2 native = TO_PIX(index);\n  float curr = native.x + native.y * " + sizex + ";\n  bool even = mod(floor(curr / (blockSize / 2.)), 2.) == 0.;\n\n  float shift = (blockSize - 1.) - (2. * mod(curr, blockSize));\n  vec2 bCoord = coordShift(shift, index);\n\n  float a = current.x;\n  float b = texture2D(src, bCoord).x;\n\n  // fill result\n  gl_FragColor = current;\n  gl_FragColor.x = DIR_CMP(even, a, b);\n}"
    });
    passBitonic = function(backBuf, frontBuf){
      var b, merge, sort;
      b = [backBuf, frontBuf];
      merge = sizeM / 2;
      while (merge >= 1) {
        avs.pass(bitonicMergeProg, b[1], {
          src: b[0].texture
        }, fn$);
        b = [b[1], b[0]];
        sort = sizeM / merge / 4;
        while (sort >= 1) {
          avs.pass(bitonicSortProg, b[1], {
            src: b[0].texture
          }, fn1$);
          b = [b[1], b[0]];
          sort /= 2;
        }
        merge /= 2;
      }
      return b[0];
      function fn$(b){
        return b.prog.sendFloat('count', merge);
      }
      function fn1$(b){
        return b.prog.sendFloat('spread', sort);
      }
    };
    backBuf = avs.createFramebuffer({
      size: size
    });
    frontBuf = avs.createFramebuffer({
      size: size
    });
    return drawLoop(16, function(){
      var sortedBuf;
      avs.pass(fillProg, backBuf);
      avs.pass(convertProg, frontBuf, {
        src: backBuf.texture
      });
      sortedBuf = passBitonic(frontBuf, backBuf);
      return avs.useProgram(mainProg, function(prog){
        var toDebug, pixels;
        toDebug = sortedBuf;
        clear();
        useTexture(toDebug.texture);
        prog.drawDisplay();
        pixels = avs.readPixels(toDebug);
        return avs.useProgram(pointsProg, function(points){
          return points.drawBuffer(createBuffer(pixels), {
            vars: 4
          });
        });
      });
    });
  });
}).call(this);
