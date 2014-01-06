class Errors


	@notImplemented: (method) ->
		throw new Error "Method '#{method}' is not implemented."


	@notFound: (path) ->
		throw new Error "File or directory '#{path}' does not exists."


	@alreadyExists: (path) ->
		throw new Error "File or directory '#{path}' already exists."


	@directoryExists: (path) ->
		throw new Error "Directory '#{path}' already exists."


	@notFile: (path) ->
		throw new Error "Path '#{path}' is not a file."


	@notDirectory: (path) ->
		throw new Error "Path '#{path}' is not a directory."


	@directoryNotEmpty: (path) ->
		throw new Error "Directory '#{path}' is not empty."


	@fdNotFound: (fd) ->
		throw new Error "File descriptor #{fd} not exists."


	@notWritable: (path) ->
		throw new Error "File '#{path}' is not open for writing."


	@notReadable: (path) ->
		throw new Error "File '#{path}' is not open for reading."


module.exports = Errors