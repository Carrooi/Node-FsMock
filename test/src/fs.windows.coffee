FS = require '../../lib/fs'
Stats = require '../../lib/Stats'
expect = require('chai').expect

fs = null

describe 'fs.windows', ->

	beforeEach( ->
		fs = new FS({}, windows: true)
	)


	#*******************************************************************************************************************
	#										SET TREE
	#*******************************************************************************************************************


	describe '#constructor()', ->

		it 'should parse input data', ->
			fs = new FS(
				'xampp': {}
				'xampp\\htdocs\\index.php': ''
				'Users\\david\\documents\\school\\projects': {}
				'Users':
					'david': {}
					'john':
						'passwords.txt': ''
			, windows: true)
			expect(fs._data).to.have.keys([
				'c:', 'c:\\xampp', 'c:\\xampp\\htdocs\\index.php', 'c:\\xampp\\htdocs',
				'c:\\Users\\david\\documents\\school\\projects', 'c:\\Users\\david\\documents\\school',
				'c:\\Users\\david\\documents', 'c:\\Users\\david', 'c:\\Users', 'c:\\Users\\john',
				'c:\\Users\\john\\passwords.txt'
			])
			expect(fs.statSync('c:\\xampp\\htdocs\\index.php').isFile()).to.be.true
			expect(fs.statSync('c:\\xampp\\htdocs').isDirectory()).to.be.true
			expect(fs.statSync('c:\\Users\\john').isDirectory()).to.be.true
			expect(fs.statSync('c:\\Users\\john\\passwords.txt').isFile()).to.be.true


	#*******************************************************************************************************************
	#										OPTIONS
	#*******************************************************************************************************************

	describe 'options', ->

		it 'should create mocked fs with root directory', ->
			fs = new FS({}, {windows: true})
			expect(fs._data).to.have.keys(['c:'])

		it 'should create mocked fs with different root', ->
			fs = new FS(
				'xampp':
					'htdocs':
						'index.php': ''
				'Users\\David\\passwords.txt': ''
			, windows: true, root: 'd:')
			expect(fs._data).to.have.keys([
				'd:', 'd:\\xampp', 'd:\\xampp\\htdocs', 'd:\\xampp\\htdocs\\index.php', 'd:\\Users', 'd:\\Users\\David',
				'd:\\Users\\David\\passwords.txt'
			])

		it 'should create mocked fs with other drives', ->
			fs = new FS(
				'Users\\David\\passwords.txt': ''
			, windows: true, drives: ['d:', 'z:', 'x:'])
			expect(fs._data).to.have.keys([
				'c:', 'c:\\Users', 'c:\\Users\\David', 'c:\\Users\\David\\passwords.txt', 'd:', 'z:', 'x:'
			])

		it 'should create mocked fs with files in different drives', ->
			fs = new FS(
				'c:\\Users\\David\\passwords.txt': {}
				'x:\\xampp\\htdocs\\index.php': ''
			, windows: true, root: false)
			expect(fs._data).to.have.keys([
				'c:', 'c:\\Users', 'c:\\Users\\David', 'c:\\Users\\David\\passwords.txt',
				'x:', 'x:\\xampp', 'x:\\xampp\\htdocs', 'x:\\xampp\\htdocs\\index.php'
			])


	#*******************************************************************************************************************
	#										RENAME
	#*******************************************************************************************************************


	describe '#rename()', ->

		it 'should return an error if path does not exists', (done) ->
			fs.rename('c:\\xampp\\htdocs', 'c:\\xampp\old_htdocs', (err) ->
				expect(err).to.be.an.instanceof(Error)
				expect(err.message).to.be.equal("File or directory 'c:\\xampp\\htdocs' does not exists.")
				done()
			)

		it 'should return an error if path with new name already exists', (done) ->
			fs.mkdirSync('c:\\xampp\\htdocs')
			fs.mkdirSync('c:\\xampp\old_htdocs')
			fs.rename('c:\\xampp\\htdocs', 'c:\\xampp\old_htdocs', (err) ->
				expect(err).to.be.an.instanceof(Error)
				expect(err.message).to.be.equal("File or directory 'c:\\xampp\old_htdocs' already exists.")
				done()
			)

		it 'should rename path', (done) ->
			fs.mkdirSync('c:\\xampp\\htdocs')
			fs.rename('c:\\xampp\\htdocs', 'c:\\xampp\old_htdocs', (err) ->
				expect(err).to.not.exists
				expect(fs.existsSync('c:\\xampp\\htdocs')).to.be.false
				expect(fs._data).to.have.keys(['c:', 'c:\\xampp', 'c:\\xampp\old_htdocs'])
				done()
			)


	#*******************************************************************************************************************
	#										FTRUNCATE
	#*******************************************************************************************************************


	describe '#ftruncate()', ->

		it 'should return an error if file descriptor does not exists', (done) ->
			fs.ftruncate(1, 10, (err) ->
				expect(err).to.be.an.instanceof(Error)
				expect(err.message).to.be.equal("File descriptor 1 not exists.")
				done()
			)

		it 'should return an error if file is not opened for writening', (done) ->
			fs.writeFileSync('c:\\xampp\\htdocs\\index.php', '')
			fd = fs.openSync('c:\\xampp\\htdocs\\index.php', 'r')
			fs.ftruncate(fd, 10, (err) ->
				expect(err).to.be.an.instanceof(Error)
				expect(err.message).to.be.equal("File 'c:\\xampp\\htdocs\\index.php' is not open for writing.")
				done()
			)

		it 'should truncate file data', (done) ->
			fs.writeFileSync('c:\\xampp\\htdocs\\index.php', 'hello word')
			fd = fs.openSync('c:\\xampp\\htdocs\\index.php', 'w+')
			fs.ftruncate(fd, 5, ->
				expect(fs.readFileSync('c:\\xampp\\htdocs\\index.php', encoding: 'utf8')).to.be.equal('hello')
				done()
			)


	#*******************************************************************************************************************
	#										TRUNCATE
	#*******************************************************************************************************************


	describe '#truncate()', ->

		it 'should return an error if path does not exists', (done) ->
			fs.truncate('c:\\xampp\\htdocs\\index.php', 10, (err) ->
				expect(err).to.be.an.instanceof(Error)
				expect(err.message).to.be.equal("File or directory 'c:\\xampp\\htdocs\\index.php' does not exists.")
				done()
			)

		it 'should return an error if path is not file', (done) ->
			fs.mkdirSync('c:\\xampp\\htdocs')
			fs.truncate('c:\\xampp\\htdocs', 10, (err) ->
				expect(err).to.be.an.instanceof(Error)
				expect(err.message).to.be.equal("Path 'c:\\xampp\\htdocs' is not a file.")
				done()
			)

		it 'should leave file data if needed length is larger than data length', (done) ->
			fs.writeFileSync('c:\\xampp\\htdocs\\index.php', 'hello word')
			fs.truncate('c:\\xampp\\htdocs\\index.php', 15, ->
				expect(fs.readFileSync('c:\\xampp\\htdocs\\index.php', encoding: 'utf8')).to.be.equal('hello word')
				done()
			)

		it 'should truncate file data', (done) ->
			fs.writeFileSync('c:\\xampp\\htdocs\\index.php', 'hello word')
			fs.truncate('c:\\xampp\\htdocs\\index.php', 5, ->
				expect(fs.readFileSync('c:\\xampp\\htdocs\\index.php', encoding: 'utf8')).to.be.equal('hello')
				done()
			)


	#*******************************************************************************************************************
	#										CHOWN
	#*******************************************************************************************************************


	describe '#chown()', ->

		it 'should return an error if path does not exists', (done) ->
			fs.chown('c:\\xampp\\htdocs', 200, 200, (err) ->
				expect(err).to.be.an.instanceof(Error)
				expect(err.message).to.be.equal("File or directory 'c:\\xampp\\htdocs' does not exists.")
				done()
			)

		it 'should change uid and gid', (done) ->
			fs.mkdirSync('c:\\xampp\\htdocs')
			fs.chown('c:\\xampp\\htdocs', 300, 200, ->
				stats = fs.statSync('c:\\xampp\\htdocs')
				expect(stats.uid).to.be.equal(300)
				expect(stats.gid).to.be.equal(200)
				done()
			)


	#*******************************************************************************************************************
	#										FCHOWN
	#*******************************************************************************************************************


	describe '#fchown()', ->

		it 'should return an error if descriptor does not exists', (done) ->
			fs.fchown(1, 200, 200, (err) ->
				expect(err).to.be.an.instanceof(Error)
				expect(err.message).to.be.equal("File descriptor 1 not exists.")
				done()
			)

		it 'should change uid and  gid', (done) ->
			fs.mkdirSync('c:\\xampp\\htdocs')
			fs.open('c:\\xampp\\htdocs', 'r', (err, fd) ->
				fs.fchown(fd, 300, 400, ->
					stats = fs.fstatSync(fd)
					expect(stats.uid).to.be.equal(300)
					expect(stats.gid).to.be.equal(400)
					done()
				)
			)


	#*******************************************************************************************************************
	#										LCHOWN
	#*******************************************************************************************************************


	describe '#lchown()', ->

		it 'should return an error if path does not exists', (done) ->
			fs.lchown('c:\\xampp\\htdocs\\index.php', 200, 200, (err) ->
				expect(err).to.be.an.instanceof(Error)
				expect(err.message).to.be.equal("File or directory 'c:\\xampp\\htdocs\\index.php' does not exists.")
				done()
			)

		it 'should return an error if path is not symlink', (done) ->
			fs.writeFileSync('c:\\xampp\\htdocs\\index.php', '')
			fs.lchown('c:\\xampp\\htdocs\\index.php', 200, 200, (err) ->
				expect(err).to.be.an.instanceof(Error)
				expect(err.message).to.be.equal("Path 'c:\\xampp\\htdocs\\index.php' is not a symbolic link.")
				done()
			)

		it 'should change uid and gid of symlink', (done) ->
			fs.writeFileSync('c:\\xampp\\htdocs\\index.php', '')
			fs.symlinkSync('c:\\xampp\\htdocs\\index.php', 'c:\\xampp\\htdocs\\default.php')
			fs.lchown('c:\\xampp\\htdocs\\default.php', 500, 600, ->
				stats = fs.lstatSync('c:\\xampp\\htdocs\\default.php')
				expect(stats.uid).to.be.equal(500)
				expect(stats.gid).to.be.equal(600)
				done()
			)


	#*******************************************************************************************************************
	#										CHMOD
	#*******************************************************************************************************************


	describe '#chmod()', ->

		it 'should return an error if path does not exists', (done) ->
			fs.chmod('c:\\xampp\\htdocs', 777, (err) ->
				expect(err).to.be.an.instanceof(Error)
				expect(err.message).to.be.equal("File or directory 'c:\\xampp\\htdocs' does not exists.")
				done()
			)

		it 'should change mode', (done) ->
			fs.mkdirSync('c:\\xampp\\htdocs')
			fs.chmod('c:\\xampp\\htdocs', 777, ->
				expect(fs.statSync('c:\\xampp\\htdocs').mode).to.be.equal(777)
				done()
			)


	#*******************************************************************************************************************
	#										FCHMOD
	#*******************************************************************************************************************


	describe '#fchmod()', ->

		it 'should return an error if descriptor does not exists', (done) ->
			fs.fchmod(1, 777, (err) ->
				expect(err).to.be.an.instanceof(Error)
				expect(err.message).to.be.equal("File descriptor 1 not exists.")
				done()
			)

		it 'should change mode', (done) ->
			fs.writeFileSync('c:\\xampp\\htdocs\\index.php', '')
			fs.open('c:\\xampp\\htdocs\\index.php', 'r', (err, fd) ->
				fs.fchmod(fd, 777, ->
					expect(fs.fstatSync(fd).mode).to.be.equal(777)
					done()
				)
			)


	#*******************************************************************************************************************
	#										LCHMOD
	#*******************************************************************************************************************


	describe '#lchmod()', ->

		it 'should return an error if path does not exists', (done) ->
			fs.lchmod('c:\\xampp\\htdocs', 777, (err) ->
				expect(err).to.be.an.instanceof(Error)
				expect(err.message).to.be.equal("File or directory 'c:\\xampp\\htdocs' does not exists.")
				done()
			)

		it 'should return an error if path is not symlink', (done) ->
			fs.mkdirSync('c:\\xampp\\htdocs')
			fs.lchmod('c:\\xampp\\htdocs', 777, (err) ->
				expect(err).to.be.an.instanceof(Error)
				expect(err.message).to.be.equal("Path 'c:\\xampp\\htdocs' is not a symbolic link.")
				done()
			)

		it 'should change mode of symlink', (done) ->
			fs.writeFileSync('c:\\xampp\\htdocs\\index.php', '')
			fs.symlinkSync('c:\\xampp\\htdocs\\index.php', 'c:\\xampp\\htdocs\\default.php')
			fs.lchmod('c:\\xampp\\htdocs\\default.php', 777, ->
				expect(fs.lstatSync('c:\\xampp\\htdocs\\default.php').mode).to.be.equal(777)
				done()
			)


	#*******************************************************************************************************************
	#										STAT
	#*******************************************************************************************************************


	describe '#stat()', ->

		it 'should return an error if path does not exists', (done) ->
			fs.stat('c:\\xampp\\htdocs', (err) ->
				expect(err).to.be.an.instanceof(Error)
				expect(err.message).to.be.equal("File or directory 'c:\\xampp\\htdocs' does not exists.")
				done()
			)

		it 'should return stats object for path', (done) ->
			fs.writeFileSync('c:\\xampp\\htdocs\\index.php', '')
			fs.stat('c:\\xampp\\htdocs\\index.php', (err, stats) ->
				expect(stats).to.be.an.instanceof(Stats)
				expect(stats.isFile()).to.be.true
				done()
			)


	#*******************************************************************************************************************
	#										LSTAT
	#*******************************************************************************************************************


	describe '#lstat()', ->

		it 'should return an error if path does not exists', (done) ->
			fs.lstat('c:\\xampp\\htdocs', (err) ->
				expect(err).to.be.an.instanceof(Error)
				expect(err.message).to.be.equal("File or directory 'c:\\xampp\\htdocs' does not exists.")
				done()
			)

		it 'should return an error if path is not a symlink', (done) ->
			fs.mkdirSync('c:\\xampp\\htdocs')
			fs.lstat('c:\\xampp\\htdocs', (err) ->
				expect(err).to.be.an.instanceof(Error)
				expect(err.message).to.be.equal("Path 'c:\\xampp\\htdocs' is not a symbolic link.")
				done()
			)

		it 'should return stats for symlink', (done) ->
			fs.mkdirSync('c:\\xampp\\htdocs')
			fs.symlinkSync('c:\\xampp\\htdocs', 'c:\\xampp\\document_root')
			fs.lstat('c:\\xampp\\document_root', (err, stats) ->
				expect(stats.isSymbolicLink()).to.be.true
				done()
			)


	#*******************************************************************************************************************
	#										FSTAT
	#*******************************************************************************************************************


	describe '#fstat()', ->

		it 'should return an error if descriptor does not exists', (done) ->
			fs.fstat(1, (err) ->
				expect(err).to.be.an.instanceof(Error)
				expect(err.message).to.be.equal("File descriptor 1 not exists.")
				done()
			)

		it 'should return stat object', (done) ->
			fs.writeFileSync('c:\\xampp\\htdocs\\index.php', '')
			fs.open('c:\\xampp\\htdocs\\index.php', 'r', (err, fd) ->
				fs.fstat(fd, (err, stats) ->
					expect(stats).to.be.an.instanceof(Stats)
					expect(stats._path).to.be.equal('c:\\xampp\\htdocs\\index.php')
					done()
				)
			)


	#*******************************************************************************************************************
	#										LINK
	#*******************************************************************************************************************


	describe '#link()', ->

		it 'should return an error if source path does not exists', (done) ->
			fs.link('c:\\xampp\\htdocs\\index.php', 'c:\\xampp\\htdocs\\default.php', (err) ->
				expect(err).to.be.an.instanceof(Error)
				expect(err.message).to.be.equal("File or directory 'c:\\xampp\\htdocs\\index.php' does not exists.")
				done()
			)

		it 'should create link to file', (done) ->
			fs.writeFileSync('c:\\xampp\\htdocs\\index.php', '')
			fs.link('c:\\xampp\\htdocs\\index.php', 'c:\\xampp\\htdocs\\default.php', ->
				expect(fs.existsSync('c:\\xampp\\htdocs\\default.php')).to.be.true
				expect(fs.statSync('c:\\xampp\\htdocs\\default.php').isFile()).to.be.true
				done()
			)


	#*******************************************************************************************************************
	#										SYMLINK
	#*******************************************************************************************************************


	describe '#symlink()', ->

		it 'should return an error if source path does not exists', (done) ->
			fs.symlink('c:\\xampp\\htdocs\\index.php', 'c:\\xampp\\htdocs\\default.php', (err) ->
				expect(err).to.be.an.instanceof(Error)
				expect(err.message).to.be.equal("File or directory 'c:\\xampp\\htdocs\\index.php' does not exists.")
				done()
			)

		it 'should create link to file', (done) ->
			fs.writeFileSync('c:\\xampp\\htdocs\\index.php', '')
			fs.symlink('c:\\xampp\\htdocs\\index.php', 'c:\\xampp\\htdocs\\default.php', ->
				expect(fs.existsSync('c:\\xampp\\htdocs\\default.php')).to.be.true
				done()
			)


	#*******************************************************************************************************************
	#										READLINK
	#*******************************************************************************************************************


	describe '#readlink()', ->

		it 'should return an error if source path does not exists', (done) ->
			fs.readlink('c:\\xampp\\htdocs\\default.php', (err) ->
				expect(err).to.be.an.instanceof(Error)
				expect(err.message).to.be.equal("File or directory 'c:\\xampp\\htdocs\\default.php' does not exists.")
				done()
			)

		it 'should get path of hard link', (done) ->
			fs.writeFileSync('c:\\xampp\\htdocs\\index.php', '')
			fs.link('c:\\xampp\\htdocs\\index.php', 'c:\\xampp\\htdocs\\default.php', ->
				fs.readlink('c:\\xampp\\htdocs\\..\\..\\xampp\\htdocs\\something\\..\\default.php', (err, path) ->
					expect(path).to.be.equal('c:\\xampp\\htdocs\\default.php')
					done()
				)
			)

		it 'should get path to source file of symlink', (done) ->
			fs.writeFileSync('c:\\xampp\\htdocs\\index.php', '')
			fs.symlink('c:\\xampp\\htdocs\\index.php', 'c:\\xampp\\htdocs\\default.php', ->
				fs.readlink('c:\\xampp\\htdocs\\..\\..\\xampp\\htdocs\\something\\..\\default.php', (err, path) ->
					expect(path).to.be.equal('c:\\xampp\\htdocs\\index.php')
					done()
				)
			)

		it 'should get normalized path to file if it is not link', (done) ->
			fs.writeFileSync('c:\\xampp\\htdocs\\index.php', '')
			fs.readlink('c:\\xampp\\htdocs\\..\\..\\xampp\\htdocs\\something\\..\\index.php', (err, path) ->
				expect(path).to.be.equal('c:\\xampp\\htdocs\\index.php')
				done()
			)


	#*******************************************************************************************************************
	#										REALPATH
	#*******************************************************************************************************************


	describe '#realpath()', ->

		it 'should return an error if path does not exists', (done) ->
			fs.realpath('c:\\xampp\\htdocs', (err) ->
				expect(err).to.be.an.instanceof(Error)
				expect(err.message).to.be.equal("File or directory 'c:\\xampp\\htdocs' does not exists.")
				done()
			)

		it 'should load realpath from cache object', (done) ->
			fs.realpath('c:\\xampp\\htdocs', 'c:\\xampp\\htdocs': 'c:\\xampp\\data\\www', (err, resolvedPath) ->
				expect(resolvedPath).to.be.equal('c:\\xampp\\data\\www')
				done()
			)

		it 'should return resolved realpath', (done) ->
			fs.writeFileSync('c:\\xampp\\htdocs\\index.php', '')
			fs.realpath('c:\\xampp\\htdocs\\data\\..\\..\\htdocs\\index.php', (err, resolvedPath) ->
				expect(resolvedPath).to.be.equal('c:\\xampp\\htdocs\\index.php')
				done()
			)


	#*******************************************************************************************************************
	#										UNLINK
	#*******************************************************************************************************************


	describe '#unlink()', ->

		it 'should return an error if path does not exists', (done) ->
			fs.unlink('c:\\xampp\\htdocs\\index.php', (err) ->
				expect(err).to.be.an.instanceof(Error)
				expect(err.message).to.be.equal("File or directory 'c:\\xampp\\htdocs\\index.php' does not exists.")
				done()
			)

		it 'should return an error if path is not file', (done) ->
			fs.mkdirSync('c:\\xampp\\htdocs')
			fs.unlink('c:\\xampp\\htdocs', (err) ->
				expect(err).to.be.an.instanceof(Error)
				expect(err.message).to.be.equal("Path 'c:\\xampp\\htdocs' is not a file.")
				done()
			)

		it 'should remove file', (done) ->
			fs.writeFileSync('c:\\xampp\\htdocs\\index.php', '')
			fs.unlink('c:\\xampp\\htdocs\\index.php', ->
				expect(fs._data).to.have.keys(['c:', 'c:\\xampp\\htdocs', 'c:\\xampp'])
				done()
			)


	#*******************************************************************************************************************
	#										RMDIR
	#*******************************************************************************************************************


	describe '#rmdir()', ->

		it 'should return an error if path does not exists', (done) ->
			fs.rmdir('c:\\xampp\\htdocs', (err) ->
				expect(err).to.be.an.instanceof(Error)
				expect(err.message).to.be.equal("File or directory 'c:\\xampp\\htdocs' does not exists.")
				done()
			)

		it 'should return an error if path is not directory', (done) ->
			fs.writeFileSync('c:\\xampp\\htdocs\\index.php', '')
			fs.rmdir('c:\\xampp\\htdocs\\index.php', (err) ->
				expect(err).to.be.an.instanceof(Error)
				expect(err.message).to.be.equal("Path 'c:\\xampp\\htdocs\\index.php' is not a directory.")
				done()
			)

		it 'should return an error if directory is not empty', (done) ->
			fs.mkdirSync('c:\\xampp\\htdocs')
			fs.writeFileSync('c:\\xampp\\htdocs\\index.php', '')
			fs.rmdir('c:\\xampp\\htdocs', (err) ->
				expect(err).to.be.an.instanceof(Error)
				expect(err.message).to.be.equal("Directory 'c:\\xampp\\htdocs' is not empty.")
				done()
			)

		it 'should remove directory', (done) ->
			fs.mkdirSync('c:\\xampp\\htdocs')
			fs.rmdir('c:\\xampp\\htdocs', ->
				expect(fs._data).to.have.keys(['c:', 'c:\\xampp'])
				done()
			)


	#*******************************************************************************************************************
	#										MKDIR
	#*******************************************************************************************************************


	describe '#mkdir()', ->

		it 'should return an error if path already exists', (done) ->
			fs.mkdirSync('c:\\xampp\\htdocs')
			fs.mkdir('c:\\xampp\\htdocs', (err) ->
				expect(err).to.be.an.instanceof(Error)
				expect(err.message).to.be.equal("File or directory 'c:\\xampp\\htdocs' already exists.")
				done()
			)

		it 'should create new directory', (done) ->
			fs.mkdir('c:\\xampp\\htdocs', ->
				expect(fs._data).to.have.keys(['c:', 'c:\\xampp', 'c:\\xampp\\htdocs'])
				done()
			)


	#*******************************************************************************************************************
	#										READDIR
	#*******************************************************************************************************************


	describe '#readdir()', ->

		it 'should return an error if path does not exists', (done) ->
			fs.readdir('c:\\xampp\\htdocs', (err) ->
				expect(err).to.be.an.instanceof(Error)
				expect(err.message).to.be.equal("File or directory 'c:\\xampp\\htdocs' does not exists.")
				done()
			)

		it 'should throw an error if path is not directory', (done) ->
			fs.writeFileSync('c:\\xampp\\htdocs\\index.php', '')
			fs.readdir('c:\\xampp\\htdocs\\index.php', (err) ->
				expect(err).to.be.an.instanceof(Error)
				expect(err.message).to.be.equal("Path 'c:\\xampp\\htdocs\\index.php' is not a directory.")
				done()
			)

		it 'should load all files and directories from directory', (done) ->
			fs = new FS(
				'xampp\\htdocs':
					'index.php': ''
					'project':
						'school': {}
				'Users\\david': {}
			, windows: true)
			fs.readdir('c:\\xampp\\htdocs', (err, files) ->
				expect(files).to.be.eql([
					'index.php'
					'project'
				])
				expect(fs.statSync('c:\\xampp\\htdocs\\index.php').isFile()).to.be.true
				expect(fs.statSync('c:\\xampp\\htdocs\\project').isDirectory()).to.be.true
				done()
			)


	#*******************************************************************************************************************
	#										CLOSE
	#*******************************************************************************************************************


	describe '#close()', ->

		it 'should return an error if file descriptor does not exists', (done) ->
			fs.close(1, (err) ->
				expect(err).to.be.an.instanceof(Error)
				expect(err.message).to.be.equal("File descriptor 1 not exists.")
				done()
			)

		it 'should close opened file', (done) ->
			fs.writeFileSync('c:\\xampp\\htdocs\\index.php', '')
			fd = fs.openSync('c:\\xampp\\htdocs\\index.php', 'r')
			fs.close(fd, ->
				expect(fs._fileDescriptors).to.be.eql([])
				done()
			)


	#*******************************************************************************************************************
	#										OPEN
	#*******************************************************************************************************************


	describe '#open()', ->

		it 'should return an error if file does not exists (flag: r)', (done) ->
			fs.open('c:\\xampp\\htdocs\\index.php', 'r', (err) ->
				expect(err).to.be.an.instanceof(Error)
				expect(err.message).to.be.equal("File or directory 'c:\\xampp\\htdocs\\index.php' does not exists.")
				done()
			)

		it 'should return an error if file does not exists (flag: r+)', (done) ->
			fs.open('c:\\xampp\\htdocs\\index.php', 'r+', (err) ->
				expect(err).to.be.an.instanceof(Error)
				expect(err.message).to.be.equal("File or directory 'c:\\xampp\\htdocs\\index.php' does not exists.")
				done()
			)

		it 'should return an error if file already exists (flag: wx)', (done) ->
			fs.writeFileSync('c:\\xampp\\htdocs\\index.php', '')
			fs.open('c:\\xampp\\htdocs\\index.php', 'wx', (err) ->
				expect(err).to.be.an.instanceof(Error)
				expect(err.message).to.be.equal("File or directory 'c:\\xampp\\htdocs\\index.php' already exists.")
				done()
			)

		it 'should return an error if file already exists (flag: wx+)', (done) ->
			fs.writeFileSync('c:\\xampp\\htdocs\\index.php', '')
			fs.open('c:\\xampp\\htdocs\\index.php', 'wx+', (err) ->
				expect(err).to.be.an.instanceof(Error)
				expect(err.message).to.be.equal("File or directory 'c:\\xampp\\htdocs\\index.php' already exists.")
				done()
			)

		it 'should return an error if file already exists (flag: ax)', (done) ->
			fs.writeFileSync('c:\\xampp\\htdocs\\index.php', '')
			fs.open('c:\\xampp\\htdocs\\index.php', 'ax', (err) ->
				expect(err).to.be.an.instanceof(Error)
				expect(err.message).to.be.equal("File or directory 'c:\\xampp\\htdocs\\index.php' already exists.")
				done()
			)

		it 'should return an error if file already exists (flag: ax+)', (done) ->
			fs.writeFileSync('c:\\xampp\\htdocs\\index.php', '')
			fs.open('c:\\xampp\\htdocs\\index.php', 'ax+', (err) ->
				expect(err).to.be.an.instanceof(Error)
				expect(err.message).to.be.equal("File or directory 'c:\\xampp\\htdocs\\index.php' already exists.")
				done()
			)

		it 'should create new file if it does not exists (flag: w)', (done) ->
			fs.open('c:\\xampp\\htdocs\\index.php', 'w', (err, fd) ->
				expect(fs.fstatSync(fd).isFile()).to.be.true
				done()
			)

		it 'should create new file if it does not exists (flag: w+)', (done) ->
			fs.open('c:\\xampp\\htdocs\\index.php', 'w+', (err, fd) ->
				expect(fs.fstatSync(fd).isFile()).to.be.true
				done()
			)

		it 'should create new file if it does not exists (flag: a)', (done) ->
			fs.open('c:\\xampp\\htdocs\\index.php', 'a', (err, fd) ->
				expect(fs.fstatSync(fd).isFile()).to.be.true
				done()
			)

		it 'should create new file if it does not exists (flag: a+)', (done) ->
			fs.open('c:\\xampp\\htdocs\\index.php', 'a+', (err, fd) ->
				expect(fs.fstatSync(fd).isFile()).to.be.true
				done()
			)


	#*******************************************************************************************************************
	#										UTIMES
	#*******************************************************************************************************************


	describe '#utimes()', ->

		it 'shoul change atime and mtime', (done) ->
			fs.writeFileSync('c:\\xampp\\htdocs\\index.php', '')
			atime = fs.statSync('c:\\xampp\\htdocs\\index.php').atime
			mtime = fs.statSync('c:\\xampp\\htdocs\\index.php').mtime

			setTimeout( ->
				fs.utimes('c:\\xampp\\htdocs\\index.php', new Date, new Date, ->
					expect(fs.statSync('c:\\xampp\\htdocs\\index.php').atime.getTime()).not.to.be.equal(atime.getTime())
					expect(fs.statSync('c:\\xampp\\htdocs\\index.php').mtime.getTime()).not.to.be.equal(mtime.getTime())
					done()
				)
			, 100)


	#*******************************************************************************************************************
	#										FUTIMES
	#*******************************************************************************************************************


	describe '#futimes()', ->

		it 'should return an error if file descriptor does not exists', (done) ->
			fs.futimes(1, new Date, new Date, (err) ->
				expect(err).to.be.an.instanceof(Error)
				expect(err.message).to.be.equal("File descriptor 1 not exists.")
				done()
			)

		it 'should change atime and mtime', (done) ->
			fs.mkdirSync('c:\\xampp\\htdocs')

			fs.open('c:\\xampp\\htdocs', 'r', (err, fd) ->
				atime = fs.fstatSync(fd).atime
				mtime = fs.fstatSync(fd).mtime

				setTimeout( ->
					fs.futimes(fd, new Date, new Date, ->
						expect(fs.fstatSync(fd).atime.getTime()).not.to.be.equal(atime.getTime())
						expect(fs.fstatSync(fd).mtime.getTime()).not.to.be.equal(mtime.getTime())
						done()
					)
				, 100)
			)


	#*******************************************************************************************************************
	#										FSYNC
	#*******************************************************************************************************************


	describe '#fsync()', ->

		it 'should return an error if file descriptor does not exists', (done) ->
			fs.fsync(1, (err) ->
				expect(err).to.be.an.instanceof(Error)
				expect(err.message).to.be.equal("File descriptor 1 not exists.")
				done()
			)


	#*******************************************************************************************************************
	#										WRITE
	#*******************************************************************************************************************


	describe '#write()', ->

		it 'should return an error if file descriptor does not exists', (done) ->
			fs.write(1, new Buffer(''), 0, 0, 0, (err) ->
				expect(err).to.be.an.instanceof(Error)
				expect(err.message).to.be.equal("File descriptor 1 not exists.")
				done()
			)

		it 'should return an error if file is not open for writing', (done) ->
			fs.writeFileSync('c:\\xampp\\htdocs\\index.php', '')
			fs.open('c:\\xampp\\htdocs\\index.php', 'r', (err, fd) ->
				fs.write(fd, new Buffer(''), 0, 0, 0, (err) ->
					expect(err).to.be.an.instanceof(Error)
					expect(err.message).to.be.equal("File 'c:\\xampp\\htdocs\\index.php' is not open for writing.")
					done()
				)
			)

		it 'should write data to file', (done) ->
			fs.writeFileSync('c:\\xampp\\htdocs\\index.php', 'hello word')
			fs.open('c:\\xampp\\htdocs\\index.php', 'w', (err, fd) ->
				fs.write(fd, new Buffer('hello'), 0, 5, null, ->
					expect(fs.readFileSync('c:\\xampp\\htdocs\\index.php', encoding: 'utf8')).to.be.equal('hello')
					done()
				)
			)

		it 'should write data to exact position in file', (done) ->
			fs.writeFileSync('c:\\xampp\\htdocs\\index.php', 'helloword')
			fs.open('c:\\xampp\\htdocs\\index.php', 'w', (err, fd) ->
				fs.write(fd, new Buffer(' '), 0, 1, 5, ->
					expect(fs.readFileSync('c:\\xampp\\htdocs\\index.php', encoding: 'utf8')).to.be.equal('hello word')
					done()
				)
			)


	#*******************************************************************************************************************
	#										READ
	#*******************************************************************************************************************


	describe '#read()', ->

		it 'should return an error if file descriptor does not exists', (done) ->
			fs.read(1, new Buffer(1), 0, 1, null, (err) ->
				expect(err).to.be.an.instanceof(Error)
				expect(err.message).to.be.equal("File descriptor 1 not exists.")
				done()
			)

		it 'should return an error if file is not open for reading', (done) ->
			fs.writeFileSync('c:\\xampp\\htdocs\\index.php', '')
			fs.open('c:\\xampp\\htdocs\\index.php', 'w', (err, fd) ->
				fs.read(fd, new Buffer(1), 0, 1, null, (err) ->
					expect(err).to.be.an.instanceof(Error)
					expect(err.message).to.be.equal("File 'c:\\xampp\\htdocs\\index.php' is not open for reading.")
					done()
				)
			)

		it 'should read all data', (done) ->
			fs.writeFileSync('c:\\xampp\\htdocs\\index.php', 'hello word')
			fs.open('c:\\xampp\\htdocs\\index.php', 'r', (err, fd) ->
				size = fs.fstatSync(fd).size
				buffer = new Buffer(size)
				fs.read(fd, buffer, 0, size, null, (err, bytesRead, buffer) ->
					expect(bytesRead).to.be.equal(size)
					expect(bytesRead).to.be.equal(10)
					expect(buffer.toString('utf8')).to.be.equal('hello word')
					done()
				)
			)

		it 'should read all data byte by byte', (done) ->
			fs.writeFileSync('c:\\xampp\\htdocs\\index.php', 'hello word')
			fs.open('c:\\xampp\\htdocs\\index.php', 'r', (err, fd) ->
				size = fs.fstatSync(fd).size
				buffer = new Buffer(size)
				bytesRead = 0

				while bytesRead < size
					fs.read(fd, buffer, bytesRead, 1, bytesRead)
					bytesRead++

				expect(buffer.toString('utf8')).to.be.equal('hello word')
				done()
			)


	#*******************************************************************************************************************
	#										READ FILE
	#*******************************************************************************************************************


	describe '#readFile()', ->

		it 'should return an error if path does not exists', (done) ->
			fs.readFile('c:\\xampp\\htdocs\\index.php', (err) ->
				expect(err).to.be.an.instanceof(Error)
				expect(err.message).to.be.equal("File or directory 'c:\\xampp\\htdocs\\index.php' does not exists.")
				done()
			)

		it 'should throw an error if path is not file', (done) ->
			fs.mkdirSync('c:\\xampp\\htdocs')
			fs.readFile('c:\\xampp\\htdocs', (err) ->
				expect(err).to.be.an.instanceof(Error)
				expect(err.message).to.be.equal("Path 'c:\\xampp\\htdocs' is not a file.")
				done()
			)

		it 'should read data from file as buffer', (done) ->
			s = '<?php echo "hello";'
			fs.writeFileSync('c:\\xampp\\htdocs\\index.php', s)
			fs.readFile('c:\\xampp\\htdocs\\index.php', (err, data) ->
				expect(data).to.be.an.instanceof(Buffer)
				expect(data.toString('utf8')).to.be.equal(s)
				done()
			)

		it 'should read data from file as string', (done) ->
			s = '<?php echo "hello";'
			fs.writeFileSync('c:\\xampp\\htdocs\\index.php', s)
			fs.readFile('c:\\xampp\\htdocs\\index.php', encoding: 'utf8', (err, data) ->
				expect(data).to.be.equal(s)
				done()
			)


	#*******************************************************************************************************************
	#										WRITE FILE
	#*******************************************************************************************************************


	describe '#writeFile()', ->

		it 'should create new file', (done) ->
			fs.writeFile('c:\\xampp\\htdocs\\index.php', '', ->
				expect(fs._data).to.have.keys(['c:', 'c:\\xampp\\htdocs\\index.php', 'c:\\xampp\\htdocs', 'c:\\xampp'])
				expect(fs.statSync('c:\\xampp\\htdocs\\index.php').isFile()).to.be.true
				done()
			)

		it 'should rewrite old file', (done) ->
			fs.writeFileSync('c:\\xampp\\htdocs\\index.php', 'old')
			fs.writeFile('c:\\xampp\\htdocs\\index.php', 'new', ->
				expect(fs.readFileSync('c:\\xampp\\htdocs\\index.php', encoding: 'utf8')).to.be.equal('new')
				done()
			)


	#*******************************************************************************************************************
	#										APPEND FILE
	#*******************************************************************************************************************


	describe '#appendFile()', ->

		it 'should return an error if path is not file', (done) ->
			fs.mkdirSync('c:\\xampp\\htdocs')
			fs.appendFile('c:\\xampp\\htdocs', '', (err) ->
				expect(err).to.be.an.instanceof(Error)
				expect(err.message).to.be.equal("Path 'c:\\xampp\\htdocs' is not a file.")
				done()
			)

		it 'should create new file', (done) ->
			fs.appendFile('c:\\xampp\\htdocs\\index.php', 'hello', (err) ->
				expect(fs.readFileSync('c:\\xampp\\htdocs\\index.php', encoding: 'utf8')).to.be.equal('hello')
				done()
			)

		it 'should append data to file with buffer', (done) ->
			fs.writeFileSync('c:\\xampp\\htdocs\\index.php', 'one')
			fs.appendFile('c:\\xampp\\htdocs\\index.php', new Buffer(', two'), ->
				expect(fs.readFileSync('c:\\xampp\\htdocs\\index.php', encoding: 'utf8')).to.be.equal('one, two')
				done()
			)


	#*******************************************************************************************************************
	#										WATCH
	#*******************************************************************************************************************


	describe '#watch()', ->

		it 'should throw an error if path does not exists', ->
			expect( -> fs.watch('c:\\xampp\\htdocs')).to.throw(Error, "File or directory 'c:\\xampp\\htdocs' does not exists.")

		it 'should call listener when attributes were changed', (done) ->
			fs.writeFileSync('c:\\xampp\\htdocs\\index.php', '')
			fs.watch('c:\\xampp\\htdocs\\index.php', (event, filename) ->
				expect(event).to.be.equal('change')
				expect(filename).to.be.equal('c:\\xampp\\htdocs\\index.php')
				done()
			)
			fs.utimesSync('c:\\xampp\\htdocs\\index.php', new Date, new Date)

		it 'should call listener when file was renamed', (done) ->
			fs.writeFileSync('c:\\xampp\\htdocs\\index.php', '')
			fs.watch('c:\\xampp\\htdocs\\index.php', (event, filename) ->
				expect(event).to.be.equal('rename')
				expect(filename).to.be.equal('c:\\xampp\\htdocs\\default.php')
				done()
			)
			fs.renameSync('c:\\xampp\\htdocs\\index.php', 'c:\\xampp\\htdocs\\default.php')

		it 'should call listener when data was changed', (done) ->
			fs.writeFileSync('c:\\xampp\\htdocs\\index.php', '')
			fs.watch('c:\\xampp\\htdocs\\index.php', (event, filename) ->
				expect(event).to.be.equal('change')
				expect(filename).to.be.equal('c:\\xampp\\htdocs\\index.php')
				expect(fs.readFileSync('c:\\xampp\\htdocs\\index.php', encoding: 'utf8')).to.be.equal('hello word')
				done()
			)
			fs.writeFileSync('c:\\xampp\\htdocs\\index.php', 'hello word')

		it 'should close watching', (done) ->
			fs.writeFileSync('c:\\xampp\\htdocs\\index.php', '')
			called = false
			watcher = fs.watch('c:\\xampp\\htdocs\\index.php', (event, filename) ->
				called = true
			)
			watcher.close()
			fs.utimesSync('c:\\xampp\\htdocs\\index.php', new Date, new Date)
			setTimeout( ->
				expect(called).to.be.false
				done()
			, 50)


	#*******************************************************************************************************************
	#										EXISTS
	#*******************************************************************************************************************


	describe '#exists()', ->

		it 'should return false when file does not exists', (done) ->
			fs.exists('c:\\xampp\\htdocs\\index.php', (exists) ->
				expect(exists).to.be.false
				done()
			)

		it 'should return true when file exists', (done) ->
			fs.writeFileSync('c:\\xampp\\htdocs\\index.php', '')
			fs.exists('c:\\xampp\\htdocs\\index.php', (exists) ->
				expect(exists).to.be.true
				done()
			)


	#*******************************************************************************************************************
	#										CREATE READ STREAM
	#*******************************************************************************************************************


	describe '#createReadStream()', ->

		it 'should emit an open event with the file descriptor when it opens a file', (done) ->
			fs.writeFileSync('c:\\xampp\\htdocs\\index.php', '')
			rs = fs.createReadStream('c:\\xampp\\htdocs\\index.php')
			rs.on 'open', (fd) ->
				expect(fd).to.be.a('number')
				done()

		it 'should not emit an open event if file does not exist', (done) ->
			rs = fs.createReadStream('c:\\xampp\\htdocs\\index.php')
			rs.on 'open', (fd) ->
				expect().fail()
			rs.on 'error', (err) ->
				done()

		it 'should emit an error event if file does not exist', (done) ->
			rs = fs.createReadStream('c:\\xampp\\htdocs\\index.php')
			rs.on 'error', (err) ->
				expect(err).to.be.an.instanceof(Error)
				done()

		it 'should create readable stream', (done) ->
			fs.writeFileSync('c:\\xampp\\htdocs\\index.php', 'hello word')
			rs = fs.createReadStream('c:\\xampp\\htdocs\\index.php')
			rs.setEncoding('utf8')

			rs.on 'data', (chunk) ->
				expect(chunk).to.be.equal('hello word')
				done()

		it 'should create readable stream with start and end', (done) ->
			fs.writeFileSync('c:\\xampp\\htdocs\\index.php', 'hello word')
			rs = fs.createReadStream('c:\\xampp\\htdocs\\index.php', start: 6, end: 10)
			rs.setEncoding('utf8')

			rs.on 'data', (chunk) ->
				expect(chunk).to.be.equal('word')
				done()

		it 'should create readable stream with custom fd', (done) ->
			fs.writeFileSync('c:\\xampp\\htdocs\\index.php', 'hello word')
			fd = fs.openSync('c:\\xampp\\htdocs\\index.php', 'r', 666)
			rs = fs.createReadStream('c:\\xampp\\htdocs\\index.php', {fd: fd, autoClose: false})

			rs.setEncoding('utf8')
			rs.on 'data', (chunk) ->
				expect(chunk).to.be.equal('hello word')
				expect(fs._hasFd(fd)).to.be.true

				fs.closeSync(fd)
				done()


	#*******************************************************************************************************************
	#										CREATE WRITE STREAM
	#*******************************************************************************************************************


	describe '#createWriteStream()', ->

		it 'should emit an open event with the file descriptor when it opens a file', (done) ->
			fs.writeFileSync('c:\\xampp\\htdocs\\index.php', '')
			ws = fs.createWriteStream('/var/www/index.php')
			ws.on 'open', (fd) ->
				expect(fd).to.be.a('number')
				done()

		it 'should not emit an open event if creating write stream fails', (done) ->
			fs.writeFileSync('c:\\xampp\\htdocs\\index.php', '')
			ws = fs.createWriteStream('c:\\xampp\\htdocs\\index.php', {flags: 'wx'})
			ws.on 'open', (fd) ->
				expect().fail()
			ws.on 'error', (err) ->
				done()

		it 'should emit an error event if mode is wx and file already exists', (done) ->
			fs.writeFileSync('c:\\xampp\\htdocs\\index.php', '')
			ws = fs.createWriteStream('c:\\xampp\\htdocs\\index.php', {flags: 'wx'})
			ws.on 'error', (err) ->
				expect(err).to.be.an.instanceof(Error)
				done()

		it 'should emit an error event if file is a directory', (done) ->
			fs.mkdirSync('c:\\xampp\\htdocs')
			ws = fs.createWriteStream('c:\\xampp\\htdocs')
			ws.on 'error', (err) ->
				expect(err).to.be.an.instanceof(Error)
				done()
			ws.write('hello')

		it 'should create writable stream', (done) ->
			fs.writeFileSync('c:\\xampp\\htdocs\\index.php', '')
			ws = fs.createWriteStream('c:\\xampp\\htdocs\\index.php')
			ws.on 'finish', ->
				expect(fs.readFileSync('c:\\xampp\\htdocs\\index.php', encoding: 'utf8')).to.be.equal('hello word')
				done()

			ws.write('hello')
			ws.write(' ')
			ws.write('word')
			ws.end()
