window.WebAudio =
  Defaults:
    fftSize: 1024,
    smoothingTimeConstant: 0.3

  context: new (window.AudioContext or window.webkitAudioContext)

  init: (params = {}) ->

    @fftSize = params.fftSize or @Defaults.fftSize
    @destination = params.destination or @context.destination

    @analyser = @context.createAnalyser()
    @analyser.smoothingTimeConstant = params.smoothingTimeConstant or @Defaults.smoothingTimeConstant
    @analyser.fftSize = @fftSize
    @analyser.connect @destination

    @proc = @context.createJavaScriptNode(@fftSize / 2, 1, 1)
    @proc.connect @destination

    @dataArray = new Uint8Array(@analyser.fftSize)

    @paused = true

  bindUpdate: (callback) ->
    @proc.onaudioprocess = =>
      callback() if callback?
      if @getPlayedPercents() > 1.0
        @pause()
        @lastPause = 0

  setSource: (source) ->
    @source and @source.disconnect()
    @source = source
    @source.connect @analyser
    @source.connect @proc

  loadData: (audioData, cb) ->
    @pause()
    @context.decodeAudioData audioData, ((buffer) =>
      @currentBuffer = buffer
      @lastStart = 0
      @lastPause = 0
      @startTime = null
      cb buffer if cb?
    ), Error

  isPaused: ->
    @paused

  getDuration: ->
    @currentBuffer and @currentBuffer.duration

  play: (start, end, delay = 0) ->
     return unless @currentBuffer
     @pause()
     @setSource @context.createBufferSource()
     @source.buffer = @currentBuffer
     start ?= @getCurrentTime()
     end ?= @source.buffer.duration

     @lastStart = start
     @startTime = @context.currentTime

     @source.noteGrainOn delay, start, end - start

     @paused = false

  pause: (delay) ->
    return  if not @currentBuffer or @paused
    @lastPause = @getCurrentTime()
    @source.noteOff delay or 0
    @paused = true

  getPlayedPercents: ->
    @getCurrentTime() / @getDuration()

  getCurrentTime: ->
    if @isPaused()
      @lastPause
    else
      @lastStart + (@context.currentTime - @startTime)

  waveform: ->
    @analyser.getByteTimeDomainData @dataArray
    @dataArray

  frequency: ->
    @analyser.getByteFrequencyData @dataArray
    @dataArray

  loadSound: (url, cb) ->
    xhr = new XMLHttpRequest()
    xhr.open 'GET', url, true
    xhr.responseType = 'arraybuffer'
    xhr.onprogress = (ev) ->
      $('.track.source').width ((ev.loaded / ev.total) * 100) + '%'

    xhr.onload = =>
      return unless xhr.readyState is 4
      @context.decodeAudioData xhr.response, (buffer) ->
        cb and cb(buffer)

    WebAudio.request and WebAudio.request.abort()
    WebAudio.request = xhr
    xhr.send()

  createSound: (buffer) ->
    source = @context.createBufferSource()
    source.buffer = buffer
    source.connect @context.destination
    source

  playSound: (source, delay = 0, start, duration) ->
    initialDelay = @context.currentTime + delay
    if not start? or not duration?
      source.noteOn initialDelay
    else if start and duration
      source.noteGrainOn initialDelay, start, duration

  stopSound: (source, delay = 0) ->
    source.noteOff @context.currentTime + delay
