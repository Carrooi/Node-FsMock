class Stats


	__path: null

	__isFile: false

	__isDirectory: false

	dev: 0

	ino: 0

	mode: 0

	nlink: 0

	uid: 0

	gid: 0

	rdev: 0

	size: 0

	blksize: 0

	blocks: 1

	atime: null

	mtime: null

	ctime: null


	constructor: (@__path, data = {}) ->
		@atime = new Date
		@mtime = new Date
		@ctime = new Date

		for name, value of data
			if typeof @[name] != 'undefined' && Object.prototype.toString.call(@[name]) != '[object Function]'
				@[name] = value


	__notImplemented: (method) ->
		throw new Error "Method '#{method}' is not implemented."


	__modified: ->
		@mtime = new Date
		@ctime = new Date


	__modifiedAttributes: ->
		@ctime = new Date


	__accessed: ->
		@atime = new Date


	isFile: ->
		return @__isFile


	isDirectory: ->
		return @__isDirectory


	isBlockDevice: ->
		@__notImplemented 'isBlockDevice'


	isCharacterDevice: ->
		@__notImplemented 'isCharacterDevice'


	isSymbolicLink: ->
		@__notImplemented 'isSymbolicLink'


	isFIFO: ->
		@__notImplemented 'isFIFO'


	isSocket: ->
		@__notImplemented 'isSocket'


module.exports = Stats