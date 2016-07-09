(function() {

	var escape = require('escape-regexp');
	var Readable = require('stream').Readable;
	var Writable = require('stream').Writable;

	var Stats = require('./Stats');
	var Errors = require('./Errors');
	var FSWatcher = require('./FSWatcher');
	var Helpers = require('./Helpers');


	var bind = function(fn, self) {
		return function() {
			return fn.apply(self, arguments);
		};
	};


	var isFunction = function(obj) {
		return Object.prototype.toString.call(obj) === '[object Function]';
	};


	var isReadable = function(flags) {
		return flags === 'r' || flags === 'r+' || flags === 'rs' || flags === 'rs+' || flags === 'w+' || flags === 'wx+' || flags === 'a+' || flags === 'ax+';
	};


	var isWritable = function(flags) {
		return flags === 'r+' || flags === 'rs+' || flags === 'w' || flags === 'wx' || flags === 'w+' || flags === 'wx+';
	};


	var isCreatable = function(flags) {
		return flags === 'w' || flags === 'w+' || flags === 'a' || flags === 'a+';
	};


	var toDate = function(time) {
		if (typeof time === 'number') {
			return new Date(time * 1000);
		}

		if (time instanceof Date) {
			return time;
		}

		throw new Error("Cannot parse time: " + time);
	};


	var fs = function(tree, options) {
		var drive, i;

		if (tree == null) {
			tree = {};
		}

		if (options == null) {
			options = {};
		}

		this._data = {};
		this._fileDescriptors = [];

		if (typeof options.windows === 'undefined') {
			options.windows = false;
		}

		if (typeof options.root === 'undefined') {
			options.root = (options.windows ? fs.ROOT_DIRECTORY.windows : fs.ROOT_DIRECTORY.posix);
		}

		if (typeof options.drives === 'undefined') {
			options.drives = [];
		}

		if (options.root) {
			options.root = Helpers.normalizePath(options.windows, options.root);

			if (options.windows) {
				options.root = Helpers.normalizeDriveWindows(options.root);
			}

			options._root = escape(options.root);
		}

		options.delimiter = (options.windows ? fs.DELIMITER.windows : fs.DELIMITER.posix);
		options._delimiter = escape(options.delimiter);

		if (!options.windows && options.drives.length > 0) {
			throw new Error('Options drive can be used only with windows options.');
		}

		this._options = options;

		if (options.root) {
			this._addPath(options.root, null, null, true);
		}

		for (i = 0; i < options.drives.length; i++) {
			this._addPath(Helpers.normalizeDriveWindows(options.drives[i]), null, null, true);
		}

		this._setTree(tree, {});

		this.rename = bind(this.rename, this);
		this.renameSync = bind(this.renameSync, this);
		this.ftruncate = bind(this.ftruncate, this);
		this.ftruncateSync = bind(this.ftruncateSync, this);
		this.truncate = bind(this.truncate, this);
		this.truncateSync = bind(this.truncateSync, this);
		this.chown = bind(this.chown, this);
		this.chownSync = bind(this.chownSync, this);
		this.fchown = bind(this.fchown, this);
		this.fchownSync = bind(this.fchownSync, this);
		this.lchown = bind(this.lchown, this);
		this.lchownSync = bind(this.lchownSync, this);
		this.chmod = bind(this.chmod, this);
		this.chmodSync = bind(this.chmodSync, this);
		this.fchmod = bind(this.fchmod, this);
		this.fchmodSync = bind(this.fchmodSync, this);
		this.lchmod = bind(this.lchmod, this);
		this.lchmodSync = bind(this.lchmodSync, this);
		this.stat = bind(this.stat, this);
		this.statSync = bind(this.statSync, this);
		this.lstat = bind(this.lstat, this);
		this.lstatSync = bind(this.lstatSync, this);
		this.fstat = bind(this.fstat, this);
		this.fstatSync = bind(this.fstatSync, this);
		this.link = bind(this.link, this);
		this.linkSync = bind(this.linkSync, this);
		this.symlink = bind(this.symlink, this);
		this.symlinkSync = bind(this.symlinkSync, this);
		this.readlink = bind(this.readlink, this);
		this.readlinkSync = bind(this.readlinkSync, this);
		this.realpath = bind(this.realpath, this);
		this.realpathSync = bind(this.realpathSync, this);
		this.unlink = bind(this.unlink, this);
		this.unlinkSync = bind(this.unlinkSync, this);
		this.rmdir = bind(this.rmdir, this);
		this.rmdirSync = bind(this.rmdirSync, this);
		this.mkdir = bind(this.mkdir, this);
		this.mkdirSync = bind(this.mkdirSync, this);
		this.readdir = bind(this.readdir, this);
		this.readdirSync = bind(this.readdirSync, this);
		this.close = bind(this.close, this);
		this.closeSync = bind(this.closeSync, this);
		this.open = bind(this.open, this);
		this.openSync = bind(this.openSync, this);
		this.utimes = bind(this.utimes, this);
		this.utimesSync = bind(this.utimesSync, this);
		this.futimes = bind(this.futimes, this);
		this.futimesSync = bind(this.futimesSync, this);
		this.fsync = bind(this.fsync, this);
		this.fsyncSync = bind(this.fsyncSync, this);
		this.write = bind(this.write, this);
		this.writeSync = bind(this.writeSync, this);
		this.read = bind(this.read, this);
		this.readSync = bind(this.readSync, this);
		this.readFile = bind(this.readFile, this);
		this.readFileSync = bind(this.readFileSync, this);
		this.writeFile = bind(this.writeFile, this);
		this.writeFileSync = bind(this.writeFileSync, this);
		this.appendFile = bind(this.appendFile, this);
		this.appendFileSync = bind(this.appendFileSync, this);
		this.watchFile = bind(this.watchFile, this);
		this.unwatchFile = bind(this.unwatchFile, this);
		this.watch = bind(this.watch, this);
		this.exists = bind(this.exists, this);
		this.existsSync = bind(this.existsSync, this);
		this.createReadStream = bind(this.createReadStream, this);
		this.createWriteStream = bind(this.createWriteStream, this);
	};


	fs.DELIMITER = {
		posix: '/',
		windows: '\\'
	};

	fs.ROOT_DIRECTORY = {
		posix: fs.DELIMITER.posix,
		windows: 'c:'
	};


	fs.prototype._options = null;

	fs.prototype._data = null;

	fs.prototype._fileDescriptors = null;

	fs.prototype._fileDescriptorsCounter = 0;


	fs.prototype._hasFd = function(fd) {
		return typeof this._fileDescriptors[fd] !== 'undefined';
	};


	fs.prototype._hasSubPaths = function(path) {
		var found;

		for (found in this._data) {
			if (this._data.hasOwnProperty(found)) {
				if (path !== found && found.match(new RegExp('^' + escape(path))) !== null) {
					return true;
				}
			}
		}

		return false;
	};


	fs.prototype._setAttributes = function(path, attributes) {
		if (attributes == null) {
			attributes = {};
		}

		return this._data[path].stats._setAttributes(attributes);
	};


	fs.prototype._addPath = function(path, data, info, root) {
		var item, stats, subData, subPath, type;

		if (data == null) {
			data = '';
		}

		if (info == null) {
			info = {};
		}

		if (root == null) {
			root = false;
		}

		if (typeof info.stats === 'undefined') {
			info.stats = {};
		}

		if (typeof info.mode === 'undefined') {
			info.mode = 777;
		}

		if (typeof info.encoding === 'undefined') {
			info.encoding = 'utf8';
		}

		if (typeof info.source === 'undefined') {
			info.source = null;
		}

		if (path[0] === '@') {
			return this.linkSync(data, path.substr(1));
		}

		if (root) {
			type = 'directory';
			info = {
				paths: {}
			};

		} else if (path[0] === '%') {
			type = 'symlink';
			path = path.substr(1);
			info = {
				source: data
			};

		} else if (typeof data === 'string' || data instanceof Buffer) {
			type = 'file';
			info = {
				data: data
			};

		} else if (Object.prototype.toString.call(data) === '[object Object]') {
			type = 'directory';
			info = {
				paths: data
			};

		} else {
			throw new Error('Unknown type');
		}

		if (!root && this._options.root && path.match(new RegExp('^' + this._options._root)) === null) {
			path = Helpers.joinPaths(this._options.windows, this._options.root, path);
		}

		path = Helpers.normalizePath(this._options.windows, path);

		stats = new Stats(path, info.stats);
		stats.mode = info.mode;

		this._data[path] = {};

		item = this._data[path];
		item.stats = stats;

		switch (type) {
			case 'directory':
				stats._isDirectory = true;

				if (typeof info.paths !== 'undefined') {
					for (subPath in info.paths) {
						if (info.paths.hasOwnProperty(subPath)) {
							subData = info.paths[subPath];
							this._addPath(Helpers.joinPaths(this._options.windows, path, subPath), subData);
						}
					}
				}

				break;
			case 'file':

				stats._isFile = true;

				if (typeof info.data === 'undefined') {
					item.data = new Buffer('', info.encoding);

				} else if (info.data instanceof Buffer) {
					item.data = info.data;

				} else {
					item.data = new Buffer(info.data, info.encoding);
				}

				stats.blksize = stats.size = item.data.length;

				break;
			case 'symlink':
				stats._isSymlink = true;
				item.source = info.source;

				break;
			default:
				throw new Error("Type must be directory, file or symlink, " + type + " given.");
		}
	};


	fs.prototype._expandPaths = function() {
		var path;

		for (path in this._data) {
			if (this._data.hasOwnProperty(path)) {
				this._expandPath(path);
			}
		}
	};


	fs.prototype._expandPath = function(path) {
		var match, position, sub;

		match = path.match(new RegExp(this._options._delimiter, 'g'));

		if (match !== null && match.length > 1) {
			sub = path;

			while (sub !== null) {
				position = sub.lastIndexOf(this._options.delimiter);

				if (position > 0) {
					sub = sub.substring(0, sub.lastIndexOf(this._options.delimiter));

					if (typeof this._data[sub] === 'undefined') {
						this._addPath(sub, {});
					}

				} else {
					sub = null;
				}
			}
		}
	};


	fs.prototype._setTree = function(tree, info) {
		var path;

		if (info == null) {
			info = {};
		}

		for (path in tree) {
			if (tree.hasOwnProperty(path)) {
				this._addPath(path, tree[path]);
			}
		}

		for (path in info) {
			if (info.hasOwnProperty(path)) {
				this._setAttributes(path, info[path]);
			}
		}

		this._expandPaths();
	};


	fs.prototype._realpath = function(path) {
		if (path[0] === '.') {
			path = Helpers.joinPaths(this._options.windows, this._options.delimiter, path);
		}

		return Helpers.normalizePath(this._options.windows, path);
	};


	fs.prototype._getSourcePath = function(path) {
		path = this._realpath(path);

		if (!this._data[path]) {
			return path;
		}

		if (this._data[path].stats.isSymbolicLink()) {
			return this._data[path].source;
		}

		return path;
	};


	fs.prototype.rename = function(oldPath, newPath, callback) {
		try {
			this.renameSync(oldPath, newPath);
		} catch (e) {
			return callback(e);
		}
		return callback();
	};


	fs.prototype.renameSync = function(oldPath, newPath) {
		oldPath = this.realpathSync(oldPath);
		newPath = this._realpath(newPath);

		if (!this.existsSync(oldPath)) {
			Errors.notFound(oldPath);
		}

		if (this.existsSync(newPath)) {
			Errors.alreadyExists(newPath);
		}

		this._data[newPath] = this._data[oldPath];

		delete this._data[oldPath];

		this._data[newPath].stats._path = newPath;
		this._data[newPath].stats._modifiedAttributes('rename');
	};


	fs.prototype.ftruncate = function(fd, len, callback) {
		try {
			this.ftruncateSync(fd, len);
		} catch (e) {
			return callback(e);
		}
		return callback();
	};


	fs.prototype.ftruncateSync = function(fd, len) {
		var data, item;

		if (!this._hasFd(fd)) {
			Errors.fdNotFound(fd);
		}

		item = this._data[this._fileDescriptors[fd].path];
		data = item.data.toString('utf8');

		if (item.data.length > len) {
			data = data.substr(0, len);
		}

		return this.writeSync(fd, new Buffer(data), 0, data.length, null);
	};


	fs.prototype.truncate = function(path, len, callback) {
		try {
			this.truncateSync(path, len);
		} catch (e) {
			return callback(e);
		}
		return callback();
	};


	fs.prototype.truncateSync = function(path, len) {
		var fd;

		path = this._getSourcePath(path);

		if (!this.existsSync(path)) {
			Errors.notFound(path);
		}

		fd = this.openSync(path, 'w');

		if (!this.fstatSync(fd).isFile()) {
			Errors.notFile(path);
		}

		this.ftruncateSync(fd, len);

		this.closeSync(fd);
	};


	fs.prototype.chown = function(path, uid, gid, callback) {

		try {
			this.chownSync(path, uid, gid);
		} catch (e) {
			return callback(e);
		}

	  return callback();
	};


	fs.prototype.chownSync = function(path, uid, gid) {
		var fd;

		path = this._getSourcePath(path);
		fd = this.openSync(path, 'r');

		this.fchownSync(fd, uid, gid);

		this.closeSync(fd);
	};


	fs.prototype.fchown = function(fd, uid, gid, callback) {
		try {
			this.fchownSync(fd, uid, gid);
		} catch (e) {
			return callback(e);
		}

		return callback();
	};


	fs.prototype.fchownSync = function(fd, uid, gid) {
		if (!this._hasFd(fd)) {
			Errors.fdNotFound(fd);
		}

		this._setAttributes(this._fileDescriptors[fd].path, {
			uid: uid,
			gid: gid
		});
	};


	fs.prototype.lchown = function(path, uid, gid, callback) {
		try {
			this.lchownSync(path, uid, gid);
		} catch (e) {
			return callback(e);
		}

		return callback(null);
	};

	fs.prototype.lchownSync = function(path, uid, gid) {
		path = this.realpathSync(path);

		if (!this.existsSync(path)) {
			Errors.notFound(path);
		}

		if (!this.lstatSync(path).isSymbolicLink()) {
			Errors.notSymlink(path);
		}

		this._setAttributes(path, {
			uid: uid,
			gid: gid
		});
	};


	fs.prototype.chmod = function(path, mode, callback) {
		try {
			this.chmodSync(path, mode);
		} catch (e) {
			return callback(e);
		}
		return callback();
	};


	fs.prototype.chmodSync = function(path, mode) {
		var fd;

		path = this._getSourcePath(path);
		fd = this.openSync(path, 'r', mode);

		this.fchmodSync(fd, mode);

		this.closeSync(fd);
	};


	fs.prototype.fchmod = function(fd, mode, callback) {
		try {
			this.fchmodSync(fd, mode);
		} catch (e) {
			return callback(e);
		}
		return callback(null);
	};


	fs.prototype.fchmodSync = function(fd, mode) {
		if (!this._hasFd(fd)) {
			Errors.fdNotFound(fd);
		}

		this._setAttributes(this._fileDescriptors[fd].path, {
			mode: mode
		});
	};

	fs.prototype.lchmod = function(path, mode, callback) {
		try {
			this.lchmodSync(path, mode);
		} catch (e) {
			return callback(e);
		}
		return callback(null);
	};


	fs.prototype.lchmodSync = function(path, mode) {
		path = this.realpathSync(path);

		if (!this.existsSync(path)) {
			Errors.notFound(path);
		}

		if (!this.lstatSync(path).isSymbolicLink()) {
			Errors.notSymlink(path);
		}

		this._setAttributes(path, {
			mode: mode
		});
	};


	fs.prototype.stat = function(path, callback) {
	  var stat;

		try {
			stat = this.statSync(path);
		} catch (e) {
			return callback(e, null);
		}

	  return callback(null, stat);
	};


	fs.prototype.statSync = function(path) {
		var fd, result;

		path = this._getSourcePath(path);
		fd = this.openSync(path, 'r');
		result = this.fstatSync(fd);

		this.closeSync(fd);

		return result;
	};


	fs.prototype.lstat = function(path, callback) {
	  var stat;

		try {
			stat = this.lstatSync(path);
		} catch (e) {
			return callback(e, null);
		}

	  return callback(null, stat);
	};


	fs.prototype.lstatSync = function(path) {
		var stats;

		path = this.realpathSync(path);

		if (!this.existsSync(path)) {
			Error.notFound(path);
		}

		stats = this._data[path].stats;

		return stats;
	};


	fs.prototype.fstat = function(fd, callback) {
	  var stat;

		try {
			stat = this.fstatSync(fd);
		} catch (e) {
			return callback(e, null);
		}

	  return callback(null, stat);
	};


	fs.prototype.fstatSync = function(fd) {
		if (!this._hasFd(fd)) {
			Errors.fdNotFound(fd);
		}

		return this._data[this._fileDescriptors[fd].path].stats;
	};


	fs.prototype.link = function(srcpath, dstpath, callback) {

		try {
			this.linkSync(srcpath, dstpath);
		} catch (e) {
			return callback(e);
		}

		return callback(null);
	};


	fs.prototype.linkSync = function(srcpath, dstpath) {
		srcpath = this.realpathSync(srcpath);
		dstpath = this._realpath(dstpath);

		if (!this.existsSync(srcpath)) {
			Errors.notFound(srcpath);
		}

		return this._data[dstpath] = this._data[srcpath];
	};


	fs.prototype.symlink = function(srcpath, dstpath, type, callback) {
		if (type == null) {
			type = null;
		}

		if (isFunction(type)) {
			callback = type;
			type = null;
		}

		try {
			this.symlinkSync(srcpath, dstpath);
		} catch (e) {
			return callback(e);
		}
		return callback(null);
	};


	fs.prototype.symlinkSync = function(srcpath, dstpath, type) {
		if (type == null) {
			type = null;
		}

		srcpath = this.realpathSync(srcpath);
		dstpath = this._realpath(dstpath);

		if (!this.existsSync(srcpath)) {
			Errors.notFound(srcpath);
		}

		this._addPath('%' + dstpath, srcpath);
	};


	fs.prototype.readlink = function(path, callback) {
	  var linkString;

		try {
			linkString = this.readlinkSync(path);
		} catch (e) {
			return callback(e, null);
		}

	  return callback(null, linkString);
	};


	fs.prototype.readlinkSync = function(path) {
		path = this._getSourcePath(path);

		if (!this.existsSync(path)) {
			Errors.notFound(path);
		}

		return path;
	};


	fs.prototype.realpath = function(path, cache, callback) {
		if (cache == null) {
			cache = null;
		}

		if (isFunction(cache)) {
			callback = cache;
			cache = null;
		}

	  var resolvedPath;

		try {
			resolvedPath = this.realpathSync(path, cache);
		} catch (e) {
			return callback(e, null);
		}

	  return callback(null, resolvedPath);
	};


	fs.prototype.realpathSync = function(path, cache) {
		if (cache == null) {
			cache = null;
		}

		if (cache !== null && typeof cache[path] !== 'undefined') {
			return cache[path];
		}

		path = this._realpath(path);

		if (!this.existsSync(path)) {
			Errors.notFound(path);
		}

		return path;
	};


	fs.prototype.unlink = function(path, callback) {
		try {
			this.unlinkSync(path);
		} catch (e) {
			return callback(e);
		}

	  return callback();
	};


	fs.prototype.unlinkSync = function(path) {
		path = this.realpathSync(path);

		if (!this.existsSync(path)) {
			Errors.notFound(path);
		}

		if (!this.statSync(path).isFile()) {
			Errors.notFile(path);
		}

		delete this._data[path];
	};


	fs.prototype.rmdir = function(path, callback) {
		try {
			this.rmdirSync(path);
		} catch (e) {
			return callback(e);
		}

		return callback();
	};


	fs.prototype.rmdirSync = function(path) {
		path = this.realpathSync(path);

		if (!this.existsSync(path)) {
			Errors.notFound(path);
		}

		if (!this.statSync(path).isDirectory()) {
			Errors.notDirectory(path);
		}

		if (this._hasSubPaths(path)) {
			Errors.directoryNotEmpty(path);
		}

		delete this._data[path];
	};


	fs.prototype.mkdir = function(path, mode, callback) {
		if (mode == null) {
			mode = null;
		}

		if (isFunction(mode)) {
			callback = mode;
			mode = null;
		}

		try {
			this.mkdirSync(path, mode);
		} catch (e) {
			return callback(e);
		}

	  return callback();
	};


	fs.prototype.mkdirSync = function(path, mode) {
		if (mode == null) {
			mode = null;
		}

		path = this._realpath(path);

		if (this.existsSync(path)) {
			Errors.alreadyExists(path);
		}

		this._addPath(path, {}, {
			mode: mode
		});

		this._expandPath(path);
	};


	fs.prototype.readdir = function(path, callback) {
	  var files;

		try {
	    files = this.readdirSync(path);
		} catch (e) {
			return callback(e, null);
		}

		return callback(null, files);
	};


	fs.prototype.readdirSync = function(path) {
		var files, match, name, slashes;

		path = this._getSourcePath(path);

		if (!this.existsSync(path)) {
			Errors.notFound(path);
		}

		if (!this.statSync(path).isDirectory()) {
			Errors.notDirectory(path);
		}

		path = path === this._options.delimiter ? '' : path;
		path = escape(path);
		files = [];

		for (name in this._data) {
			if (this._data.hasOwnProperty(name) && name !== path && name !== this._options.delimiter && (match = name.match(new RegExp('^' + path + '(.+)$'))) !== null) {
				slashes = match[1].match(new RegExp(this._options._delimiter, 'g'));
				slashes = slashes === null ? 0 : slashes.length;
				if (slashes === 1) {
					files.push(match[1].substr(1));
				}
			}
		}

		return files;
	};


	fs.prototype.close = function(fd, callback) {
		try {
			this.closeSync(fd);
		} catch (e) {
			return callback(e);
		}

	  return callback();
	};


	fs.prototype.closeSync = function(fd) {
		if (!this._hasFd(fd)) {
			Errors.fdNotFound(fd);
		}

		delete this._fileDescriptors[fd];
	};


	fs.prototype.open = function(path, flags, mode, callback) {
		if (mode == null) {
			mode = null;
		}

		if (isFunction(mode)) {
			callback = mode;
			mode = null;
		}

	  var fd;

		try {
			fd = this.openSync(path, flags, mode);
		} catch (e) {
			return callback(e, null);
		}

	  return callback(null, fd);
	};


	fs.prototype.openSync = function(path, flags, mode) {
		var exists;

		if (mode == null) {
			mode = null;
		}

		path = this._getSourcePath(path);
		exists = this.existsSync(path);

		if ((flags === 'r' || flags === 'r+') && !exists) {
			Errors.notFound(path);
		}

		if ((flags === 'wx' || flags === 'wx+' || flags === 'ax' || flags === 'ax+') && exists) {
			Errors.alreadyExists(path);
		}

		this._fileDescriptors[this._fileDescriptorsCounter] = {
			path: path,
			flags: flags
		};

		if (isCreatable(flags) && !exists) {
			this._addPath(path, '', {
				mode: mode
			});
		}

		this._fileDescriptorsCounter++;

		return this._fileDescriptorsCounter - 1;
	};


	fs.prototype.utimes = function(path, atime, mtime, callback) {
		try {
			this.utimesSync(path, atime, mtime);
		} catch (e) {
			return callback(e);
		}

		return callback(null);
	};


	fs.prototype.utimesSync = function(path, atime, mtime) {
		var fd;

		path = this.realpathSync(path);
		fd = this.openSync(path, 'r');

		this.futimesSync(fd, atime, mtime);
		this.closeSync(fd);
	};


	fs.prototype.futimes = function(fd, atime, mtime, callback) {
		try {
			this.futimesSync(fd, atime, mtime);
		} catch (e) {
			return callback(e);
		}

	  return callback(null);
	};


	fs.prototype.futimesSync = function(fd, atime, mtime) {
		if (!this._hasFd(fd)) {
			Errors.fdNotFound(fd);
		}

		this._setAttributes(this._fileDescriptors[fd].path, {
			atime: toDate(atime),
			mtime: toDate(mtime)
		});
	};


	fs.prototype.fsync = function(fd, callback) {
		try {
			this.fsyncSync(fd);
		} catch (e) {
			return callback(e);
		}

		return callback(null);
	};


	fs.prototype.fsyncSync = function(fd) {
		if (!this._hasFd(fd)) {
			return Errors.fdNotFound(fd);
		}
	};


	fs.prototype.write = function(fd, buffer, offset, length, position, callback) {
		if (position == null) {
			position = null;
		}

		if (callback == null) {
			callback = null;
		}

		try {
			this.writeSync(fd, buffer, offset, length, position);
		} catch (e) {
	    return callback && callback(e, null, buffer);
		}

	  return callback && callback(null, length, buffer);
	};


	fs.prototype.writeSync = function(fd, buffer, offset, length, position) {
		var data, fdData, item, oldData, oldFlags, path, stats;

		if (position == null) {
			position = null;
		}

		if (!this._hasFd(fd)) {
			Errors.fdNotFound(fd);
		}

		fdData = this._fileDescriptors[fd];
		path = fdData.path;

		if (!isWritable(fdData.flags)) {
			Errors.notWritable(path);
		}

		stats = this.fstatSync(fd);

		if (!stats.isFile()) {
			Errors.notFile(path);
		}

		item = this._data[path];
		data = buffer.toString('utf8', offset).substr(0, length);

		if (position !== null) {
			buffer = new Buffer(stats.size);
			oldFlags = fdData.flags;
			fdData.flags = 'r';
			this.readSync(fd, buffer, 0, stats.size, 0);
			fdData.flags = oldFlags;
			oldData = buffer.toString('utf8');
			data = [oldData.slice(0, position), data, oldData.slice(position)].join('');
		}

		item.data = new Buffer(data);
		item.stats.size = data.length;
		item.stats.blksize = data.length;

		item.stats._modified();
	};


	fs.prototype.read = function(fd, buffer, offset, length, position, callback) {
		if (position == null) {
			position = 0;
		}

		if (callback == null) {
			callback = null;
		}

		try {
			this.readSync(fd, buffer, offset, length, position);
		} catch (e) {
			return callback && callback(e, 0, buffer);
		}

	  return callback && callback(null, length, buffer);
	};


	fs.prototype.readSync = function(fd, buffer, offset, length, position) {
		var data, item, path;

		if (position == null) {
			position = 0;
		}

		if (!this._hasFd(fd)) {
			Errors.fdNotFound(fd);
		}

		item = this._fileDescriptors[fd];
		path = item.path;

		if (!isReadable(item.flags)) {
			Errors.notReadable(path);
		}

		if (!this.fstatSync(fd).isFile()) {
			Errors.notFile(path);
		}

		item = this._data[path];

		data = item.data.toString('utf8');
		data = data.substr(position, length);

		buffer.write(data, offset);

		item.stats._accessed();

		return length;
	};


	fs.prototype.readFile = function(filename, options, callback) {
		if (options == null) {
			options = {};
		}

		if (isFunction(options)) {
			callback = options;
			options = null;
		}

	  var content;

		try {
	    content = this.readFileSync(filename, options);
		} catch (e) {
			return callback(e, null);
		}

		return callback(null, content);
	};


	fs.prototype.readFileSync = function(filename, options) {
		var buffer, data, fd, size;

		if (options == null) {
			options = {};
		}

		if (typeof options.encoding === 'undefined') {
			options.encoding = null;
		}

		if (typeof options.flag === 'undefined') {
			options.flag = 'r';
		}

		fd = this.openSync(filename, options.flag);
		size = this.fstatSync(fd).size;
		buffer = new Buffer(size);

		this.readSync(fd, buffer, 0, size, null);
		this.closeSync(fd);

		data = buffer;

		if (options.encoding !== null) {
			data = buffer.toString(options.encoding);
		}

		return data;
	};



	fs.prototype.writeFile = function(filename, data, options, callback) {
		if (options == null) {
			options = {};
		}

		if (isFunction(options)) {
			callback = options;
			options = null;
		}

		try {
			this.writeFileSync(filename, data, options);
		} catch (e) {
			return callback(e, null);
		}
	  return callback();
	};


	fs.prototype.writeFileSync = function(filename, data, options) {
		var fd;

		if (options == null) {
			options = {};
		}

		if (typeof options.encoding === 'undefined') {
			options.encoding = 'utf8';
		}

		if (typeof options.mode === 'undefined') {
			options.mode = 438;
		}

		if (typeof options.flag === 'undefined') {
			options.flag = 'w';
		}

		filename = this._getSourcePath(filename);
		fd = this.openSync(filename, options.flag, options.mode);

		this.writeSync(fd, new Buffer(data, options.encoding), 0, data.length, null);
		this.closeSync(fd);
		this._expandPath(filename);
	};


	fs.prototype.appendFile = function(filename, data, options, callback) {
		if (options == null) {
			options = {};
		}

		if (isFunction(options)) {
			callback = options;
			options = null;
		}

		try {
			this.appendFileSync(filename, data, options);
		} catch (e) {
			return callback(e, null);
		}

	  return callback();
	};


	fs.prototype.appendFileSync = function(filename, data, options) {
		var fd, size;

		if (options == null) {
			options = {};
		}

		if (typeof options.encoding === 'undefined') {
			options.encoding = 'utf8';
		}

		if (typeof options.mode === 'undefined') {
			options.mode = 438;
		}

		if (typeof options.flag === 'undefined') {
			options.flag = 'w';
		}

		if (typeof data === 'string') {
			data = new Buffer(data, options.encoding);
		}

		fd = this.openSync(filename, options.flag, options.mode);
		size = this.fstatSync(fd).size;

		this.writeSync(fd, data, 0, data.length, size);
		this.closeSync(fd);
	};


	fs.prototype.watchFile = function(filename, options, listener) {
		return Errors.notImplemented('watchFile');
	};


	fs.prototype.unwatchFile = function(filename, listener) {
		return Errors.notImplemented('unwatchFile');
	};


	fs.prototype.watch = function(filename, options, listener) {
		var stats, watcher;

		if (options == null) {
			options = null;
		}

		if (listener == null) {
			listener = null;
		}

		if (isFunction(options)) {
			listener = options;
			options = null;
		}

		if (!this.existsSync(filename)) {
			Errors.notFound(filename);
		}

		watcher = new FSWatcher(listener);
		stats = this.statSync(filename);

		stats.on('modified', function(stats) {
			return watcher.emit('change', 'change', stats._path);
		});

		stats.on('modifiedAttributes', function(stats, event) {
			return watcher.emit('change', event, stats._path);
		});

		return watcher;
	};


	fs.prototype.exists = function(path, callback) {
		return callback(this.existsSync(path));
	};


	fs.prototype.existsSync = function(path) {
		path = this._realpath(path);
		return typeof this._data[path] !== 'undefined';
	};


	fs.prototype.createReadStream = function(path, options) {
		var buffer, data, rs, size;

		if (options == null) {
			options = {};
		}

		if (typeof options.flags === 'undefined') {
			options.flags = 'r';
		}

		if (typeof options.encoding === 'undefined') {
			options.encoding = null;
		}

		if (typeof options.fd === 'undefined') {
			options.fd = null;
		}

		if (typeof options.mode === 'undefined') {
			options.mode = 666;
		}

		if (typeof options.autoClose === 'undefined') {
			options.autoClose = true;
		}

		if (typeof options.start === 'undefined') {
			options.start = null;
		}

		if (typeof options.end === 'undefined') {
			options.end = null;
		}

		rs = new Readable;

		try {
			if (options.fd === null) {
				options.fd = this.openSync(path, options.flags, options.mode);
			}

			process.nextTick(function() {
				rs.emit('open', options.fd);
			});

			size = this.fstatSync(options.fd).size;
			buffer = new Buffer(size);

			this.readSync(options.fd, buffer, 0, size, 0);

			data = buffer.toString(options.encoding);

			if (options.start !== null && options.end !== null) {
				data = data.substring(options.start, options.end);
			}

			rs.push(data);
			rs.push(null);

			if (options.autoClose) {
				this.closeSync(options.fd);
			}
		} catch (e) {
			process.nextTick(function() {
				rs.emit('error', e);
			});
		}

		return rs;
	};


	fs.prototype.createWriteStream = function(path, options) {
		var fd, position, ws, self;

		self = this;

		if (options == null) {
			options = {};
		}

		if (typeof options.flags === 'undefined') {
			options.flags = 'w';
		}

		if (typeof options.encoding === 'undefined') {
			options.encoding = null;
		}

		if (typeof options.mode === 'undefined') {
			options.mode = 666;
		}

		if (typeof options.start === 'undefined') {
			options.start = 0;
		}

		ws = Writable();

		try {
			fd = this.openSync(path, options.flags, options.mode);
			process.nextTick(function() {
				ws.emit('open', fd);
			});
		} catch (e) {
			process.nextTick(function() {
				ws.emit('error', e);
			});
		}

		position = options.start;

		ws._write = function(chunk, enc, next) {
			if (typeof chunk === 'string') {
				chunk = new Buffer(chunk);
			}

			self.write(fd, chunk, 0, chunk.length, position, function(err) {
				position += chunk.length;
				next(err);
			});
		};

		ws.on('finish', function() {
			self.closeSync(fd);
		});

		return ws;
	};


	module.exports = fs;

}).call(this);
