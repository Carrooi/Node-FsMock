Errors = require './Errors'
EventEmitter = require('events').EventEmitter

class Stats extends EventEmitter


	_path: null

	_isFile: false

	_isDirectory: false

	_isSymlink: false

	dev: 0

	ino: 0

	mode: 438

	nlink: 0

	uid: 100

	gid: 100

	rdev: 0

	size: 0

	blksize: 0

	blocks: 1

	atime: null

	mtime: null

	ctime: null


	constructor: (@_path, data = {}) ->
		@atime = new Date
		@mtime = new Date
		@ctime = new Date

		for name, value of data
			if typeof @[name] != 'undefined' && Object.prototype.toString.call(@[name]) != '[object Function]'
				@[name] = value


	_modified: ->
		@mtime = new Date
		@ctime = new Date

		@emit 'modified', @


	_modifiedAttributes: (event = 'change') ->
		@ctime = new Date

		@emit 'modifiedAttributes', @, event


	_accessed: ->
		@atime = new Date

		@emit 'accessed', @


	_setAttributes: (attributes = {}) ->
		for name, value of attributes
			if Object.prototype.toString.call(@[name]) != '[object Function]'
				@[name] = value

		@_modifiedAttributes()


	_clone: ->
		stats = new Stats(@_path, {})
		for name, value of @
			if Object.prototype.toString.call(@[name]) != '[object Function]'
				stats[name] = @[name]

		return stats


	isFile: ->
		return @_isFile


	isDirectory: ->
		return @_isDirectory


	isBlockDevice: ->
		Errors.notImplemented 'isBlockDevice'


	isCharacterDevice: ->
		Errors.notImplemented 'isCharacterDevice'


	isSymbolicLink: ->
		return @_isSymlink


	isFIFO: ->
		Errors.notImplemented 'isFIFO'


	isSocket: ->
		Errors.notImplemented 'isSocket'


module.exports = Stats