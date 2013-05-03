window.mixer ?= {}

WebAudio =

  context: new (window.AudioContext or window.webkitAudioContext)

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

mixer.WebAudio = WebAudio