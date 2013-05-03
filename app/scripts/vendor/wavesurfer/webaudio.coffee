WaveSurfer.WebAudio =
  Defaults:
    fftSize: 2048
    sampleRate: 44100
    gainMultiplier: 40
    smoothingTimeConstant: 0.3

  bindings: {}

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
    sampleRate = params.sampleRate ? @Defaults.sampleRate

    @gain = @context.createGainNode()

    @filter = @context.createBiquadFilter()
    @filter.type = 0 # lowpass
    @filter.frequency.value = sampleRate / 2;

    @passthrough = @context.createGainNode()

    @tuna = new Tuna(@context)
    @chorus = new @tuna.Chorus
      rate: 2 #0.01 to 8+
      feedback: 0.5 #0 to 1+
      delay: 0.45 #0 to 1
      bypass: 0 #the value 1 starts the effect as bypassed, 0 or 1

    @analyser = @context.createAnalyser()
    @analyser.smoothingTimeConstant = smoothingTimeConstant
    @analyser.fftSize = @fftSize

    @proc = @context.createJavaScriptNode(@fftSize / 2, 1, 1)

    @filter.connect @passthrough
    @passthrough.connect @chorus.input
    @chorus.connect @gain
    @gain.connect @analyser
    @gain.connect @proc
    @proc.connect @destination
    @analyser.connect @destination

    @dataArray = new Uint8Array(@analyser.fftSize)

    @paused = true

    @fft = new FFT(@fftSize / 2, sampleRate)
    @signal = new Float32Array(@fftSize / 2)


  setSource: (source) ->
    @source and @source.disconnect(0)
    @source = source
    @source.connect @filter

  setVolume: (volume = 1) ->
    @gain.gain.value = volume

  getVolume: () ->
    @gain.gain.value

  setPlaybackRate: (speed) ->
    @source.playbackRate.value = speed if @source?

  changeFilterFrequency: (value) ->

    # Clamp the frequency between the minimum value (40 Hz) and half of the
    # sampling rate.
    frequency = mixer.log value, 40, @Defaults.sampleRate / 2
    @filter.frequency.value = frequency

    frequency

  changeFilterType: (value) ->
    @filter.type = value

  changeFilterQuality: (value) ->

    minValue = 0.0001
    maxValue = 1000

    Q = mixer.log value, 0.0001, 1000
    @filter.Q.value = Q
    Q

  changeFilterGain: (value) ->
    g = value * @Defaults.gainMultiplier
    @filter.gain.value = g
    g

  toggleFilter: (checked) ->
    @source.disconnect(0)
    @filter.disconnect(0)
    if checked
      @source.connect @filter
      @filter.connect @passthrough
    else
      @source.connect @passthrough

  toggleChorus: (checked) ->
    @passthrough.disconnect(0)
    @chorus.disconnect(0)
    if checked
      @passthrough.connect @chorus.input
      @chorus.connect @gain
    else
      @passthrough.connect @gain

  processFFT: (e) ->
    return if @paused or not @loaded

    buffers = []
    channels = e.inputBuffer.numberOfChannels
    resolution = @fftSize / channels

    sum = (prev, curr) -> prev[i] + curr[i]

    i = channels
    while i--
      buffers.push e.inputBuffer.getChannelData(i)

    i = resolution
    while i--
      if channels > 1
        @signal[i] = buffers.reduce(sum) / channels
      else
        @signal[i] = buffers[0][i]

    @fft.forward @signal

  getWaveform: -> @signal
  getSpectrum: -> @fft.spectrum

  createKick: (options = {}) ->
    new Dancer.Kick(@, options)

  bind: (event, cb) ->
    @bindings[event] ?= []
    @bindings[event].push cb

  bindUpdate: (callback) ->
    @proc.onaudioprocess = (e) =>
      return if @paused

      @processFFT e

      _.each @bindings.update, (f) => f e, @getCurrentTime()

      callback e if callback?
      if @getPlayedPercents() > 1.0
        @pause()
        @lastPause = 0

  ###
  Loads audiobuffer.

  @param {AudioBuffer} audioData Audio data.
  ###
  loadData: (audioData, cb) ->
    @pause()
    @loaded = true
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
    @source.loop = true
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