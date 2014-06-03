AVR.js
======

In-browser multicore computing library. Based on WebGL.

Usage
=====

Initialization
--------------

```javascript
avr = new AVR.Context(document.getElementById('display'))
avr.loadPrograms({
  // here comes your shaders
}, {
  // shader constants here
}, function(p) {
  // magic stuff goes here ...
});
```

Examples
--------

* SPH fluid simulation logo: http://avr.kosmaks.com
* Fuzzy c-means clustering: http://splitcity.kosmaks.com

Simple chain
------------

Chains are computing flow. Each consists of one or more passes.

index.js:
```javascript
avr.loadPrograms({
  hello: "shaders/hello.glsl"
}, {}, function(p) {
  
  var c = avr.createChain();
  avr.clear();
  c.pass(p.hello);

});
```

shaders/hello.glsl:
```glsl
precision mediump float;
varying vec2 index;

void main() { gl_FragColor = vec4(index, 0., 1.); }
```
