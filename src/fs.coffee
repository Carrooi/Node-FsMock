Stats = require './Stats'
Errors = require './Errors'
FSWatcher = require './FSWatcher'
Helpers = require './Helpers'
escape = require 'escape-regexp'
Readable = require('stream').Readable
Writable = require('stream').Writable

isFunction   = (obj)   -> return Object.prototype.toString.call(obj) == '[object Function]'
isReadable   = (flags) -> return flags in ['r', 'r+', 'rs', 'rs+', 'w+', 'wx+', 'a+', 'ax+']
isWritable   = (flags) -> return flags in ['r+', 'rs+', 'w', 'wx', 'w+', 'wx+']
isAppendable = (flags) -> return flags in ['a', 'ax', 'a+', 'ax+']
isCreatable  = (flags) -> return flags in ['w', 'w+', 'a', 'a+']

toDate = (time) ->
	if typeof time == 'number'
		return new Date(time * 1000)
	if time instanceof Date
		return time

	throw new Error "Cannot parse time: #{time}"

class fs


	@DELIMITER:
		posix: '/'
		windows: '\\'

	@ROOT_DIRECTORY:
		posix: fs.DELIMITER.posix
		windows: 'c:'


	_options: null

	_data: null

	_fileDescriptors: null

	_fileDescriptorsCounter: 0


	constructor: (tree = {}, options = {}) ->
		@_data = {}
		@_fileDescriptors = []

		if typeof options.windows == 'undefined' then options.windows = false
		if typeof options.root == 'undefined' then options.root = (if options.windows then fs.ROOT_DIRECTORY.windows else fs.ROOT_DIRECTORY.posix)
		if typeof options.drives == 'undefined' then options.drives = []

		if options.root
			options.root = Helpers.normalizePath(options.windows, options.root)
			if options.windows
				options.root = Helpers.normalizeDriveWindows(options.root)

			options._root = escape(options.root)

		options.delimiter = (if options.windows then fs.DELIMITER.windows else fs.DELIMITER.posix)
		options._delimiter = escape(options.delimiter)

		if !options.windows && options.drives.length > 0
			throw new Error 'Options drive can be used only with windows options.'

		@_options = options

		if options.root
			@_addPath(options.root, null, null, true)

		for drive in options.drives
			@_addPath(Helpers.normalizeDriveWindows(drive), null, null, true)

		@_setTree(tree, {})


	_hasFd: (fd) ->
		return typeof @_fileDescriptors[fd] != 'undefined'


	_hasSubPaths: (path) ->
		for found, data of @_data
			if path != found && found.match(new RegExp('^' + escape(path))) != null
				return true

		return false


	_setAttributes: (path, attributes = {}) ->
		@_data[path].stats._setAttributes(attributes)


	_addPath: (path, data = '', info = {}, root = false) ->
		if typeof info.stats == 'undefined' then info.stats = {}
		if typeof info.mode == 'undefined' then info.mode = 777
		if typeof info.encoding == 'undefined' then info.encoding = 'utf8'
		if typeof info.source == 'undefined' then info.source = null

		if path[0] == '@'
			return @linkSync(data, path.substr(1))

		if path[0] == '%'
			type = 'symlink'
			info = {source: data}
			path = path.substr(1)

		else if typeof data == 'string'
			type = 'file'
			info = {data: data}

		else if Object.prototype.toString.call(data) == '[object Object]'
			type = 'directory'
			info = {paths: data}

		else
			throw new Error 'Unknown type'

		if !root && @_options.root && path.match(new RegExp('^' + @_options._root)) == null
			path = Helpers.joinPaths(@_options.windows, @_options.root, path)

		stats = new Stats(path, info.stats)
		stats.mode = info.mode

		@_data[path] = {}

		item = @_data[path]
		item.stats = stats

		switch type
			when 'directory'
				stats._isDirectory = true

				if typeof info.paths != 'undefined'
					for subPath, subData of info.paths
						@_addPath(Helpers.joinPaths(@_options.windows, path, subPath), subData)

			when 'file'
				stats._isFile = true

				if typeof info.data == 'undefined'
					item.data = new Buffer('', info.encoding)
				else if info.data instanceof Buffer
					item.data = info.data
				else
					item.data = new Buffer(info.data, info.encoding)

				stats.blksize = stats.size = item.data.length

			when 'symlink'
				stats._isSymlink = true

				item.source = info.source

			else
				throw new Error "Type must be directory, file or symlink, #{type} given."


	_expandPaths: ->
		for path, data of @_data
			@_expandPath(path)


	_expandPath: (path) ->
		match = path.match(new RegExp(@_options._delimiter, 'g'))

		if match != null && match.length > 1
			sub = path
			while sub != null
				position = sub.lastIndexOf(@_options.delimiter)
				if position > 0
					sub = sub.substring(0, sub.lastIndexOf(@_options.delimiter))
					if typeof @_data[sub] == 'undefined'
						@_addPath(sub, {})
				else
					sub = null


	_setTree: (tree, info = {}) ->
		for path, data of tree
			@_addPath(path, data)

		for path, attributes of info
			@_setAttributes(path, attributes)

		@_expandPaths()


	_realpath: (path) ->
		if path[0] == '.'
			path = Helpers.joinPaths(@_options.windows, @_options.delimiter, path)

		return Helpers.normalizePath(@_options.windows, path)


	_getSourcePath: (path) ->
		path = @_realpath(path)
		if @_data[path]?.stats.isSymbolicLink()
			path = @_data[path].source

		return path


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
		oldPath = @realpathSync(oldPath)
		newPath = @_realpath(newPath)

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

		@writeSync(fd, new Buffer(data), 0, data.length, null)


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
		path = @_getSourcePath(path)

		if !@existsSync(path)
			Errors.notFound(path)

		fd = @openSync(path, 'w')

		if !@fstatSync(fd).isFile()
			Errors.notFile(path)

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
		path = @_getSourcePath(path)

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
		try
			@lchownSync(path, uid, gid)
			callback(null)
		catch err
			callback(err)


	lchownSync: (path, uid, gid) ->
		path = @realpathSync(path)

		if !@existsSync(path)
			Errors.notFound(path)

		if !@lstatSync(path).isSymbolicLink()
			Errors.notSymlink(path)

		@_setAttributes(path,
			uid: uid
			gid: gid
		)


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
		path = @_getSourcePath(path)

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
		try
			@lchmodSync(path, mode)
			callback(null)
		catch err
			callback(err)


	lchmodSync: (path, mode) ->
		path = @realpathSync(path)

		if !@existsSync(path)
			Errors.notFound(path)

		if !@lstatSync(path).isSymbolicLink()
			Errors.notSymlink(path)

		@_setAttributes(path,
			mode: mode
		)


	#*******************************************************************************************************************
	#										STAT
	#*******************************************************************************************************************


	stat: (path, callback) ->
		try
			callback(null, @statSync(path))
		catch err
			callback(err, null)


	statSync: (path) ->
		path = @_getSourcePath(path)

		fd = @openSync(path, 'r')
		result = @fstatSync(fd)
		@closeSync(fd)
		return result


	#*******************************************************************************************************************
	#										LSTAT
	#*******************************************************************************************************************


	lstat: (path, callback) ->
		try
			callback(null, @lstatSync(path))
		catch err
			callback(err, null)


	lstatSync: (path) ->
		path = @realpathSync(path)

		if !@existsSync(path)
			Error.notFound(path)

		stats = @_data[path].stats

		if !stats.isSymbolicLink()
			Errors.notSymlink(path)

		return stats


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
		try
			@linkSync(srcpath, dstpath)
			callback(null)
		catch err
			callback(err)


	linkSync: (srcpath, dstpath) ->
		srcpath = @realpathSync(srcpath)
		dstpath = @_realpath(dstpath)

		if !@existsSync(srcpath)
			Errors.notFound(srcpath)

		@_data[dstpath] = @_data[srcpath]


	#*******************************************************************************************************************
	#										SYMLINK
	#*******************************************************************************************************************


	symlink: (srcpath, dstpath, type = null, callback) ->
		if isFunction(type)
			callback = type
			type = null

		try
			@symlinkSync(srcpath, dstpath)
			callback(null)
		catch err
			callback(err)


	symlinkSync: (srcpath, dstpath, type = null) ->
		srcpath = @realpathSync(srcpath)
		dstpath = @_realpath(dstpath)

		if !@existsSync(srcpath)
			Errors.notFound(srcpath)

		@_addPath('%' + dstpath, srcpath)


	#*******************************************************************************************************************
	#										READLINK
	#*******************************************************************************************************************


	readlink: (path, callback) ->
		try
			callback(null, @readlinkSync(path))
		catch err
			callback(err, null)


	readlinkSync: (path) ->
		path = @_getSourcePath(path)

		if !@existsSync(path)
			Errors.notFound(path)

		return path


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

		path = @_realpath(path)

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
		path = @realpathSync(path)

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
		path = @realpathSync(path)

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
		path = @_realpath(path)

		if @existsSync(path)
			Errors.alreadyExists(path)

		@_addPath(path, {}, mode: mode)
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
		path = @_getSourcePath(path)

		if !@existsSync(path)
			Errors.notFound(path)

		if !@statSync(path).isDirectory()
			Errors.notDirectory(path)

		path = if path == @_options.delimiter then '' else path
		path = escape(path)
		files = []

		for name, data of @_data
			if name != path && name != @_options.delimiter && (match = name.match(new RegExp('^' + path + '(.+)$'))) != null
				slashes = match[1].match(new RegExp(@_options._delimiter, 'g'))
				slashes = if slashes == null then 0 else slashes.length
				if slashes == 1
					files.push(match[1].substr(1))

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
		path = @_getSourcePath(path)
		exists = @existsSync(path)

		if flags in ['r', 'r+'] && !exists
			Errors.notFound(path)

		if flags in ['wx', 'wx+', 'ax', 'ax+'] && exists
			Errors.alreadyExists(path)

		@_fileDescriptors[@_fileDescriptorsCounter] =
			path: path
			flags: flags

		if isCreatable(flags) && !exists
			@_addPath(path, '', mode: mode)

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
		path = @realpathSync(path)

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
		try
			@fsyncSync(fd)
			callback(null)
		catch err
			callback(err)


	fsyncSync: (fd) ->
		if !@_hasFd(fd)
			Errors.fdNotFound(fd)


	#*******************************************************************************************************************
	#										WRITE
	#*******************************************************************************************************************


	write: (fd, buffer, offset, length, position = null, callback = null) ->
		try
			@writeSync(fd, buffer, offset, length, position)
			callback(null, length, buffer) if callback isnt null
		catch err
			callback(err, null, buffer) if callback isnt null


	writeSync: (fd, buffer, offset, length, position = null) ->
		if !@_hasFd(fd)
			Errors.fdNotFound(fd)

		fdData = @_fileDescriptors[fd]
		path = fdData.path

		if !isWritable(fdData.flags)
			Errors.notWritable(path)

		stats = @fstatSync(fd)

		if !stats.isFile()
			Errors.notFile(path)

		item = @_data[path]
		data = buffer.toString('utf8', offset).substr(0, length)

		if position != null
			buffer = new Buffer(stats.size)
			oldFlags = fdData.flags		# workaround for reading
			fdData.flags = 'r'
			@readSync(fd, buffer, 0, stats.size, 0)
			fdData.flags = oldFlags
			oldData = buffer.toString('utf8')
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

		item = @_fileDescriptors[fd]
		path = item.path

		if !isReadable(item.flags)
			Errors.notReadable(path)

		if !@fstatSync(fd).isFile()
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
		size = @fstatSync(fd).size
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

		filename = @_getSourcePath(filename)

		fd = @openSync(filename, options.flag, options.mode)
		@writeSync(fd, new Buffer(data, options.encoding), 0, data.length, null)
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
		stats = @statSync(filename)

		stats.on 'modified', (stats) -> watcher.emit('change', 'change', stats._path)
		stats.on 'modifiedAttributes', (stats, event) -> watcher.emit('change', event, stats._path)

		return watcher


	#*******************************************************************************************************************
	#										EXISTS
	#*******************************************************************************************************************


	exists: (path, callback) ->
		callback(@existsSync(path))


	existsSync: (path) ->
		path = @_realpath(path)
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

		rs = new Readable

		try
			if options.fd == null
				fd = @openSync(path, options.flags, options.mode)

			size = @fstatSync(fd).size

			buffer = new Buffer(size)

			@readSync(fd, buffer, 0, size, 0)

			data = buffer.toString(options.encoding)
			if options.start != null && options.end != null
				data = data.substring(options.start, options.end)

			rs.push(data)
			rs.push(null)

			if options.autoClose
				@closeSync(fd)
		catch err
			process.nextTick ->
				rs.emit('error', err)
		return rs


	#*******************************************************************************************************************
	#										CREATE WRITE STREAM
	#*******************************************************************************************************************


	createWriteStream: (path, options = {}) ->
		if typeof options.flags == 'undefined' then options.flags = 'w'
		if typeof options.encoding == 'undefined' then options.encoding = null
		if typeof options.mode == 'undefined' then options.mode = 666
		if typeof options.start == 'undefined' then options.start = 0

		ws = Writable()

		try
			fd = @openSync(path, options.flags, options.mode)
		catch err
			process.nextTick ->
				ws.emit('error', err)

		position = options.start

		ws._write = (chunk, enc, next) =>
			if typeof chunk == 'string'
				chunk = new Buffer(chunk)

			@write(fd, chunk, 0, chunk.length, position, (err) ->
				if err
					process.nextTick ->
						ws.emit('error', err)

				position += chunk.length
				next()
			)

		ws.on 'finish', =>
			@closeSync(fd)

		return ws


module.exports = fs
