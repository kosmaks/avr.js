$ ->
  avr = new AVR.Context(document.getElementById 'display')

  avr.loadPrograms {

    fill: "scripts/shaders/fill.glsl"

  }, (p) ->

    prog = avr.createDisplayProgram {
      fragment: """
      precision mediump float;
      uniform float color;
      varying vec2 index;

      void main() {
        vec2 _ = index;
        gl_FragColor = vec4(1., color, 1., 1.);
      }
      """
    }

    displayProg = avr.createDisplayProgram {
      fragment: """
      precision mediump float;
      uniform sampler2D sampler;
      varying vec2 index;

      void main() {
        vec2 _ = index;
        gl_FragColor = texture2D(sampler, index);
      }
      """
    }

    fb = avr.createFramebuffer size: [4, 4]

    p.fill.use (prog) ->
      fb.use (fb) ->
        fb.clear()
        prog.sendFloat 'color', 0.5
        prog.drawDisplay()

    displayProg.use (prog) ->
      avr.clear()
      prog.sendInt 'sampler', fb.activeTexture(0)
      prog.drawDisplay()
