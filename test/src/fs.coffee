FS = require '../../lib/fs'
Stats = require '../../lib/Stats'
expect = require('chai').expect

fs = null

describe 'fs', ->

	beforeEach( ->
		fs = new FS
	)

	describe '#_setTree()', ->

		it 'should parse input data', ->
			fs._setTree(
				'/var >>':
					stats:
						atime: new Date
				'/var/www/index.php': {}
				'/home/david/documents/school/projects >>': {}
				'/home >>':
					stats: mtime: new Date
					paths:
						'david >>': {}
						'john >>':
							paths:
								'passwords.txt': {}
			)
			expect(fs._data).to.have.keys([
				'/var', '/var/www/index.php', '/var/www', '/home/david/documents/school/projects', '/home/david/documents/school',
				'/home/david/documents', '/home/david', '/home', '/home/john', '/home/john/passwords.txt'
			])
			expect(fs._data['/var/www/index.php'].stats.isFile()).to.be.true
			expect(fs._data['/var/www'].stats.isDirectory()).to.be.true
			expect(fs._data['/home/john'].stats.isDirectory()).to.be.true
			expect(fs._data['/home/john/passwords.txt'].stats.isFile()).to.be.true

	describe '#rename()', ->

		it 'should return an error if path does not exists', (done) ->
			fs.rename('/var/www', '/var/old_www', (err) ->
				expect(err).to.be.an.instanceof(Error)
				expect(err.message).to.be.equal("File or directory '/var/www' does not exists.")
				done()
			)

		it 'should return an error if path with new name already exists', (done) ->
			fs._setTree('/var/www >>': {}, '/var/old_www >>': {})
			fs.rename('/var/www', '/var/old_www', (err) ->
				expect(err).to.be.an.instanceof(Error)
				expect(err.message).to.be.equal("File or directory '/var/old_www' already exists.")
				done()
			)

		it 'should rename path', (done) ->
			fs._setTree('/var/www >>': {})
			fs.rename('/var/www', '/var/old_www', (err) ->
				expect(err).to.not.exists
				expect(fs._data['/var/www']).not.to.exists
				expect(fs._data).to.have.keys(['/var', '/var/old_www'])
				done()
			)

	describe '#ftruncate()', ->

		it 'should return an error if file descriptor does not exists', (done) ->
			fs.ftruncate(1, 10, (err) ->
				expect(err).to.be.an.instanceof(Error)
				expect(err.message).to.be.equal("File descriptor 1 not exists.")
				done()
			)

		it 'should return an error if file is not opened for writening', (done) ->
			fs._setTree('/var/www/index.php': {})
			fd = fs.openSync('/var/www/index.php', 'r')
			fs.ftruncate(fd, 10, (err) ->
				expect(err).to.be.an.instanceof(Error)
				expect(err.message).to.be.equal("File '/var/www/index.php' is not open for writing.")
				done()
			)

		it 'should truncate file data', (done) ->
			fs._setTree('/var/www/index.php': {data: 'hello word'})
			fd = fs.openSync('/var/www/index.php', 'w+')
			fs.ftruncate(fd, 5, ->
				expect(fs._data['/var/www/index.php'].data.toString('utf8')).to.be.equal('hello')
				done()
			)

	describe '#truncate()', ->

		it 'should return an error if path does not exists', (done) ->
			fs.truncate('/var/www/index.php', 10, (err) ->
				expect(err).to.be.an.instanceof(Error)
				expect(err.message).to.be.equal("File or directory '/var/www/index.php' does not exists.")
				done()
			)

		it 'should return an error if path is not file', (done) ->
			fs._setTree('/var/www >>': {})
			fs.truncate('/var/www', 10, (err) ->
				expect(err).to.be.an.instanceof(Error)
				expect(err.message).to.be.equal("Path '/var/www' is not a file.")
				done()
			)

		it 'should leave file data if needed length is larger than data length', (done) ->
			fs._setTree('/var/www/index.php': {data: 'hello word'})
			fs.truncate('/var/www/index.php', 15, ->
				expect(fs._data['/var/www/index.php'].data.toString('utf8')).to.be.equal('hello word')
				done()
			)

		it 'should truncate file data', (done) ->
			fs._setTree('/var/www/index.php': {data: 'hello word'})
			fs.truncate('/var/www/index.php', 5, ->
				expect(fs._data['/var/www/index.php'].data.toString('utf8')).to.be.equal('hello')
				done()
			)

	describe '#chown()', ->

		it 'should return an error if path does not exists', (done) ->
			fs.chown('/var/www', 200, 200, (err) ->
				expect(err).to.be.an.instanceof(Error)
				expect(err.message).to.be.equal("File or directory '/var/www' does not exists.")
				done()
			)

		it 'should change uid and gid', (done) ->
			fs._setTree('/var/www >>': {})
			fs.chown('/var/www', 300, 200, ->
				expect(fs._data['/var/www'].stats.uid).to.be.equal(300)
				expect(fs._data['/var/www'].stats.gid).to.be.equal(200)
				done()
			)

	describe '#fchown()', ->

		it 'should return an error if descriptor does not exists', (done) ->
			fs.fchown(1, 200, 200, (err) ->
				expect(err).to.be.an.instanceof(Error)
				expect(err.message).to.be.equal("File descriptor 1 not exists.")
				done()
			)

		it 'should change uid and  gid', (done) ->
			fs._setTree('/var/www >>': {})
			fs.open('/var/www', 'r', (err, fd) ->
				fs.fchown(fd, 300, 400, ->
					expect(fs._data['/var/www'].stats.uid).to.be.equal(300)
					expect(fs._data['/var/www'].stats.gid).to.be.equal(400)
					done()
				)
			)

	describe '#chmod()', ->

		it 'should return an error if path does not exists', (done) ->
			fs.chmod('/var/www', 777, (err) ->
				expect(err).to.be.an.instanceof(Error)
				expect(err.message).to.be.equal("File or directory '/var/www' does not exists.")
				done()
			)

		it 'should change mode', (done) ->
			fs._setTree('/var/www >>': {})
			fs.chmod('/var/www', 777, ->
				expect(fs._data['/var/www'].stats.mode).to.be.equal(777)
				done()
			)

	describe '#fchmod()', ->

		it 'should return an error if descriptor does not exists', (done) ->
			fs.fchmod(1, 777, (err) ->
				expect(err).to.be.an.instanceof(Error)
				expect(err.message).to.be.equal("File descriptor 1 not exists.")
				done()
			)

		it 'should change mode', (done) ->
			fs._setTree('/var/www/index.php': {})
			fs.open('/var/www/index.php', 'r', (err, fd) ->
				fs.fchmod(1, 777, ->
					expect(fs._data['/var/www/index.php'].stats.mode).to.be.equal(777)
					done()
				)
			)


	describe '#stat()', ->

		it 'should return an error if path does not exists', (done) ->
			fs.stat('/var/www', (err) ->
				expect(err).to.be.an.instanceof(Error)
				expect(err.message).to.be.equal("File or directory '/var/www' does not exists.")
				done()
			)

		it 'should return stats object for path', (done) ->
			fs._setTree('/var/www/index.php': {})
			fs.stat('/var/www/index.php', (err, stats) ->
				expect(stats).to.be.an.instanceof(Stats)
				expect(stats.isFile()).to.be.true
				done()
			)

	describe '#fstat()', ->

		it 'should return an error if descriptor does not exists', (done) ->
			fs.fstat(1, (err) ->
				expect(err).to.be.an.instanceof(Error)
				expect(err.message).to.be.equal("File descriptor 1 not exists.")
				done()
			)

		it 'should return stat object', (done) ->
			fs._setTree('/var/www/index.php': {})
			fs.open('/var/www/index.php', 'r', (err, fd) ->
				fs.fstat(fd, (err, stats) ->
					expect(stats).to.be.an.instanceof(Stats)
					expect(stats._path).to.be.equal('/var/www/index.php')
					done()
				)
			)

	describe '#realpath()', ->

		it 'should return an error if path does not exists', (done) ->
			fs.realpath('/var/www', (err) ->
				expect(err).to.be.an.instanceof(Error)
				expect(err.message).to.be.equal("File or directory '/var/www' does not exists.")
				done()
			)

		it 'should load realpath from cache object', (done) ->
			fs.realpath('/var/www', '/var/www': '/var/data/www', (err, resolvedPath) ->
				expect(resolvedPath).to.be.equal('/var/data/www')
				done()
			)

		it 'should return resolved realpath', (done) ->
			fs._setTree('/var/www/index.php': {})
			fs.realpath('/var/www/data/../../www/index.php', (err, resolvedPath) ->
				expect(resolvedPath).to.be.equal('/var/www/index.php')
				done()
			)

	describe '#unlink()', ->

		it 'should return an error if path does not exists', (done) ->
			fs.unlink('/var/www/index.php', (err) ->
				expect(err).to.be.an.instanceof(Error)
				expect(err.message).to.be.equal("File or directory '/var/www/index.php' does not exists.")
				done()
			)

		it 'should return an error if path is not file', (done) ->
			fs._setTree('/var/www >>': {})
			fs.unlink('/var/www', (err) ->
				expect(err).to.be.an.instanceof(Error)
				expect(err.message).to.be.equal("Path '/var/www' is not a file.")
				done()
			)

		it 'should remove file', (done) ->
			fs._setTree('/var/www/index.php': {})
			fs.unlink('/var/www/index.php', ->
				expect(fs._data).to.have.keys([
					'/var/www',
					'/var'
				])
				done()
			)

	describe '#rmdir()', ->

		it 'should return an error if path does not exists', (done) ->
			fs.rmdir('/var/www', (err) ->
				expect(err).to.be.an.instanceof(Error)
				expect(err.message).to.be.equal("File or directory '/var/www' does not exists.")
				done()
			)

		it 'should return an error if path is not directory', (done) ->
			fs._setTree('/var/www/index.php': {})
			fs.rmdir('/var/www/index.php', (err) ->
				expect(err).to.be.an.instanceof(Error)
				expect(err.message).to.be.equal("Path '/var/www/index.php' is not a directory.")
				done()
			)

		it 'should return an error if directory is not empty', (done) ->
			fs._setTree('/var/www >>': {}, '/var/www/index.php': {})
			fs.rmdir('/var/www', (err) ->
				expect(err).to.be.an.instanceof(Error)
				expect(err.message).to.be.equal("Directory '/var/www' is not empty.")
				done()
			)

		it 'should remove directory', (done) ->
			fs._setTree('/var/www >>': {})
			fs.rmdir('/var/www', ->
				expect(fs._data).to.have.keys(['/var'])
				done()
			)

	describe '#mkdir()', ->

		it 'should return an error if path already exists', (done) ->
			fs._setTree('/var/www': {})
			fs.mkdir('/var/www', (err) ->
				expect(err).to.be.an.instanceof(Error)
				expect(err.message).to.be.equal("File or directory '/var/www' already exists.")
				done()
			)

		it 'should create new directory', (done) ->
			fs.mkdir('/var/www', ->
				expect(fs._data).to.have.keys(['/var', '/var/www'])
				done()
			)

	describe '#readdir()', ->

		it 'should return an error if path does not exists', (done) ->
			fs.readdir('/var/www', (err) ->
				expect(err).to.be.an.instanceof(Error)
				expect(err.message).to.be.equal("File or directory '/var/www' does not exists.")
				done()
			)

		it 'should throw an error if path is not directory', (done) ->
			fs._setTree('/var/www/index.php': {})
			fs.readdir('/var/www/index.php', (err) ->
				expect(err).to.be.an.instanceof(Error)
				expect(err.message).to.be.equal("Path '/var/www/index.php' is not a directory.")
				done()
			)

		it 'should load all files and directories from directory', (done) ->
			fs._setTree(
				'/var/www >>':
					paths:
						'index.php': {}
						'project >>':
							paths:
								'school >>': {}
				'/home/david >>': {}
			)
			fs.readdir('/var/www', (err, files) ->
				expect(files).to.be.eql([
					'/var/www/index.php'
					'/var/www/project'
				])
				expect(fs._data['/var/www/index.php'].stats.isFile()).to.be.true
				expect(fs._data['/var/www/project'].stats.isDirectory()).to.be.true
				done()
			)

	describe '#close()', ->

		it 'should return an error if file descriptor does not exists', (done) ->
			fs.close(1, (err) ->
				expect(err).to.be.an.instanceof(Error)
				expect(err.message).to.be.equal("File descriptor 1 not exists.")
				done()
			)

		it 'should close opened file', (done) ->
			fs._setTree('/var/www/index.php': {})
			fd = fs.openSync('/var/www/index.php', 'r')
			fs.close(fd, ->
				expect(fs._fileDescriptors).to.be.eql([])
				done()
			)

	describe '#open()', ->

		it 'should return an error if file does not exists (flag: r)', (done) ->
			fs.open('/var/www/index.php', 'r', (err) ->
				expect(err).to.be.an.instanceof(Error)
				expect(err.message).to.be.equal("File or directory '/var/www/index.php' does not exists.")
				done()
			)

		it 'should return an error if file does not exists (flag: r+)', (done) ->
			fs.open('/var/www/index.php', 'r+', (err) ->
				expect(err).to.be.an.instanceof(Error)
				expect(err.message).to.be.equal("File or directory '/var/www/index.php' does not exists.")
				done()
			)

		it 'should return an error if file already exists (flag: wx)', (done) ->
			fs._setTree('/var/www/index.php': {})
			fs.open('/var/www/index.php', 'wx', (err) ->
				expect(err).to.be.an.instanceof(Error)
				expect(err.message).to.be.equal("File or directory '/var/www/index.php' already exists.")
				done()
			)

		it 'should return an error if file already exists (flag: wx+)', (done) ->
			fs._setTree('/var/www/index.php': {})
			fs.open('/var/www/index.php', 'wx+', (err) ->
				expect(err).to.be.an.instanceof(Error)
				expect(err.message).to.be.equal("File or directory '/var/www/index.php' already exists.")
				done()
			)

		it 'should return an error if file already exists (flag: ax)', (done) ->
			fs._setTree('/var/www/index.php': {})
			fs.open('/var/www/index.php', 'ax', (err) ->
				expect(err).to.be.an.instanceof(Error)
				expect(err.message).to.be.equal("File or directory '/var/www/index.php' already exists.")
				done()
			)

		it 'should return an error if file already exists (flag: ax+)', (done) ->
			fs._setTree('/var/www/index.php': {})
			fs.open('/var/www/index.php', 'ax+', (err) ->
				expect(err).to.be.an.instanceof(Error)
				expect(err.message).to.be.equal("File or directory '/var/www/index.php' already exists.")
				done()
			)

		it 'should create new file if it does not exists (flag: w)', (done) ->
			fs.open('/var/www/index.php', 'w', ->
				expect(fs.statSync('/var/www/index.php').isFile())
				done()
			)

		it 'should create new file if it does not exists (flag: w+)', (done) ->
			fs.open('/var/www/index.php', 'w+', ->
				expect(fs.statSync('/var/www/index.php').isFile())
				done()
			)

		it 'should create new file if it does not exists (flag: a)', (done) ->
			fs.open('/var/www/index.php', 'a', ->
				expect(fs.statSync('/var/www/index.php').isFile())
				done()
			)

		it 'should create new file if it does not exists (flag: a+)', (done) ->
			fs.open('/var/www/index.php', 'a+', ->
				expect(fs.statSync('/var/www/index.php').isFile())
				done()
			)

	describe '#utimes()', ->

		it 'shoul change atime and mtime', (done) ->
			fs._setTree('/var/www/index.php': {})
			atime = fs.statSync('/var/www/index.php').atime
			mtime = fs.statSync('/var/www/index.php').mtime

			setTimeout( ->
				fs.utimes('/var/www/index.php', new Date, new Date, ->
					expect(fs.statSync('/var/www/index.php').atime.getTime()).not.to.be.equal(atime.getTime())
					expect(fs.statSync('/var/www/index.php').mtime.getTime()).not.to.be.equal(mtime.getTime())
					done()
				)
			, 100)


	describe '#futimes()', ->

		it 'should return an error if file descriptor does not exists', (done) ->
			fs.futimes(1, new Date, new Date, (err) ->
				expect(err).to.be.an.instanceof(Error)
				expect(err.message).to.be.equal("File descriptor 1 not exists.")
				done()
			)

		it 'should change atime and mtime', (done) ->
			fs._setTree('/var/www >>': {})
			atime = fs.statSync('/var/www').atime
			mtime = fs.statSync('/var/www').mtime

			fs.open('/var/www', 'r', (err, fd) ->
				setTimeout( ->
					fs.futimes(fd, new Date, new Date, ->
						expect(fs.statSync('/var/www').atime.getTime()).not.to.be.equal(atime.getTime())
						expect(fs.statSync('/var/www').mtime.getTime()).not.to.be.equal(mtime.getTime())
						done()
					)
				, 100)
			)

	describe '#write()', ->

		it 'should return an error if file descriptor does not exists', (done) ->
			fs.write(1, new Buffer(''), 0, 0, 0, (err) ->
				expect(err).to.be.an.instanceof(Error)
				expect(err.message).to.be.equal("File descriptor 1 not exists.")
				done()
			)

		it 'should return an error if file is not open for writing', (done) ->
			fs._setTree('/var/www/index.php': {})
			fs.open('/var/www/index.php', 'r', (err, fd) ->
				fs.write(fd, new Buffer(''), 0, 0, 0, (err) ->
					expect(err).to.be.an.instanceof(Error)
					expect(err.message).to.be.equal("File '/var/www/index.php' is not open for writing.")
					done()
				)
			)

		it 'should write data to file', (done) ->
			fs._setTree('/var/www/index.php': {data: 'hello word'})
			fs.open('/var/www/index.php', 'w', (err, fd) ->
				fs.write(fd, new Buffer('hello'), 0, 5, 0, ->
					expect(fs._data['/var/www/index.php'].data.toString('utf8')).to.be.equal('hello')
					done()
				)
			)

		it 'should write data to exact position in file', (done) ->
			fs._setTree('/var/www/index.php': {data: 'helloword'})
			fs.open('/var/www/index.php', 'w', (err, fd) ->
				fs.write(fd, new Buffer(' '), 0, 1, 5, ->
					expect(fs.readFileSync('/var/www/index.php', encoding: 'utf8')).to.be.equal('hello word')
					done()
				)
			)

	describe '#read()', ->

		it 'should return an error if file descriptor does not exists', (done) ->
			fs.read(1, new Buffer(1), 0, 1, null, (err) ->
				expect(err).to.be.an.instanceof(Error)
				expect(err.message).to.be.equal("File descriptor 1 not exists.")
				done()
			)

		it 'should return an error if file is not open for reading', (done) ->
			fs._setTree('/var/www/index.php': {})
			fs.open('/var/www/index.php', 'w', (err, fd) ->
				fs.read(fd, new Buffer(1), 0, 1, null, (err) ->
					expect(err).to.be.an.instanceof(Error)
					expect(err.message).to.be.equal("File '/var/www/index.php' is not open for reading.")
					done()
				)
			)

		it 'should read all data', (done) ->
			fs._setTree('/var/www/index.php': {data: 'hello word'})
			fs.open('/var/www/index.php', 'r', (err, fd) ->
				size = fs.statSync('/var/www/index.php').size
				buffer = new Buffer(size)
				fs.read(fd, buffer, 0, size, null, (err, bytesRead, buffer) ->
					expect(bytesRead).to.be.equal(size)
					expect(bytesRead).to.be.equal(10)
					expect(buffer.toString('utf8')).to.be.equal('hello word')
					done()
				)
			)

		it 'should read all data byte by byte', (done) ->
			fs._setTree('/var/www/index.php': {data: 'hello word'})
			fs.open('/var/www/index.php', 'r', (err, fd) ->
				size = fs.statSync('/var/www/index.php').size
				buffer = new Buffer(size)
				bytesRead = 0

				while bytesRead < size
					fs.read(fd, buffer, bytesRead, 1, bytesRead)
					bytesRead++

				expect(buffer.toString('utf8')).to.be.equal('hello word')
				done()
			)

	describe '#readFile()', ->

		it 'should return an error if path does not exists', (done) ->
			fs.readFile('/var/www/index.php', (err) ->
				expect(err).to.be.an.instanceof(Error)
				expect(err.message).to.be.equal("File or directory '/var/www/index.php' does not exists.")
				done()
			)

		it 'should throw an error if path is not file', (done) ->
			fs._setTree('/var/www >>': {})
			fs.readFile('/var/www', (err) ->
				expect(err).to.be.an.instanceof(Error)
				expect(err.message).to.be.equal("Path '/var/www' is not a file.")
				done()
			)

		it 'should read data from file as buffer', (done) ->
			s = '<?php echo "hello";'
			fs._setTree('/var/www/index.php': {data: s})
			fs.readFile('/var/www/index.php', (err, data) ->
				expect(data).to.be.an.instanceof(Buffer)
				expect(data.toString('utf8')).to.be.equal(s)
				done()
			)

		it 'should read data from file as string', (done) ->
			s = '<?php echo "hello";'
			fs._setTree('/var/www/index.php': {data: s})
			fs.readFile('/var/www/index.php', encoding: 'utf8', (err, data) ->
				expect(data).to.be.equal(s)
				done()
			)

	describe '#writeFile()', ->

		it 'should create new file', (done) ->
			fs.writeFile('/var/www/index.php', '', ->
				expect(fs._data).to.have.keys(['/var/www/index.php', '/var/www', '/var'])
				expect(fs._data['/var/www/index.php'].stats.isFile()).to.be.true
				done()
			)

		it 'should rewrite old file', (done) ->
			fs._setTree('/var/www/index.php': {data: 'old'})
			fs.writeFile('/var/www/index.php', 'new', ->
				expect(fs._data['/var/www/index.php'].data.toString('utf8')).to.be.equal('new')
				done()
			)

	describe '#appendFile()', ->

		it 'should return an error if path is not file', (done) ->
			fs._setTree('/var/www >>': {})
			fs.appendFile('/var/www', '', (err) ->
				expect(err).to.be.an.instanceof(Error)
				expect(err.message).to.be.equal("Path '/var/www' is not a file.")
				done()
			)

		it 'should create new file', (done) ->
			fs.appendFile('/var/www/index.php', 'hello', ->
				expect(fs._data['/var/www/index.php'].data.toString('utf8')).to.be.equal('hello')
				done()
			)

		it 'should append data to file with buffer', (done) ->
			fs._setTree('/var/www/index.php': {data: 'one'})
			fs.appendFile('/var/www/index.php', new Buffer(', two'), ->
				expect(fs._data['/var/www/index.php'].data.toString('utf8')).to.be.equal('one, two')
				done()
			)

	describe '#watch()', ->

		it 'should throw an error if path does not exists', ->
			expect( -> fs.watch('/var/www')).to.throw(Error, "File or directory '/var/www' does not exists.")

		it 'should call listener when attributes were changed', (done) ->
			fs._setTree('/var/www/index.php': {})
			fs.watch('/var/www/index.php', (event, filename) ->
				expect(event).to.be.equal('change')
				expect(filename).to.be.equal('/var/www/index.php')
				done()
			)
			fs.utimesSync('/var/www/index.php', new Date, new Date)

		it 'should call listener when file was renamed', (done) ->
			fs._setTree('/var/www/index.php': {})
			fs.watch('/var/www/index.php', (event, filename) ->
				expect(event).to.be.equal('rename')
				expect(filename).to.be.equal('/var/www/default.php')
				done()
			)
			fs.renameSync('/var/www/index.php', '/var/www/default.php')

		it 'should call listener when data was changed', (done) ->
			fs._setTree('/var/www/index.php': {})
			fs.watch('/var/www/index.php', (event, filename) ->
				expect(event).to.be.equal('change')
				expect(filename).to.be.equal('/var/www/index.php')
				expect(fs.readFileSync('/var/www/index.php', encoding: 'utf8')).to.be.equal('hello word')
				done()
			)
			fs.writeFileSync('/var/www/index.php', 'hello word')

		it 'should close watching', (done) ->
			fs._setTree('/var/www/index.php': {})
			called = false
			watcher = fs.watch('/var/www/index.php', (event, filename) ->
				called = true
			)
			watcher.close()
			fs.utimesSync('/var/www/index.php', new Date, new Date)
			setTimeout( ->
				expect(called).to.be.false
				done()
			, 50)


	describe '#exists()', ->

		it 'should return false when file does not exists', (done) ->
			fs.exists('/var/www/index.php', (exists) ->
				expect(exists).to.be.false
				done()
			)

		it 'should return true when file exists', (done) ->
			fs._setTree('/var/www/index.php': {})
			fs.exists('/var/www/index.php', (exists) ->
				expect(exists).to.be.true
				done()
			)

	describe '#createReadStream()', ->

		it 'should return an error if file does not exists', ->
			expect( -> fs.createReadStream('/var/www/index.php') ).to.throw(Error, "File or directory '/var/www/index.php' does not exists.")

		it 'should create readable stream', (done) ->
			fs._setTree('/var/www/index.php': {data: 'hello word'})
			rs = fs.createReadStream('/var/www/index.php').on 'readable', ->
				buf = rs.read()
				if buf != null
					expect(buf.toString('utf8')).to.be.equal('hello word')
				else
					done()

		it 'should create readable stream with start and end', (done) ->
			fs._setTree('/var/www/index.php': {data: 'hello word'})
			rs = fs.createReadStream('/var/www/index.php', start: 6, end: 10).on 'readable', ->
				buf = rs.read()
				if buf != null
					expect(buf.toString('utf8')).to.be.equal('word')
				else
					done()

	describe '#createWriteStream()', ->

		it 'should return an error if file does not exists', ->
			expect( -> fs.createReadStream('/var/www/index.php') ).to.throw(Error, "File or directory '/var/www/index.php' does not exists.")

		it 'should create writable stream', (done) ->
			fs._setTree('/var/www/index.php': {data: ''})
			ws = fs.createWriteStream('/var/www/index.php')
			ws.on 'finish', ->
				expect(fs.readFileSync('/var/www/index.php', encoding: 'utf8')).to.be.equal('hello word')
				done()

			ws.write('hello')
			ws.write(' ')
			ws.write('word')
			ws.end()