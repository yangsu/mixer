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

    track1 = new mixer.Views.TrackView
      el: '#track1'
      url: audioFileUrl

    track2 = new mixer.Views.TrackView
      el: '#track2'
      url: audioFileUrl2


$ ->
  mixer.init()