GLOBAL = exports ? this

GLOBAL.mixer =

  Models: {}
  Collections: {}
  Views: {}
  Routers: {}
  Templates: {}

  init: ->

    soundManager.setup
      url: 'components/soundmanager/swf/soundmanager2.swf'
      flashVersion: 9
      # preferFlash: false,
      onready: ->
        # Ready to use; soundManager.createSound() etc. can now be called.


    audioFileUrl = 'IO-5.0.mp3'
    context = undefined

    if typeof AudioContext isnt 'undefined'
      context = new AudioContext()
    else if typeof webkitAudioContext isnt 'undefined'
      context = new webkitAudioContext()
    else
      throw new Error('AudioContext not supported. :(')

    request = new XMLHttpRequest()
    request.open 'GET', audioFileUrl, true
    request.responseType = 'arraybuffer'

    request.onload = ->
      audioData = request.response

      # create a sound source
      soundSource = context.createBufferSource()

      # The Audio Context handles creating source
      # buffers from raw binary data
      soundBuffer = context.createBuffer(audioData, true) #make mono

      # Add the buffered data to our object
      soundSource.buffer = soundBuffer

      soundSource.connect context.destination

      # Create a volume (gain) node
      volumeNode = context.createGainNode()

      #Set the volume
      volumeNode.gain.value = 0.1
      soundSource.connect volumeNode

      soundSource.noteGrainOn(0, 0, soundBuffer.duration)

    request.send()

$ ->
  mixer.init()