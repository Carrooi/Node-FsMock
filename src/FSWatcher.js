(function() {

	var EventEmitter = require('events').EventEmitter;
	var Utils = require('util');


	var FSWatcher = function(listener) {
		EventEmitter.call(this);

		this.listener = listener;

		this.addListener('change', this.listener);
	};


	Utils.inherits(FSWatcher, EventEmitter);


	FSWatcher.prototype.close = function() {
		this.removeListener('change', this.listener);
	};


	FSWatcher.prototype.listener = null;


	module.exports = FSWatcher;

}).call(this);
