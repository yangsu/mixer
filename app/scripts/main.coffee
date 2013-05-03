GLOBAL = exports ? this

GLOBAL.mixer =

  Models: {}
  Collections: {}
  Views: {}
  Routers: {}
  Templates: {}

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

    mixer.WebAudio.loadSound audioFileUrl, (buffer) =>
      source = mixer.WebAudio.createSound(buffer)

      mixer.WebAudio.playSound source

$ ->
  mixer.init()