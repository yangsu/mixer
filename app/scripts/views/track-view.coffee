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

    @$('.slider').slider
      min: 0
      max: 1
      step: 0.1
      value: 1
      formater: (v) -> v.toString().slice(0, 4)
    .on 'slide', (e) =>
      if 0 == e.value
        el = '<i class="icon-volume-off"></i>'
      else if 0 < e.value < 0.5
        el = '<i class="icon-volume-down"></i>'
      else
        el = '<i class="icon-volume-up"></i>'

      @$('.volume').children().replaceWith $ el

      @wavesurfer.setVolume e.value

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
    @wavesurfer.resize 1.5
  onZoomOut: (e) ->
    @wavesurfer.resize 0.75
  onSeek: (e) ->
    @showPause()
