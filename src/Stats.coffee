Errors = require './Errors'

class Stats


	_path: null

	_isFile: false

	_isDirectory: false

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


	_modifiedAttributes: ->
		@ctime = new Date


	_accessed: ->
		@atime = new Date


	isFile: ->
		return @_isFile


	isDirectory: ->
		return @_isDirectory


	isBlockDevice: ->
		Errors.notImplemented 'isBlockDevice'


	isCharacterDevice: ->
		Errors.notImplemented 'isCharacterDevice'


	isSymbolicLink: ->
		Errors.notImplemented 'isSymbolicLink'


	isFIFO: ->
		Errors.notImplemented 'isFIFO'


	isSocket: ->
		Errors.notImplemented 'isSocket'


module.exports = Stats