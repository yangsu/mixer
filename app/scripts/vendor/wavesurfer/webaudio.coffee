WaveSurfer.WebAudio =
  Defaults:
    fftSize: 2048
    sampleRate: 44100
    QualityMultiplier: 1000
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

    @tuna = new Tuna(@context)

    @filter = @context.createBiquadFilter()
    @filter.type = 0 # lowpass
    @filter.frequency.value = sampleRate / 2;

    @gain = @context.createGainNode()
    @gain.connect @filter

    @filter.connect @destination

    @analyser = @context.createAnalyser()
    @analyser.smoothingTimeConstant = smoothingTimeConstant
    @analyser.fftSize = @fftSize
    @analyser.connect @gain

    @proc = @context.createJavaScriptNode(@fftSize / 2, 1, 1)
    @proc.connect @gain

    @dataArray = new Uint8Array(@analyser.fftSize)

    @paused = true

    @fft = new FFT(@fftSize / 2, sampleRate)
    @signal = new Float32Array(@fftSize / 2)

  changeFilterFrequency: (value) ->

    # Clamp the frequency between the minimum value (40 Hz) and half of the
    # sampling rate.
    minValue = 40
    maxValue = @Defaults.sampleRate / 2

    # Logarithm (base 2) to compute how many octaves fall in the range.
    numberOfOctaves = Math.log(maxValue / minValue) / Math.LN2

    # Compute a multiplier from 0 to 1 based on an exponential scale.
    multiplier = Math.pow(2, numberOfOctaves * (value - 1.0))

    # Get back to the frequency value between min and max.
    frequency = maxValue * multiplier
    @filter.frequency.value = frequency

    frequency

  changeFilterType: (value) ->
    @filter.type = value

  changeFilterQuality: (value) ->

    minValue = 0.0001
    maxValue = 1000

    numberOfOctaves = Math.log(maxValue / minValue) / Math.LN2
    multiplier = Math.pow(2, numberOfOctaves * (value - 1.0))
    Q = multiplier * @Defaults.QualityMultiplier
    @filter.Q.value = Q
    Q

  changeFilterGain: (value) ->
    g = value * @Defaults.gainMultiplier
    @filter.gain.value = g
    g

  toggleFilter: (checked) ->
    @gain.disconnect(0)
    @filter.disconnect(0)
    if checked
      @gain.connect(@filter)
      @filter.connect(@destination)
    else
      @gain.connect(@destination)

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