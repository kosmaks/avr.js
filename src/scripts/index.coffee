$ ->
  avr = new AVR.Context(document.getElementById 'display')

  avr.loadPrograms {
    fill: "shaders/fill.glsl"
    display: "shaders/display.glsl"
  }, {
    hi: 0.5.toFixed(2)
  }, (p) ->

    fb = avr.createFramebuffer size: [4, 4]

    c = avr.createChain()
    c.framebuffer 'main', size: [4, 4]
    c.doubleFramebuffer 'sampler', size: [4, 4]

    c.pass p.fill, 'back sampler', []
    c.pass p.fill, 'front sampler', []
    c.pass p.display, 'main', ['front sampler']
    c.swapBuffers()

    p.display.use (prog) ->
      avr.clear()
      prog.sendInt 'sampler', c.getBuffer('main').activeTexture(0)
      prog.drawDisplay()
