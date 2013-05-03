WaveSurfer.Drawer =
  defaultParams:
    waveColor: '#999'
    progressColor: '#333'
    cursorColor: '#ddd'
    markerColor: '#eee'
    loadingColor: '#999'
    cursorWidth: 1
    loadPercent: false
    loadingBars: 20
    barHeight: 1
    barMargin: 10
    markerWidth: 1
    frameMargin: 0
    fillParent: false
    maxSecPerPx: false
    scrollParent: false

  scale: window.devicePixelRatio

  init: (params) ->

    # extend params with defaults
    @params = _.defaults params, @defaultParams

    @markers = {}
    @canvas = params.canvas
    @parent = @canvas.parentNode
    if params.fillParent
      style = @canvas.style
      style.width = @parent.clientWidth + 'px'
      style.height = @parent.clientHeight + 'px'
    @prepareContext()
    @loadImage params.image, @drawImage.bind(this)  if params.image

  prepareContext: ->
    canvas = @canvas
    w = canvas.clientWidth
    h = canvas.clientHeight
    @width = canvas.width = w * @scale
    @height = canvas.height = h * @scale
    canvas.style.width = w + 'px'
    canvas.style.height = h + 'px'
    @context = canvas.getContext('2d')
    console.error 'Canvas size is zero.'  if not @width or not @height

  getPeaks: (buffer) ->
    frames = buffer.getChannelData(0).length

    # Frames per pixel
    k = frames / @width
    maxSecPerPx = @params.maxSecPerPx
    if maxSecPerPx
      secPerPx = k / buffer.sampleRate
      if secPerPx > maxSecPerPx
        targetWidth = Math.ceil(frames / maxSecPerPx / buffer.sampleRate / @scale)
        @canvas.style.width = targetWidth + 'px'
        @prepareContext()
        k = frames / @width
    @peaks = []
    @maxPeak = -Infinity
    i = 0

    while i < @width
      sum = 0
      c = 0

      while c < buffer.numberOfChannels
        chan = buffer.getChannelData(c)
        vals = chan.subarray(i * k, (i + 1) * k)
        peak = -Infinity
        p = 0
        l = vals.length

        while p < l
          val = Math.abs(vals[p])
          peak = val  if val > peak
          p++
        sum += peak
        c++
      @peaks[i] = sum
      @maxPeak = sum  if sum > @maxPeak
      i++
    @maxPeak *= 1 + @params.frameMargin

  progress: (percents) ->
    @cursorPos = ~~(@width * percents)
    @redraw()
    if @params.scrollParent
      half = @parent.clientWidth / 2
      target = @cursorPos - half
      offset = target - @parent.scrollLeft

      # if the cursor is currently visible...
      if offset >= -half and offset < half

        # well limit the 're-center' rate.
        rate = 5
        offset = Math.max(-rate, Math.min(rate, offset))
        target = @parent.scrollLeft + offset
      @canvas.parentNode.scrollLeft = ~~target

  drawBuffer: (buffer) ->
    @getPeaks buffer
    @progress 0


  ###
  Redraws the entire canvas on each audio frame.
  ###
  redraw: ->
    @clear()

    # Draw WebAudio buffer peaks.
    if @peaks
      _.each @peaks, (peak, index) =>
        @drawFrame index, peak, @maxPeak

    # Or draw an image.
    else if @image
      @drawImage()

    # Draw markers.
    _.each @markers, (marker, key) =>
      percentage = ~~(@width * marker.percentage)
      @drawMarker percentage, marker.width, marker.color

    @drawCursor()

  clear: ->
    @context.clearRect 0, 0, @width, @height

  drawFrame: (index, value, max) ->
    w = 1
    h = Math.round(value * (@height / max))
    x = index * w
    y = Math.round((@height - h) / 2)
    if @cursorPos >= x
      @context.fillStyle = @params.progressColor
    else
      @context.fillStyle = @params.waveColor
    @context.fillRect x, y, w, h

  drawCursor: ->
    @drawMarker @cursorPos, @params.cursorWidth, @params.cursorColor

  drawMarker: (position, width, color) ->
    width = width or @params.markerWidth
    color = color or @params.markerColor
    w = width * @scale
    h = @height
    x = Math.min(position, @width - w)
    y = 0
    @context.fillStyle = color
    @context.fillRect x, y, w, h


  ###
  Loads and caches an image.
  ###
  loadImage: (url, callback) ->
    img = document.createElement('img')
    onLoad = =>
      img.removeEventListener 'load', onLoad
      @image = img
      callback img

    img.addEventListener 'load', onLoad, false
    img.src = url


  ###
  Draws a pre-drawn waveform image.
  ###
  drawImage: ->
    cc = @context
    cc.drawImage @image, 0, 0, @width, @height
    cc.save()
    cc.globalCompositeOperation = 'source-atop'
    cc.fillStyle = @params.progressColor
    cc.fillRect 0, 0, @cursorPos, @height
    cc.restore()

  drawLoading: (progress) ->
    barHeight = @params.barHeight * @scale
    y = ~~(@height - barHeight) / 2
    @context.fillStyle = @params.loadingColor
    if @params.loadPercent
      width = Math.round(@width * progress)
      @context.fillRect 0, y, width, barHeight
      return
    bars = @params.loadingBars
    margin = @params.barMargin * @scale
    barWidth = ~~(@width / bars) - margin
    progressBars = ~~(bars * progress)
    i = 0

    while i < progressBars
      x = i * barWidth + i * margin
      @context.fillRect x, y, barWidth, barHeight
      i += 1