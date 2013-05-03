GLOBAL = exports ? this

GLOBAL.mixer =

  Models: {}
  Collections: {}
  Views: {}
  Routers: {}
  Templates: {}

  context: new webkitAudioContext()
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

    mixer.request and mixer.request.abort()
    mixer.request = xhr
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

  init: ->

    audioFileUrl = 'files/IO-5.0.mp3'

    soundManager.setup
      url: 'components/soundmanager/swf/soundmanager2.swf'
      flashVersion: 9
      # preferFlash: false,
      onready: ->
        # Ready to use; soundManager.createSound() etc. can now be called.

        soundManager.createSound({
          id: 'mySound'
          url: audioFileUrl
          autoLoad: true
          autoPlay: false
          onload: () ->
            # alert('The sound '+this.id+' loaded!')
          volume: 50
        });

    @loadSound audioFileUrl, (buffer) =>
      source = @createSound(buffer)

      @playSound source

$ ->
  mixer.init()