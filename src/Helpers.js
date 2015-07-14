(function() {

	var splitDeviceRe = /^([a-zA-Z]:|[\\\/]{2}[^\\\/]+[\\\/]+[^\\\/]+)?([\\\/])?([\s\S]*?)$/;

	var Helpers = {};


	Helpers.normalizeArray = function (parts, allowAboveRoot) {
		var i, last, up;

		up = 0;
		i = parts.length - 1;

		while (i >= 0) {
			last = parts[i];
			if (last === ".") {
				parts.splice(i, 1);
			} else if (last === "..") {
				parts.splice(i, 1);
				up++;
			} else if (up) {
				parts.splice(i, 1);
				up--;
			}

			i--;
		}

		if (allowAboveRoot) {
			while (up--) {
				parts.unshift("..");
				up;
			}
		}

		return parts;
	};


	Helpers.normalizeDriveWindows = function (drive) {
		drive = Helpers.normalizePathWindows(drive);
		if (drive.length === 3 && drive.charAt(2) === '.') {
			drive = drive.substr(0, 2);
		}

		return drive;
	};


	Helpers.normalizeUNCRoot = function (device) {
		return '\\\\' + device.replace(/^[\\\/]+/, '').replace(/[\\\/]+/g, '\\');
	};


	Helpers.joinPaths = function () {
		var isWindows, paths;

		isWindows = arguments[0];
		paths = 2 <= arguments.length ? [].slice.call(arguments, 1) : [];

		if (isWindows == null) {
			isWindows = false;
		}

		if (isWindows) {
			return Helpers.joinPathsWindows(paths);
		} else {
			return Helpers.joinPathsPosix(paths);
		}
	};


	Helpers.normalizePath = function (isWindows, path) {
		if (isWindows == null) {
			isWindows = false;
		}

		if (isWindows) {
			return Helpers.normalizePathWindows(path);
		} else {
			return Helpers.normalizePathPosix(path);
		}
	};


	Helpers.joinPathsWindows = function (paths) {
		var f, joined;

		f = function (p) {
			if (typeof p !== 'string') {
				throw new TypeError('Arguments to path.join must be strings');
			}

			return p;
		};

		paths = Array.prototype.filter.call(paths, f);
		joined = paths.join('\\');

		if (!/^[\\\/]{2}[^\\\/]/.test(paths[0])) {
			joined = joined.replace(/^[\\\/]{2,}/, '\\');
		}

		return Helpers.normalizePathWindows(joined);
	};


	Helpers.joinPathsPosix = function (paths) {
		var i, len, segment, path;

		path = '';

		for (i = 0, len = paths.length; i < len; i++) {
			segment = paths[i];

			if (typeof segment !== 'string') {
				throw new TypeError('Arguments to path.join must be strings');
			}

			if (segment) {
				if (!path) {
					path += segment;
				} else {
					path += '/' + segment;
				}
			}
		}

		return Helpers.normalizePathPosix(path);
	};


	Helpers.normalizePathWindows = function (path) {
		var device, isAbsolute, isUnc, result, tail;

		if (/^[a-z]:$/.test(path)) {
			return path;
		}

		result = splitDeviceRe.exec(path);
		device = result[1] || '';
		isUnc = device && device.charAt(1) !== ':';
		isAbsolute = Helpers.isAbsoluteWindows(path);
		tail = result[3];

		if (device && device.charAt(1) === ':') {
			device = device[0].toLowerCase() + device.substr(1);
		}

		tail = Helpers.normalizeArray(tail.split(/[\\\/]+/).filter(function (p) {
			return !!p;
		}), !isAbsolute).join('\\');

		if (!tail && !isAbsolute) {
			tail = '.';
		}

		if (isUnc) {
			device = Helpers.normalizeUNCRoot(device);
		}

		return device + (isAbsolute ? '\\' : '') + tail;
	};


	Helpers.normalizePathPosix = function (path) {
		var i, isAbsolute, nonEmptySegments, segments;

		isAbsolute = Helpers.isAbsolutePosix(path);
		segments = path.split('/');
		nonEmptySegments = [];
		i = 0;

		while (i < segments.length) {
			if (segments[i]) {
				nonEmptySegments.push(segments[i]);
			}

			i++;
		}

		path = Helpers.normalizeArray(nonEmptySegments, !isAbsolute).join('/');

		if (!path && !isAbsolute) {
			path = '.';
		}

		return (isAbsolute ? '/' : '') + path;
	};


	Helpers.isAbsoluteWindows = function (path) {
		var device, isUnc, result;

		result = splitDeviceRe.exec(path);
		device = result[1] || '';
		isUnc = device !== '' && device.charAt(1) !== ':';

		return !!result[2] || isUnc;
	};


	Helpers.isAbsolutePosix = function (path) {
		return path.charAt(0) === '/';
	};


	module.exports = Helpers;

}).call(this);
