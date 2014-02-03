path = require 'path'

class Helpers


	@splitDeviceRe: /^([a-zA-Z]:|[\\\/]{2}[^\\\/]+[\\\/]+[^\\\/]+)?([\\\/])?([\s\S]*?)$/


	@normalizeArray: (parts, allowAboveRoot) ->
		up = 0
		i = parts.length - 1

		while i >= 0
			last = parts[i]
			if last is "."
				parts.splice i, 1
			else if last is ".."
				parts.splice i, 1
				up++
			else if up
				parts.splice i, 1
				up--
			i--

		if allowAboveRoot
			while up--
				parts.unshift ".."
				up

		return parts


	@normalizeDriveWindows: (drive) ->
		drive = @normalizePathWindows(drive)
		if drive.length == 3 && drive.charAt(2) == '.'
			drive = drive.substr(0, 2)

		return drive


	@normalizeUNCRoot: (device) ->
		return '\\\\' + device.replace(/^[\\\/]+/, '').replace(/[\\\/]+/g, '\\')


	@joinPaths: (isWindows = false, paths...) ->
		if isWindows
			return @joinPathsWindows(paths)
		else
			return @joinPathsPosix(paths)


	@normalizePath: (isWindows = false, path) ->
		if isWindows
			return @normalizePathWindows(path)
		else
			return @normalizePathPosix(path)


	@joinPathsWindows: (paths) ->
		f = (p) ->
			if typeof p != 'string'
				throw new TypeError 'Arguments to path.join must be strings'
			return p

		paths = Array.prototype.filter.call(paths, f)
		joined = paths.join('\\')

		if !/^[\\\/]{2}[^\\\/]/.test(paths[0])
			joined = joined.replace(/^[\\\/]{2,}/, '\\')

		return @normalizePathWindows(joined)


	@joinPathsPosix: (paths) ->
		path = ''
		for segment in paths
			if typeof segment != 'string'
				throw new TypeError 'Arguments to path.join must be strings'

			if segment
				if !path
					path += segment
				else
					path += '/' + segment

		return @normalizePathPosix(path)


	@normalizePathWindows: (path) ->
		result = @splitDeviceRe.exec(path)
		device = result[1] || ''
		isUnc = device && device.charAt(1) != ':'
		isAbsolute = @isAbsoluteWindows(path)
		tail = result[3]
		trailingSlash = /[\\\/]$/.test(tail)

		if device && device.charAt(1) == ':'
			device = device[0].toLowerCase() + device.substr(1)

		tail = @normalizeArray(tail.split(/[\\\/]+/).filter( (p) ->
			return !!p
		), !isAbsolute).join('\\')

		if !tail && !isAbsolute
			tail = '.'

		if tail && trailingSlash
			tail += '\\'

		if isUnc
			device = @normalizeUNCRoot(device)

		return device + (if isAbsolute then '\\' else '') + tail


	@normalizePathPosix: (path) ->
		isAbsolute = @isAbsolutePosix(path)
		trailingSlash = path[path.length - 1] == '/'
		segments = path.split('/')
		nonEmptySegments = []

		i = 0
		while i < segments.length
			nonEmptySegments.push segments[i]  if segments[i]
			i++

		path = @normalizeArray(nonEmptySegments, !isAbsolute).join('/')

		if !path && !isAbsolute
			path = '.'

		if path && trailingSlash
			path += '/'

		return (if isAbsolute then '/' else '') + path


	@isAbsoluteWindows: (path) ->
		result = @splitDeviceRe.exec(path)
		device = result[1] || ''
		isUnc = device && device.charAt(1) != ':'

		return !!result[2] || isUnc


	@isAbsolutePosix: (path) ->
		return path.charAt(0) == '/'


module.exports = Helpers