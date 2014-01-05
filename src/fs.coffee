Stats = require './Stats'
escape = require 'escape-regexp'

isFunction = (obj) -> return Object.prototype.toString.call(obj) == '[object Function]'

class fs


	__data: null

	__fileDescriptors: null

	__fileDescriptorsCounter: 0


	constructor: (tree = {}) ->
		@__data = {}
		@__fileDescriptors = []

		@__setTree(tree)


	__notImplemented: (method) ->
		throw new Error "Method '#{method}' is not implemented."


	__notFound: (path) ->
		throw new Error "File or directory '#{path}' does not exists."


	__alreadyExists: (path) ->
		throw new Error "File or directory '#{path}' already exists."


	__directoryExists: (path) ->
		throw new Error "Directory '#{path}' already exists."


	__notFile: (path) ->
		throw new Error "Path '#{path}' is not a file."


	__notDirectory: (path) ->
		throw new Error "Path '#{path}' is not a directory."


	__directoryNotEmpty: (path) ->
		throw new Error "Directory '#{path}' is not empty."


	__fdNotFound: (fd) ->
		throw new Error "File descriptor #{fd} not exists."


	__isFd: (fd) ->
		return typeof @__fileDescriptors[fd] != 'undefined'


	__fdNotWritable: (fd) ->
		throw new Error "File '#{@__fileDescriptors[fd].path}' is not open for writing."


	__fdNotReadable: (fd) ->
		throw new Error "File '#{@__fileDescriptors[fd].path}' is not open for reading."


	__hasSubPaths: (path) ->
		for found, data of @__data
			if path != found && found.match(new RegExp('^' + escape(path))) != null
				return true

		return false


	__isReadable: (flags) ->
		return flags in ['r', 'r+', 'rs', 'rs+', 'w+', 'wx+', 'a+', 'ax+']


	__isWritable: (flags) ->
		return flags in ['r+', 'rs+', 'w', 'wx', 'w+', 'wx+']


	__isAppendable: (flags) ->
		return flags in ['a', 'ax', 'a+', 'ax+']


	__setAttributes: (path, attributes = {}) ->
		for name, value of attributes
			@__data[path][name] = value

		@__data[path].stats.__modifiedAttributes()


	__addPath: (path, data = {}, type = null) ->
		if typeof data.stats == 'undefined' then data.stats = {}
		if typeof data.mode == 'undefined' then data.mode = 777
		if typeof data.encoding == 'undefined' then data.encoding = 'utf8'

		if type == null
			if path.match(/\s>>$/) != null
				path = path.substring(0, path.length - 3)
				type = 'directory'
			else
				type = 'file'

		@__data[path] =
			mode: data.mode
			uid: 100
			gid: 100
			stats: new Stats(path, data.stats)

		if type == 'directory'
			@__data[path].stats.__isDirectory = true

			if typeof data.paths != 'undefined'
				for subPath, subData of data.paths
					@__addPath(path + '/' + subPath, subData)

		else if type == 'file'
			@__data[path].stats.__isFile = true

			if typeof data.data == 'undefined'
				@__data[path].data = new Buffer('', data.encoding)
			else if data.data instanceof Buffer
				@__data[path].data = data.data
			else
				@__data[path].data = new Buffer(data.data, data.encoding)

			@__data[path].stats.blksize = @__data[path].stats.size = @__data[path].data.length


	__expandPaths: ->
		for path, data of @__data
			@__expandPath(path)


	__expandPath: (path) ->
		match = path.match(/\//g)

		if match != null && match.length > 1
			sub = path
			while sub != null
				position = sub.lastIndexOf('/')
				if position > 0
					sub = sub.substring(0, sub.lastIndexOf('/'))
					if typeof @__data[sub] == 'undefined'
						@__addPath(sub + ' >>')
				else
					sub = null


	__setTree: (tree) ->
		for path, data of tree
			@__addPath(path, data)

		@__expandPaths()


	rename: (oldPath, newPath, callback) ->
		try
			@renameSync(oldPath, newPath)
			callback()
		catch err
			callback(err)


	renameSync: (oldPath, newPath) ->
		if !@existsSync(oldPath)
			@__notFound(oldPath)

		if @existsSync(newPath)
			@__alreadyExists(newPath)

		@__data[newPath] = @__data[oldPath]
		delete @__data[oldPath]

		@__data[newPath].stats.__modifiedAttributes()


	ftruncate: (fd, len, callback) ->
		try
			@ftruncateSync(fd, len)
			callback()
		catch err
			callback(err)


	ftruncateSync: (fd, len) ->
		if !@__isFd(fd)
			@__fdNotFound(fd)

		item = @__data[@__fileDescriptors[fd].path]

		data = item.data.toString('utf8')
		if item.data.length > len
			data = data.substr(0, len)

		@writeSync(fd, new Buffer(data), 0, data.length, 0)


	truncate: (path, len, callback) ->
		try
			@truncateSync(path, len)
			callback()
		catch err
			callback(err)


	truncateSync: (path, len) ->
		if !@existsSync(path)
			@__notFound(path)

		if !@statSync(path).isFile()
			@__notFile(path)

		fd = @openSync(path, 'w')
		@ftruncateSync(fd, len)
		@closeSync(fd)


	chown: (path, uid, gid, callback) ->
		try
			@chownSync(path, uid, gid)
			callback()
		catch err
			callback(err)


	chownSync: (path, uid, gid) ->
		if !@existsSync(path)
			@__notFound(path)

		@__setAttributes(path, uid: uid, gid: gid)


	fchown: (fd, uid, gid, callback) ->
		@fchownSync(fd, uid, gid)
		callback()


	fchownSync: (fd, uid, gid) ->
		@__notImplemented 'fchown'


	lchown: (path, uid, gid, callback) ->
		@lchownSync(path, uid, gid)
		callback()


	lchownSync: (path, uid, gid) ->
		@__notImplemented 'lchown'


	chmod: (path, mode, callback) ->
		try
			@chmodSync(path, mode)
			callback()
		catch err
			callback(err)


	chmodSync: (path, mode) ->
		if !@existsSync(path)
			@__notFound(path)

		@__setAttributes(path, mode: mode)


	fchmod: (fd, mode, callback) ->
		@fchmodSync(fd, mode)
		callback()


	fchmodSync: (fd, mode) ->
		@__notImplemented 'fchmod'


	lchmod: (path, mode, callback) ->
		@lchmodSync(path, mode)
		callback()


	lchmodSync: (path, mode) ->
		@__notImplemented 'lchmod'


	stat: (path, callback) ->
		try
			callback(null, @statSync(path))
		catch err
			callback(err, null)


	statSync: (path) ->
		if !@existsSync(path)
			@__notFound(path)

		return @__data[path].stats


	lstat: (path, callback) ->
		@lstatSync(path)
		callback()


	lstatSync: (path) ->
		@__notImplemented 'lstat'


	fstat: (fd, callback) ->
		@fstatSync(fd)
		callback()


	fstatSync: (path) ->
		@__notImplemented 'fstat'


	link: (srcpath, dstpath, callback) ->
		@linkSync(srcpath, dstpath)
		callback()


	linkSync: (srcpath, dstpath) ->
		@__notImplemented 'link'


	symlink: (srcpath, dstpath, type = null, callback) ->
		if isFunction(type)
			callback = type
			type = null

		@symlinkSync(srcpath, dstpath, type)
		callback()


	symlinkSync: (srcpath, dstpath, type = null) ->
		@__notImplemented 'symlink'


	readlink: (path, callback) ->
		@readlinkSync(path)
		callback()


	readlinkSync: (path) ->
		@__notImplemented 'readlink'


	realpath: (path, cache = null, callback) ->
		if isFunction(cache)
			callback = cache
			cache = null

		@realpathSync(path, cache)
		callback()


	realpathSync: (path, cache = null) ->
		@__notImplemented 'realpath'


	unlink: (path, callback) ->
		try
			@unlinkSync(path)
			callback()
		catch err
			callback(err)


	unlinkSync: (path) ->
		if !@existsSync(path)
			@__notFound(path)

		if !@statSync(path).isFile()
			@__notFile(path)

		delete @__data[path]


	rmdir: (path, callback) ->
		try
			@rmdirSync(path)
			callback()
		catch err
			callback(err)


	rmdirSync: (path) ->
		if !@existsSync(path)
			@__notFound(path)

		if !@statSync(path).isDirectory()
			@__notDirectory(path)

		if @__hasSubPaths(path)
			@__directoryNotEmpty(path)

		delete @__data[path]


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
			@__alreadyExists(path)

		@__addPath(path, mode: mode, 'directory')
		@__expandPath(path)


	readdir: (path, callback) ->
		try
			callback(null, @readdirSync(path))
		catch err
			callback(err, null)


	readdirSync: (path) ->
		if !@existsSync(path)
			@__notFound(path)

		if !@statSync(path).isDirectory()
			@__notDirectory(path)

		path = escape(path)
		files = []

		for name, data of @__data
			if name != path && (match = name.match(new RegExp('^' + path + '(.+)$'))) != null && match[1].match(/\//g).length == 1
				files.push(name)

		return files


	close: (fd, callback) ->
		try
			@closeSync(fd)
			callback()
		catch err
			callback(err)


	closeSync: (fd) ->
		if !@__isFd(fd)
			@__fdNotFound(fd)

		delete @__fileDescriptors[fd]


	open: (path, flags, mode = null, callback) ->
		if isFunction(mode)
			callback = mode
			mode = null

		try
			callback(null, @openSync(path, flags, mode))
		catch err
			callback(err, null)


	openSync: (path, flags, mode = null) ->
		if @existsSync(path) && @statSync(path).isDirectory()
			@__directoryExists(path)

		if flags in ['r', 'r+'] && !@existsSync(path)
			@__notFound(path)

		if flags in ['wx', 'wx+', 'ax', 'ax+'] && @existsSync(path)
			@__alreadyExists(path)

		if flags in ['w', 'w+', 'a', 'a+'] && !@existsSync(path)
			options = {}
			if mode != null then options.mode = mode
			@writeFileSync(path, '', options)

		@__fileDescriptors[@__fileDescriptorsCounter] =
			path: path
			flags: flags

		@__fileDescriptorsCounter++

		return @__fileDescriptorsCounter - 1


	utimes: (path, atime, mtime, callback) ->
		@utimesSync(path, atime, mtime)
		callback()


	utimesSync: (path, atime, mtime) ->
		@__notImplemented 'utime'


	futimes: (fd, atime, mtime, callback) ->
		@futimesSync(fd, atime, mtime)
		callback()


	futimesSync: (fd, atime, mtime) ->
		@__notImplemented 'futime'


	fsync: (fd, callback) ->
		@fsyncSync(fd)
		callback()


	fsyncSync: (fd) ->
		@__notImplemented 'fsync'


	write: (fd, buffer, offset, length, position, callback = null) ->
		try
			@writeSync(fd, buffer, offset, length, position)
			callback(null, length, buffer) if callback isnt null
		catch err
			callback(err, null, buffer) if callback isnt null


	# todo: position
	writeSync: (fd, buffer, offset, length, position) ->
		if !@__isFd(fd)
			@__fdNotFound(fd)

		if !@__isWritable(@__fileDescriptors[fd].flags)
			@__fdNotWritable(fd)

		item = @__data[@__fileDescriptors[fd].path]
		data = buffer.toString('utf8', offset).substr(0, length)

		item.data = new Buffer(data)
		item.stats.size = data.length
		item.stats.blksize = data.length
		item.stats.__modified()


	read: (fd, buffer, offset, length, position = 0, callback = null) ->
		try
			@readSync(fd, buffer, offset, length, position)
			callback(null, length, buffer) if callback isnt null
		catch err
			callback(err, 0, buffer) if callback isnt null


	readSync: (fd, buffer, offset, length, position = 0) ->
		if !@__isFd(fd)
			@__fdNotFound(fd)

		if !@__isReadable(@__fileDescriptors[fd].flags)
			@__fdNotReadable(fd)

		item = @__data[@__fileDescriptors[fd].path]

		data = item.data.toString('utf8')
		data = data.substr(position, length)

		buffer.write(data, offset)

		item.stats.__accessed()

		return length


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

		if !@existsSync(filename)
			@__addPath(filename, data: data, mode: options.mode)

		fd = @openSync(filename, options.flag, options.mode)
		@writeSync(fd, new Buffer(data, options.encoding), 0, data.length, 0)
		@closeSync(fd)

		@__data[filename].stats.__modified()
		@__expandPath(filename)


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

		if !@existsSync(filename)
			@__addPath(filename, data: '', mode: options.mode)

		if !@statSync(filename).isFile()
			@__notFile(filename)

		if data instanceof Buffer
			data = data.toString('utf8')

		data = @__data[filename].data.toString('utf8') + data
		@writeFileSync(filename, data)


	watchFile: (filename, options = null, listener = null) ->
		if isFunction(options)
			listener = options
			options = null

		@__notImplemented 'watchFile'


	unwatchFile: (filename, listener = null) ->
		@__notImplemented 'unwatchFile'


	watch: (filename, options = null, listener = null) ->
		if isFunction(options)
			listener = options
			options = null

		@__notImplemented 'watch'


	exists: (path, callback) ->
		callback(@existsSync(path))


	existsSync: (path) ->
		return typeof @__data[path] != 'undefined'


	createReadStream: (path, options = null) ->
		@__notImplemented 'createReadStream'


	createWriteStream: (path, options = null) ->
		@__notImplemented 'createWriteStream'


module.exports = fs