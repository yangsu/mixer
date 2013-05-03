class mixer.Views.TrackView extends Backbone.View

  template: mixer.Templates.track
  initialize: (options) ->
    @$el.html @template()

    @wavesurfer = Object.create(WaveSurfer)

    @wavesurfer.init
      canvas: @$('.waveform').get(0)
      markerColor: 'rgba(0, 0, 0, 0.5)'
      frameMargin: 0.1
      maxSecPerPx: 1
      scrollParent: true
      loadPercent: true
      waveColor: 'gray'
      progressColor: 'orange'
      loadingColor: 'orange'
      cursorColor: 'navy'

    $bpm = @$('.bpm')

    @i = 0
    initial = 0
    @kick = @wavesurfer.createKick
      frequency: [ 0, 10 ]
      threshold: 0.5
      decay: 0.005
      onKick: (m, t) =>
        @showBeats @i++
        initial = t if initial is 0
        $bpm.html (@i/(t - initial) * 60).toString().slice(0, 5)
      # offKick: (e) -> console.log 'kick off'

    @wavesurfer.load options.url,
      progress: ->
      load: =>
        @kick.on()
        @$('.disabled').removeClass 'disabled'

    @wavesurfer.bindDragNDrop @$el.get(0)

    @$('.sslider').slider
      min: 0.1
      max: 5
      step: 0.1
      value: 1
      formater: (v) -> v.toString().slice(0, 4)
    .on 'slide', (e) =>
      @wavesurfer.setPlaybackRate e.value


    @$('.vslider').slider
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

    @$('.fslider').slider
      min: 0
      max: 1
      step: 0.01
      value: 1
      formater: (v) =>
        f = (@wavesurfer.changeFilterFrequency v).toString()
        decimal = f.indexOf('.')
        f.slice(0, if decimal < 0 then f.length else decimal + 2) + 'Hz'

    @$('.qslider').slider
      min: 0
      max: 1
      step: 0.01
      value: 1
      formater: (v) =>
        (@wavesurfer.changeFilterQuality v).toString().slice(0, 7)

    @$('.gslider').slider
      min: -1
      max: 1
      step: 0.01
      value: 0
      formater: (v) =>
        (@wavesurfer.changeFilterGain v).toString().slice(0, 4)


    fftCanvas = @$('.fft').get(0)
    ctx = fftCanvas.getContext '2d'
    h = fftCanvas.height
    w = fftCanvas.width
    width = 1
    spacing = 1
    ctx.fillStyle = 'orange'

    @wavesurfer.bind 'update', =>
      spectrum = @wavesurfer.getSpectrum()
      max = _.max spectrum
      return if max == 0

      ctx.clearRect 0, 0, w, h

      l = spectrum.length
      index = 0

      spectrum = _.map spectrum, (x) -> x/0.1

      while index < l
        hh = spectrum[index] * h
        ctx.fillRect index * (spacing + width), h, width, -hh
        index++

  events:
    'click .icon-backward': 'onBackward'
    'click .icon-play': 'onPlay'
    'click .icon-pause': 'onPause'
    'click .icon-forward': 'onForward'
    'click .icon-resize-full': 'onZoomIn'
    'click .icon-resize-small': 'onZoomOut'
    'click canvas': 'onSeek'
    'change #filtertype': 'onChangeFilterType'
    'change #enableFilter': 'onToggleFilter'

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

  onChangeFilterType: (e) ->
    type = $(e.currentTarget).val()
    @wavesurfer.changeFilterType type

  onToggleFilter: (e) ->
    checked = $(e.currentTarget).prop('checked')
    @wavesurfer.toggleFilter checked

  showBeats: (i) ->
    @wavesurfer.mark
      id: 'up' + i
      color: 'rgba(0, 0, 0, 0.5)'
