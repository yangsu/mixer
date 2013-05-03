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

    @wavesurfer.bindDragNDrop @$el.get(0)

  events:
    'click .icon-backward': 'onBackward'
    'click .icon-play': 'onPlay'
    'click .icon-pause': 'onPause'
    'click .icon-forward': 'onForward'
    'click .icon-resize-full': 'onZoomIn'
    'click .icon-resize-small': 'onZoomOut'
    'click canvas': 'onSeek'

  showPlay: ->
    @$('.icon-pause').replaceWith $ '<i class="icon-play"></i>'
  showPause: ->
    @$('.icon-play').replaceWith $ '<i class="icon-pause"></i>'
  onBackward: (e) ->
    @showPause()
    @wavesurfer.skipBackward()
  onPlay: (e) ->
    @showPause()
    @wavesurfer.playPause()
  onPause: (e) ->
    @showPlay()
    @wavesurfer.playPause()
  onForward: (e) ->
    @showPause()
    @wavesurfer.skipForward()

  onZoomIn: (e) ->
    @wavesurfer.resize 1.2

  onZoomOut: (e) ->
    @wavesurfer.resize 0.8

  onSeek: (e) ->
    @showPause()
