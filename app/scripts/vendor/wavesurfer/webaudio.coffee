WaveSurfer.WebAudio =
  Defaults:
    fftSize: 1024
    smoothingTimeConstant: 0.3

  context: new (window.AudioContext or window.webkitAudioContext)

  ###
  Initializes the analyser with given params.

  @param {Object} params
  @param {String} params.smoothingTimeConstant
  ###
  init: (params = {}) ->

    @fftSize = params.fftSize or @Defaults.fftSize

    @destination = params.destination or @context.destination
    smoothingTimeConstant = params.smoothingTimeConstant or @Defaults.smoothingTimeConstant

    @gain = @context.createGainNode()
    @gain.connect @destination

    @analyser = @context.createAnalyser()
    @analyser.smoothingTimeConstant = smoothingTimeConstant
    @analyser.fftSize = @fftSize
    @analyser.connect @gain

    @proc = @context.createJavaScriptNode(@fftSize / 2, 1, 1)
    @proc.connect @gain


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
    @source.connect @gain

  setVolume: (volume = 1) ->
    @gain.gain.value = volume

  getVolume: () ->
    @gain.gain.value

  ###
  Loads audiobuffer.

  @param {AudioBuffer} audioData Audio data.
  ###
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


  ###
  Plays the loaded audio region.

  @param {Number} start Start offset in seconds,
  relative to the beginning of the track.

  @param {Number} end End offset in seconds,
  relative to the beginning of the track.
  ###
  play: (start, end, delay = 0) ->
    return  unless @currentBuffer
    @pause()
    @setSource @context.createBufferSource()
    @source.buffer = @currentBuffer
    start ?= @getCurrentTime()
    end ?= @source.buffer.duration

    @lastStart = start
    @startTime = @context.currentTime
    @source.noteGrainOn delay, start, end - start
    @paused = false


  ###
  Pauses the loaded audio.
  ###
  pause: (delay) ->
    return if not @currentBuffer or @paused
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


  ###
  Returns the real-time waveform data.

  @return {Uint8Array} The waveform data.
  Values range from 0 to 255.
  ###
  waveform: ->
    @analyser.getByteTimeDomainData @dataArray
    @dataArray


  ###
  Returns the real-time frequency data.

  @return {Uint8Array} The frequency data.
  Values range from 0 to 255.
  ###
  frequency: ->
    @analyser.getByteFrequencyData @dataArray
    @dataArray