class AVR.Chain extends AVR.GLContext
  initialize: ->
    @framebuffers = {}
    @backs = {}
    @fronts = {}
    @trig = false
    @trigState = {}

  # helpers

  sendFloat: (name, value) -> (x) ->
    x.prog.sendFloat name, value

  # control flow

  framebuffer: (name, opts = {}) ->
    @framebuffers[name] = @avr.createFramebuffer opts

  doubleFramebuffer: (name, opts = {}) ->
    @backs[name] = @avr.createFramebuffer opts
    @fronts[name] = @avr.createFramebuffer opts

  pass: (prog, output, fbs = {}, cb) ->
    i = 0
    prog.use (prog) =>
      for name, fb of fbs
        prog.sendInt name, @parseSelector(fb).activeTexture(i)
        i += 1
      if output?
        @parseSelector(output).use (buf) =>
          buf.clear()
          cb? { prog: prog, buf: buf }
          prog.drawDisplay()
      else
        @avr.clear()
        cb? { prog: prog }
        prog.drawDisplay()

  getBuffer: (selector) -> @parseSelector(selector)

  swapBuffers: ->
    @trig = not @trig

  # private

  parseSelector: (selector) ->
    info   = selector.split(' ')
    name   = selector
    source = 'framebuffers'

    if info.length >= 2
      name = info[1]
      source = if info[0] == 'back'
        (if @trig then 'backs' else 'fronts')
      else if info[0] == 'front'
        (if @trig then 'fronts' else 'backs')
      else if info[0] == 'switch'
        @trigState[name] = !@trigState[name]
        (if @trigState[name] then 'fronts' else 'backs')
      else if info[0] == 'auto'
        (if @trigState[name] then 'fronts' else 'backs')

    unless @[source]?[name]?
      throw new Error "Can't find buffer '#{selector}'"

    return @[source][name]

AVR.Context::createChain = -> new AVR.Chain this
