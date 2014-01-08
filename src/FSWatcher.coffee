EventEmitter = require('events').EventEmitter

class FSWatcher extends EventEmitter


	listener: null


	constructor: (@listener) ->
		super

		@addListener('change', @listener)


	close: -> @removeListener('change', @listener)


module.exports = FSWatcher