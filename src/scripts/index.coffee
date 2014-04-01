$ ->

  size   = [16, 16]
  factor = 100

  avr = new AVR.Context(document.getElementById 'display')
  avr.loadPrograms {

    fill      : "shaders/fill.glsl"
    zero      : "shaders/zero.glsl"
    display   : "shaders/display.glsl"
    velocity  : "shaders/velocity.glsl"
    position  : "shaders/position.glsl"
    reader    : "shaders/reader.glsl"
    particles : {
      vertexUrl   : "shaders/particles.vertex.glsl"
      fragmentUrl : "shaders/particles.fragment.glsl"
    }

  }, {

    factor  : factor.toFixed(8)
    lobound : 0.toFixed(8)
    hibound : factor.toFixed(8)
    sizex   : size[0].toFixed(8)
    sizey   : size[1].toFixed(8)
    count   : (size[0] * size[1]).toFixed(8)

  }, (p) ->

    c = avr.createChain()

    # Generate buffers
    c.framebuffer('reader', size: size)
    c.doubleFramebuffer('particles', size: size)
    c.doubleFramebuffer('velocities', size: size)

    # Bootstrap
    c.pass(p.fill, 'back particles')
    c.pass(p.zero, 'back velocities')

    #$("#next").click ->
    avr.drawLoop 16, ->

      # Process
      c.pass(p.velocity, 'front velocities', {
        back: 'back velocities'
        particles: 'back particles'
      })

      c.pass(p.position, 'front particles', {
        back: 'back particles'
        velocities: 'front velocities'
      })

      c.pass(p.reader, 'reader', sampler: 'back particles')

      # Display
      c.pass(p.display, null, sampler: 'reader')
      buffer = avr.createBuffer c.getBuffer('reader').getPixels()
      p.particles.use (prog) -> prog.drawBuffer buffer, vars: 4

      c.swapBuffers()
