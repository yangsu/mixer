GLOBAL = exports ? this

GLOBAL.mixer =

  Models: {}
  Collections: {}
  Views: {}
  Routers: {}
  Templates: {}

  init: ->

    audioFileUrl = 'files/WalterWhite.mp3'
    audioFileUrl2 = 'files/Superliminal.mp3'

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

    # mixer.WebAudio.loadSound audioFileUrl, (buffer) =>
    #   source = mixer.WebAudio.createSound(buffer)

    #   mixer.WebAudio.playSound source

    track1 = new mixer.Views.TrackView
      el: '#track1'
      url: audioFileUrl

    track2 = new mixer.Views.TrackView
      el: '#track2'
      url: audioFileUrl2


$ ->
  mixer.init()