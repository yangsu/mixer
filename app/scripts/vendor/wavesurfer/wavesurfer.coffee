window.WaveSurfer =
  defaultParams:
    skipLength: 2

  init: (params) ->

    _.defaults params, @defaultParams

    if params.audio
      backend = WaveSurfer.Audio
    else
      backend = WaveSurfer.WebAudio
    @backend = Object.create(backend)
    @backend.init params
    @drawer = Object.create(WaveSurfer.Drawer)
    @drawer.init params
    @backend.bindUpdate =>
      @onAudioProcess()

    @bindClick params.canvas, (percents) =>
      @playAt percents

  onAudioProcess: ->
    @drawer.progress @backend.getPlayedPercents()  unless @backend.isPaused()

  playAt: (percents) ->
    @backend.play @backend.getDuration() * percents

  pause: ->
    @backend.pause()

  playPause: ->
    if @backend.paused
      @playAt @backend.getPlayedPercents() or 0
    else
      @pause()

  skipBackward: (seconds) ->
    @skip seconds or -@skipLength

  skipForward: (seconds) ->
    @skip seconds or @skipLength

  skip: (offset) ->
    timings = @timings(offset)
    @playAt timings[0] / timings[1]

  marks: 0
  mark: (options) ->
    options = options or {}
    timings = @timings(0)
    marker =
      width: options.width
      color: options.color
      percentage: timings[0] / timings[1]
      position: timings[0]

    id = options.id or '_m' + @marks++
    @drawer.markers[id] = marker
    @drawer.redraw()  if @backend.paused
    marker

  timings: (offset) ->
    position = @backend.getCurrentTime() or 0
    duration = @backend.getDuration() or 1
    position = Math.max(0, Math.min(duration, position + offset))
    [position, duration]

  drawBuffer: ->
    @drawer.drawBuffer @backend.currentBuffer  if @backend.currentBuffer


  ###
  Loads an audio file via XHR.
  ###
  load: (src, options = {}) ->
    xhr = new XMLHttpRequest()
    xhr.responseType = 'arraybuffer'
    xhr.addEventListener 'progress', ((e) =>
      if e.lengthComputable
        percentComplete = e.loaded / e.total
      else
        # TODO
        # for now, approximate progress with an asymptotic
        # function, and assume downloads in the 1-3 MB range.
        percentComplete = e.loaded / (e.loaded + 1000000)
      @drawer.drawLoading percentComplete
      options.progress percentComplete if options.progress?
    ), false
    xhr.addEventListener 'load', ((e) =>
      @drawer.drawLoading 1
      @backend.loadData e.target.response, (buffer) =>
        @drawBuffer()
        options.load buffer if options.load?
    ), false
    xhr.open 'GET', src, true
    xhr.send()


  ###
  Loads an audio file via drag'n'drop.
  ###
  bindDragNDrop: (dropTarget) ->
    reader = new FileReader()
    reader.addEventListener 'load', ((e) =>
      @backend.loadData e.target.result, (buffer) =>
        @drawBuffer()
        options.load buffer if options.load?
    ), false
    (dropTarget or document).addEventListener 'drop', ((e) ->
      e.preventDefault()
      file = e.dataTransfer.files[0]
      file and reader.readAsArrayBuffer(file)
    ), false


  ###
  Click to seek.
  ###
  bindClick: (element, callback) ->
    element.addEventListener 'click', ((e) ->
      relX = e.offsetX
      relX = e.layerX  if null is relX
      callback relX / @clientWidth
    ), false