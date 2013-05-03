WaveSurfer.Audio =

  ###
  Initializes the analyser with given params.

  @param {Object} params (required)
  @param {HTMLAudioElement} params.audio (required)
  ###
  init: (params) ->
    params = params or {}
    @audio = params.audio

  isPaused: ->
    @audio.paused

  getDuration: ->
    @audio.duration


  ###
  Plays the audio from a given position.

  @param {Number} start Start offset in seconds,
  relative to the beginning of the track.
  ###
  play: (start) ->
    start = start or 0
    @audio.currentTime = start  if @audio.currentTime isnt start
    @audio.play()


  ###
  Pauses playback.
  ###
  pause: ->
    @audio.pause()

  getPlayedPercents: ->
    time = Math.min(@audio.currentTime, @audio.duration)
    time / @audio.duration

  bindUpdate: (callback) ->
    @audio.addEventListener "timeupdate", callback, false