GLOBAL = exports ? this

GLOBAL.mixer =

  Models: {}
  Collections: {}
  Views: {}
  Routers: {}
  Templates: {}

  log: (value, min, max) ->
    # Logarithm (base 2) to compute how many octaves fall in the range.
    numberOfOctaves = Math.log(max / min) / Math.LN2
    # Compute a multiplier from 0 to 1 based on an exponential scale.
    multiplier = Math.pow(2, numberOfOctaves * (value - 1.0))
    # Scale value between min and max.
    max * multiplier

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