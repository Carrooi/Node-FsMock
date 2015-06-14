(function() {

	var Errors = require('./Errors');
	var EventEmitter = require('events').EventEmitter;
	var Utils = require('util');


	var Stats = function (path, data) {
		var name;

		EventEmitter.call(this);

		if (data == null) {
			data = {};
		}

		this._path = path;

		this.atime = new Date;
		this.mtime = new Date;
		this.ctime = new Date;

		for (name in data) {
			if (data.hasOwnProperty(name)) {
				if (typeof this[name] !== 'undefined' && Object.prototype.toString.call(this[name]) !== '[object Function]') {
					this[name] = data[name];
				}
			}
		}
	};


	Utils.inherits(Stats, EventEmitter);


	Stats.prototype._path = null;

	Stats.prototype._isFile = false;

	Stats.prototype._isDirectory = false;

	Stats.prototype._isSymlink = false;

	Stats.prototype.dev = 0;

	Stats.prototype.ino = 0;

	Stats.prototype.mode = 438;

	Stats.prototype.nlink = 0;

	Stats.prototype.uid = 100;

	Stats.prototype.gid = 100;

	Stats.prototype.rdev = 0;

	Stats.prototype.size = 0;

	Stats.prototype.blksize = 0;

	Stats.prototype.blocks = 1;

	Stats.prototype.atime = null;

	Stats.prototype.mtime = null;

	Stats.prototype.ctime = null;


	Stats.prototype._modified = function () {
		this.mtime = new Date;
		this.ctime = new Date;

		this.emit('modified', this);
	};


	Stats.prototype._modifiedAttributes = function (event) {
		if (event == null) {
			event = 'change';
		}

		this.ctime = new Date;

		this.emit('modifiedAttributes', this, event);
	};


	Stats.prototype._accessed = function () {
		this.atime = new Date;

		this.emit('accessed', this);
	};


	Stats.prototype._setAttributes = function (attributes) {
		var name;

		if (attributes == null) {
			attributes = {};
		}

		for (name in attributes) {
			if (attributes.hasOwnProperty(name)) {
				if (Object.prototype.toString.call(this[name]) !== '[object Function]') {
					this[name] = attributes[name];
				}
			}
		}

		this._modifiedAttributes();
	};


	Stats.prototype._clone = function () {
		var name, stats;

		stats = new Stats(this._path, {});

		for (name in this) {
			if (this.hasOwnProperty(name)) {
				if (Object.prototype.toString.call(this[name]) !== '[object Function]') {
					stats[name] = this[name];
				}
			}
		}

		return stats;
	};


	Stats.prototype.isFile = function () {
		return this._isFile;
	};


	Stats.prototype.isDirectory = function () {
		return this._isDirectory;
	};


	Stats.prototype.isBlockDevice = function () {
		return Errors.notImplemented('isBlockDevice');
	};


	Stats.prototype.isCharacterDevice = function () {
		return Errors.notImplemented('isCharacterDevice');
	};


	Stats.prototype.isSymbolicLink = function () {
		return this._isSymlink;
	};


	Stats.prototype.isFIFO = function () {
		return Errors.notImplemented('isFIFO');
	};


	Stats.prototype.isSocket = function () {
		return Errors.notImplemented('isSocket');
	};


	module.exports = Stats;

}).call(this);
