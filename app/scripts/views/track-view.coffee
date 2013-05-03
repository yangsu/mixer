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
      load: ->

    @wavesurfer.bindDragNDrop @$el.get(0)

