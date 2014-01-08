Stats = require './Stats'
Errors = require './Errors'
FSWatcher = require './FSWatcher'
escape = require 'escape-regexp'
_path = require 'path'
Readable = require('stream').Readable
Writable = require('stream').Writable

isFunction   = (obj)   -> return Object.prototype.toString.call(obj) == '[object Function]'
isReadable   = (flags) -> return flags in ['r', 'r+', 'rs', 'rs+', 'w+', 'wx+', 'a+', 'ax+']
isWritable   = (flags) -> return flags in ['r+', 'rs+', 'w', 'wx', 'w+', 'wx+']
isAppendable = (flags) -> return flags in ['a', 'ax', 'a+', 'ax+']

toDate = (time) ->
	if typeof time == 'number'
		return new Date(time * 1000)
	if time instanceof Date
		return time

	throw new Error "Cannot parse time: #{time}"

class fs


	_data: null

	_fileDescriptors: null

	_fileDescriptorsCounter: 0


	constructor: (tree = {}) ->
		@_data = {}
		@_fileDescriptors = []

		@_setTree(tree)


	_hasFd: (fd) ->
		return typeof @_fileDescriptors[fd] != 'undefined'


	_hasSubPaths: (path) ->
		for found, data of @_data
			if path != found && found.match(new RegExp('^' + escape(path))) != null
				return true

		return false


	_setAttributes: (path, attributes = {}) ->
		@_data[path].stats._setAttributes(attributes)


	_addPath: (path, data = {}, type = null) ->
		if typeof data.stats == 'undefined' then data.stats = {}
		if typeof data.mode == 'undefined' then data.mode = 777
		if typeof data.encoding == 'undefined' then data.encoding = 'utf8'

		if type == null
			if path.match(/\s>>$/) != null
				path = path.substring(0, path.length - 3)
				type = 'directory'
			else
				type = 'file'

		@_data[path] =
			stats: new Stats(path, data.stats)

		@_data[path].stats.mode = data.mode

		if type == 'directory'
			@_data[path].stats._isDirectory = true

			if typeof data.paths != 'undefined'
				for subPath, subData of data.paths
					@_addPath(path + '/' + subPath, subData)

		else if type == 'file'
			@_data[path].stats._isFile = true

			if typeof data.data == 'undefined'
				@_data[path].data = new Buffer('', data.encoding)
			else if data.data instanceof Buffer
				@_data[path].data = data.data
			else
				@_data[path].data = new Buffer(data.data, data.encoding)

			@_data[path].stats.blksize = @_data[path].stats.size = @_data[path].data.length


	_expandPaths: ->
		for path, data of @_data
			@_expandPath(path)


	_expandPath: (path) ->
		match = path.match(/\//g)

		if match != null && match.length > 1
			sub = path
			while sub != null
				position = sub.lastIndexOf('/')
				if position > 0
					sub = sub.substring(0, sub.lastIndexOf('/'))
					if typeof @_data[sub] == 'undefined'
						@_addPath(sub + ' >>')
				else
					sub = null


	_setTree: (tree) ->
		for path, data of tree
			@_addPath(path, data)

		@_expandPaths()


	#*******************************************************************************************************************
	#										RENAME
	#*******************************************************************************************************************


	rename: (oldPath, newPath, callback) ->
		try
			@renameSync(oldPath, newPath)
			callback()
		catch err
			callback(err)


	renameSync: (oldPath, newPath) ->
		if !@existsSync(oldPath)
			Errors.notFound(oldPath)

		if @existsSync(newPath)
			Errors.alreadyExists(newPath)

		@_data[newPath] = @_data[oldPath]
		delete @_data[oldPath]

		@_data[newPath].stats._path = newPath
		@_data[newPath].stats._modifiedAttributes('rename')


	#*******************************************************************************************************************
	#										FTRUNCATE
	#*******************************************************************************************************************


	ftruncate: (fd, len, callback) ->
		try
			@ftruncateSync(fd, len)
			callback()
		catch err
			callback(err)


	ftruncateSync: (fd, len) ->
		if !@_hasFd(fd)
			Errors.fdNotFound(fd)

		item = @_data[@_fileDescriptors[fd].path]

		data = item.data.toString('utf8')
		if item.data.length > len
			data = data.substr(0, len)

		@writeSync(fd, new Buffer(data), 0, data.length, 0)


	#*******************************************************************************************************************
	#										TRUNCATE
	#*******************************************************************************************************************


	truncate: (path, len, callback) ->
		try
			@truncateSync(path, len)
			callback()
		catch err
			callback(err)


	truncateSync: (path, len) ->
		if !@existsSync(path)
			Errors.notFound(path)

		if !@statSync(path).isFile()
			Errors.notFile(path)

		fd = @openSync(path, 'w')
		@ftruncateSync(fd, len)
		@closeSync(fd)


	#*******************************************************************************************************************
	#										CHOWN
	#*******************************************************************************************************************


	chown: (path, uid, gid, callback) ->
		try
			@chownSync(path, uid, gid)
			callback()
		catch err
			callback(err)


	chownSync: (path, uid, gid) ->
		fd = @openSync(path, 'r')
		@fchownSync(fd, uid, gid)
		@closeSync(fd)


	#*******************************************************************************************************************
	#										FCHOWN
	#*******************************************************************************************************************


	fchown: (fd, uid, gid, callback) ->
		try
			@fchownSync(fd, uid, gid)
			callback()
		catch err
			callback(err)


	fchownSync: (fd, uid, gid) ->
		if !@_hasFd(fd)
			Errors.fdNotFound(fd)

		@_setAttributes(@_fileDescriptors[fd].path, uid: uid, gid: gid)


	#*******************************************************************************************************************
	#										LCHOWN
	#*******************************************************************************************************************


	lchown: (path, uid, gid, callback) ->
		@lchownSync(path, uid, gid)
		callback()


	lchownSync: (path, uid, gid) ->
		Errors.notImplemented 'lchown'


	#*******************************************************************************************************************
	#										CHMOD
	#*******************************************************************************************************************


	chmod: (path, mode, callback) ->
		try
			@chmodSync(path, mode)
			callback()
		catch err
			callback(err)


	chmodSync: (path, mode) ->
		fd = @openSync(path, 'r', mode)
		@fchmodSync(fd, mode)
		@closeSync(fd)


	#*******************************************************************************************************************
	#										FCHMOD
	#*******************************************************************************************************************


	fchmod: (fd, mode, callback) ->
		try
			@fchmodSync(fd, mode)
			callback(null)
		catch err
			callback(err)


	fchmodSync: (fd, mode) ->
		if !@_hasFd(fd)
			Errors.fdNotFound(fd)

		@_setAttributes(@_fileDescriptors[fd].path, mode: mode)


	#*******************************************************************************************************************
	#										LCHMOD
	#*******************************************************************************************************************


	lchmod: (path, mode, callback) ->
		@lchmodSync(path, mode)
		callback()


	lchmodSync: (path, mode) ->
		Errors.notImplemented 'lchmod'


	#*******************************************************************************************************************
	#										STAT
	#*******************************************************************************************************************


	stat: (path, callback) ->
		try
			callback(null, @statSync(path))
		catch err
			callback(err, null)


	statSync: (path) ->
		fd = @openSync(path, 'r')
		result = @fstatSync(fd)
		@closeSync(fd)
		return result


	#*******************************************************************************************************************
	#										LSTAT
	#*******************************************************************************************************************


	lstat: (path, callback) ->
		@lstatSync(path)
		callback()


	lstatSync: (path) ->
		Errors.notImplemented 'lstat'


	#*******************************************************************************************************************
	#										FSTAT
	#*******************************************************************************************************************


	fstat: (fd, callback) ->
		try
			callback(null, @fstatSync(fd))
		catch err
			callback(err, null)


	fstatSync: (fd) ->
		if !@_hasFd(fd)
			Errors.fdNotFound(fd)

		return @_data[@_fileDescriptors[fd].path].stats


	#*******************************************************************************************************************
	#										LINK
	#*******************************************************************************************************************


	link: (srcpath, dstpath, callback) ->
		@linkSync(srcpath, dstpath)
		callback()


	linkSync: (srcpath, dstpath) ->
		Errors.notImplemented 'link'


	#*******************************************************************************************************************
	#										SYMLINK
	#*******************************************************************************************************************


	symlink: (srcpath, dstpath, type = null, callback) ->
		if isFunction(type)
			callback = type
			type = null

		@symlinkSync(srcpath, dstpath, type)
		callback()


	symlinkSync: (srcpath, dstpath, type = null) ->
		Errors.notImplemented 'symlink'


	#*******************************************************************************************************************
	#										READLINK
	#*******************************************************************************************************************


	readlink: (path, callback) ->
		@readlinkSync(path)
		callback()


	readlinkSync: (path) ->
		Errors.notImplemented 'readlink'


	#*******************************************************************************************************************
	#										REALPATH
	#*******************************************************************************************************************


	realpath: (path, cache = null, callback) ->
		if isFunction(cache)
			callback = cache
			cache = null

		try
			callback(null, @realpathSync(path, cache))
		catch err
			callback(err, null)


	realpathSync: (path, cache = null) ->
		if cache != null && typeof cache[path] != 'undefined'
			return cache[path]

		if path[0] == '.'
			path = _path.join('/', path)

		path = _path.normalize(path)

		if !@existsSync(path)
			Errors.notFound(path)

		return path


	#*******************************************************************************************************************
	#										UNLINK
	#*******************************************************************************************************************


	unlink: (path, callback) ->
		try
			@unlinkSync(path)
			callback()
		catch err
			callback(err)


	unlinkSync: (path) ->
		if !@existsSync(path)
			Errors.notFound(path)

		if !@statSync(path).isFile()
			Errors.notFile(path)

		delete @_data[path]


	#*******************************************************************************************************************
	#										RMDIR
	#*******************************************************************************************************************


	rmdir: (path, callback) ->
		try
			@rmdirSync(path)
			callback()
		catch err
			callback(err)


	rmdirSync: (path) ->
		if !@existsSync(path)
			Errors.notFound(path)

		if !@statSync(path).isDirectory()
			Errors.notDirectory(path)

		if @_hasSubPaths(path)
			Errors.directoryNotEmpty(path)

		delete @_data[path]


	#*******************************************************************************************************************
	#										MKDIR
	#*******************************************************************************************************************


	mkdir: (path, mode = null, callback) ->
		if isFunction(mode)
			callback = mode
			mode = null

		try
			@mkdirSync(path, mode)
			callback()
		catch err
			callback(err)


	mkdirSync: (path, mode = null) ->
		if @existsSync(path)
			Errors.alreadyExists(path)

		@_addPath(path, mode: mode, 'directory')
		@_expandPath(path)


	#*******************************************************************************************************************
	#										READDIR
	#*******************************************************************************************************************


	readdir: (path, callback) ->
		try
			callback(null, @readdirSync(path))
		catch err
			callback(err, null)


	readdirSync: (path) ->
		if !@existsSync(path)
			Errors.notFound(path)

		if !@statSync(path).isDirectory()
			Errors.notDirectory(path)

		path = escape(path)
		files = []

		for name, data of @_data
			if name != path && (match = name.match(new RegExp('^' + path + '(.+)$'))) != null && match[1].match(/\//g).length == 1
				files.push(name)

		return files


	#*******************************************************************************************************************
	#										CLOSE
	#*******************************************************************************************************************


	close: (fd, callback) ->
		try
			@closeSync(fd)
			callback()
		catch err
			callback(err)


	closeSync: (fd) ->
		if !@_hasFd(fd)
			Errors.fdNotFound(fd)

		delete @_fileDescriptors[fd]


	#*******************************************************************************************************************
	#										OPEN
	#*******************************************************************************************************************


	open: (path, flags, mode = null, callback) ->
		if isFunction(mode)
			callback = mode
			mode = null

		try
			callback(null, @openSync(path, flags, mode))
		catch err
			callback(err, null)


	openSync: (path, flags, mode = null) ->
		if flags in ['r', 'r+'] && !@existsSync(path)
			Errors.notFound(path)

		if flags in ['wx', 'wx+', 'ax', 'ax+'] && @existsSync(path)
			Errors.alreadyExists(path)

		if flags in ['w', 'w+', 'a', 'a+'] && !@existsSync(path)
			options = {}
			if mode != null then options.mode = mode
			@writeFileSync(path, '', options)

		@_fileDescriptors[@_fileDescriptorsCounter] =
			path: path
			flags: flags

		@_fileDescriptorsCounter++

		return @_fileDescriptorsCounter - 1


	#*******************************************************************************************************************
	#										UTIMES
	#*******************************************************************************************************************


	utimes: (path, atime, mtime, callback) ->
		try
			@utimesSync(path, atime, mtime)
			callback(null)
		catch err
			callback(err)


	utimesSync: (path, atime, mtime) ->
		fd = @openSync(path, 'r')
		@futimesSync(fd, atime, mtime)
		@closeSync(fd)


	#*******************************************************************************************************************
	#										FUTIMES
	#*******************************************************************************************************************


	futimes: (fd, atime, mtime, callback) ->
		try
			@futimesSync(fd, atime, mtime)
			callback(null)
		catch err
			callback(err)


	futimesSync: (fd, atime, mtime) ->
		if !@_hasFd(fd)
			Errors.fdNotFound(fd)

		@_setAttributes(@_fileDescriptors[fd].path,
			atime: toDate(atime)
			mtime: toDate(mtime)
		)


	#*******************************************************************************************************************
	#										FSYNC
	#*******************************************************************************************************************


	fsync: (fd, callback) ->
		@fsyncSync(fd)
		callback()


	fsyncSync: (fd) ->
		Errors.notImplemented 'fsync'


	#*******************************************************************************************************************
	#										WRITE
	#*******************************************************************************************************************


	write: (fd, buffer, offset, length, position, callback = null) ->
		try
			@writeSync(fd, buffer, offset, length, position)
			callback(null, length, buffer) if callback isnt null
		catch err
			callback(err, null, buffer) if callback isnt null


	writeSync: (fd, buffer, offset, length, position = 0) ->
		if !@_hasFd(fd)
			Errors.fdNotFound(fd)

		path = @_fileDescriptors[fd].path

		if !isWritable(@_fileDescriptors[fd].flags)
			Errors.notWritable(path)

		if !@statSync(path).isFile()
			Errors.notFile(path)

		item = @_data[path]
		data = buffer.toString('utf8', offset).substr(0, length)

		if position != 0
			oldData = @readFileSync(path, encoding: 'utf8')
			data = [oldData.slice(0, position), data, oldData.slice(position)].join('')

		item.data = new Buffer(data)
		item.stats.size = data.length
		item.stats.blksize = data.length
		item.stats._modified()


	#*******************************************************************************************************************
	#										READ
	#*******************************************************************************************************************


	read: (fd, buffer, offset, length, position = 0, callback = null) ->
		try
			@readSync(fd, buffer, offset, length, position)
			callback(null, length, buffer) if callback isnt null
		catch err
			callback(err, 0, buffer) if callback isnt null


	readSync: (fd, buffer, offset, length, position = 0) ->
		if !@_hasFd(fd)
			Errors.fdNotFound(fd)

		path = @_fileDescriptors[fd].path

		if !isReadable(@_fileDescriptors[fd].flags)
			Errors.notReadable(path)

		if !@statSync(path).isFile()
			Errors.notFile(path)

		item = @_data[path]

		data = item.data.toString('utf8')
		data = data.substr(position, length)

		buffer.write(data, offset)

		item.stats._accessed()

		return length


	#*******************************************************************************************************************
	#										READ FILE
	#*******************************************************************************************************************


	readFile: (filename, options = {}, callback) ->
		if isFunction(options)
			callback = options
			options = null

		try
			callback(null, @readFileSync(filename, options))
		catch err
			callback(err, null)


	readFileSync: (filename, options = {}) ->
		if typeof options.encoding == 'undefined' then options.encoding = null
		if typeof options.flag == 'undefined' then options.flag = 'r'

		fd = @openSync(filename, options.flag)
		size = @statSync(filename).size
		buffer = new Buffer(size)

		@readSync(fd, buffer, 0, size, null)

		@closeSync(fd)

		data = buffer
		if options.encoding != null
			data = buffer.toString(options.encoding)

		return data


	#*******************************************************************************************************************
	#										WRITE FILE
	#*******************************************************************************************************************


	writeFile: (filename, data, options = {}, callback) ->
		if isFunction(options)
			callback = options
			options = null

		try
			callback(null, @writeFileSync(filename, data, options))
		catch err
			callback(err, null)


	writeFileSync: (filename, data, options = {}) ->
		if typeof options.encoding == 'undefined' then options.encoding = 'utf8'
		if typeof options.mode == 'undefined' then options.mode = 438
		if typeof options.flag == 'undefined' then options.flag = 'w'

		fd = @openSync(filename, options.flag, options.mode)
		@writeSync(fd, new Buffer(data, options.encoding), 0, data.length, 0)
		@closeSync(fd)

		@_expandPath(filename)


	#*******************************************************************************************************************
	#										APPEND FILE
	#*******************************************************************************************************************


	appendFile: (filename, data, options = {}, callback) ->
		if isFunction(options)
			callback = options
			options = null

		try
			callback(null, @appendFileSync(filename, data, options))
		catch err
			callback(err, null)


	appendFileSync: (filename, data, options = {}) ->
		if typeof options.encoding == 'undefined' then options.encoding = 'utf8'
		if typeof options.mode == 'undefined' then options.mode = 438
		if typeof options.flag == 'undefined' then options.flag = 'w'

		if typeof data == 'string'
			data = new Buffer(data, options.encoding)

		fd = @openSync(filename, options.flag, options.mode)
		size = @fstatSync(fd).size
		@writeSync(fd, data, 0, data.length, size)
		@closeSync(fd)


	#*******************************************************************************************************************
	#										WATCH FILE
	#*******************************************************************************************************************


	watchFile: (filename, options = null, listener = null) ->
		if isFunction(options)
			listener = options
			options = null

		Errors.notImplemented 'watchFile'


	#*******************************************************************************************************************
	#										UNWATCH FILE
	#*******************************************************************************************************************


	unwatchFile: (filename, listener = null) ->
		Errors.notImplemented 'unwatchFile'


	#*******************************************************************************************************************
	#										WATCH
	#*******************************************************************************************************************


	watch: (filename, options = null, listener = null) ->
		if isFunction(options)
			listener = options
			options = null

		if !@existsSync(filename)
			Errors.notFound(filename)

		watcher = new FSWatcher(listener)

		@statSync(filename).on 'modified', (stats) -> watcher.emit('change', 'change', stats._path)
		@statSync(filename).on 'modifiedAttributes', (stats, event) -> watcher.emit('change', event, stats._path)

		return watcher


	#*******************************************************************************************************************
	#										EXISTS
	#*******************************************************************************************************************


	exists: (path, callback) ->
		callback(@existsSync(path))


	existsSync: (path) ->
		return typeof @_data[path] != 'undefined'


	#*******************************************************************************************************************
	#										CREATE READ STREAM
	#*******************************************************************************************************************


	createReadStream: (path, options = {}) ->
		if typeof options.flags == 'undefined' then options.flags = 'r'
		if typeof options.encoding == 'undefined' then options.encoding = null
		if typeof options.fd == 'undefined' then options.fd = null
		if typeof options.mode == 'undefined' then options.mode = 666
		if typeof options.autoClose == 'undefined' then options.autoClose = true
		if typeof options.start == 'undefined' then options.start = null
		if typeof options.end == 'undefined' then options.end = null

		if options.fd == null
			fd = @openSync(path, options.flags, options.mode)

		size = @fstatSync(fd).size

		rs = new Readable
		buffer = new Buffer(size)

		@readSync(fd, buffer, 0, size, 0)

		data = buffer.toString(options.encoding)
		if options.start != null && options.end != null
			data = data.substring(options.start, options.end)

		rs.push(data)
		rs.push(null)

		if options.autoClose
			@closeSync(fd)

		return rs


	#*******************************************************************************************************************
	#										CREATE WRITE STREAM
	#*******************************************************************************************************************


	createWriteStream: (path, options = {}) ->
		if typeof options.flags == 'undefined' then options.flags = 'w'
		if typeof options.encoding == 'undefined' then options.encoding = null
		if typeof options.mode == 'undefined' then options.mode = 666
		if typeof options.start == 'undefined' then options.start = 0

		fd = @openSync(path, options.flags, options.mode)

		position = options.start

		ws = Writable()
		ws._write = (chunk, enc, next) =>
			if typeof chunk == 'string'
				chunk = new Buffer(chunk)

			@write(fd, chunk, 0, chunk.length, position, ->
				position += chunk.length
				next()
			)

		ws.on 'finish', =>
			@closeSync(fd)

		return ws


module.exports = fs