(function (window, jQuery, _) {
  window.BufferLoader = function (context, urlHash, callback) {
    this.context = context;
    this.urlHash = urlHash;
    this.onload = callback;
    this.bufferHash = {};
    this.loadCount = 0;
    this.bufferCount = _.keys(urlHash).length;
  };

  BufferLoader.prototype.loadBuffer = function(url, key) {
    // Load buffer asynchronously
    var request = new XMLHttpRequest();
    request.open("GET", url, true);
    request.responseType = "arraybuffer";

    var loader = this;

    request.onload = function() {
      // Asynchronously decode the audio file data in request.response
      loader.context.decodeAudioData(
        request.response,
        function(buffer) {
          if (!buffer) {
            alert('error decoding file data: ' + url);
            return;
          }
          loader.bufferHash[key] = buffer;
          if (++loader.loadCount == loader.bufferCount)
            loader.onload(loader.bufferHash);
        },
        function(error) {
          console.error('decodeAudioData error', error);
        }
      );
    }

    request.onerror = function() {
      alert('BufferLoader: XHR error');
    }

    request.send();
  };

  BufferLoader.prototype.load = function() {
    var self = this;
    _.each(self.urlHash, function (url, key) {
      self.loadBuffer(url, key);
    })
  };
})(window, jQuery, _);