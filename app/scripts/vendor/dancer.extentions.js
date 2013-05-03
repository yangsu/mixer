
(function() {
  Dancer.addPlugin( 'getContext', function( ) {
    return this.audioAdapter.context;
//     return this;
  });
})();