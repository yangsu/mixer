class mixer.Views.TrackView extends Backbone.View

  template: mixer.Templates.track
  initialize: (options) ->
    @$el.html @template()

    @wavesurfer = Object.create(WaveSurfer)

    @wavesurfer.init
      canvas: @$('canvas').get(0)
      markerColor: 'rgba(0, 0, 0, 0.5)'
      frameMargin: 0.1
      maxSecPerPx: 1
      scrollParent: true
      loadPercent: true
      waveColor: 'gray'
      progressColor: 'orange'
      loadingColor: 'orange'
      cursorColor: 'navy'

    @wavesurfer.load options.url,
      progress: ->
      load: =>
        @$('.disabled').removeClass 'disabled'
        @loaded = true

    @wavesurfer.bindDragNDrop @$el.get(0)

  events:
    'click .icon-backward': 'onBackward'
    'click .icon-play': 'onPlay'
    'click .icon-pause': 'onPause'
    'click .icon-forward': 'onForward'
    'click canvas': 'onSeek'

  showPlay: ->
    @$('.icon-pause').replaceWith $ '<i class="icon-play"></i>'
  showPause: ->
    @$('.icon-play').replaceWith $ '<i class="icon-pause"></i>'
  onBackward: (e) ->
    return if not @loaded
    @showPause()
    @wavesurfer.skipBackward()
  onPlay: (e) ->
    return if not @loaded
    @showPause()
    @wavesurfer.playPause()
  onPause: (e) ->
    return if not @loaded
    @showPlay()
    @wavesurfer.playPause()
  onForward: (e) ->
    return if not @loaded
    @showPause()
    @wavesurfer.skipForward()

  onSeek: (e) ->
    @showPause()
