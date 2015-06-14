(function() {

	var FS = require('../lib/fs');
	var Stats = require('../lib/Stats');

	var expect = require('chai').expect;


	var fs = null;


	describe('fs.posix', function () {


		beforeEach(function () {
			fs = new FS;
		});


		describe('#constructor()', function () {

			it('should parse input data', function () {
				fs = new FS({
					'var': {},
					'var/www/index.php': '',
					'home/david/documents/school/projects': {},
					'home': {
						'david': {},
						'john': {
							'passwords.txt': ''
						}
					}
				});

				expect(fs._data).to.have.keys([
					'/', '/var', '/var/www/index.php', '/var/www', '/home/david/documents/school/projects', '/home/david/documents/school',
					'/home/david/documents', '/home/david', '/home', '/home/john', '/home/john/passwords.txt'
				]);

				expect(fs.statSync('/var/www/index.php').isFile()).to.be.true;
				expect(fs.statSync('/var/www').isDirectory()).to.be.true;
				expect(fs.statSync('/home/john').isDirectory()).to.be.true;
				expect(fs.statSync('/home/john/passwords.txt').isFile()).to.be.true;
			});

		});


		describe('#options', function () {

			it('should create mocked fs with root directory', function () {
				expect(fs._data).to.have.keys(['/']);
			});

			it('should throw an error when setting drives', function () {
				expect(function () {
					new FS({}, {drives: ['d:', 'z:']});
				}).to.throw(Error, 'Options drive can be used only with windows options.');
			});

		});


		describe('#rename()', function () {

			it('should return an error if path does not exists', function (done) {
				fs.rename('/var/www', '/var/old_www', function (err) {
					expect(err).to.be.an.instanceof(Error);
					expect(err.message).to.be.equal("File or directory '/var/www' does not exists.");
					done();
				});
			});

			it('should return an error if path with new name already exists', function (done) {
				fs.mkdirSync('/var/www');
				fs.mkdirSync('/var/old_www');
				fs.rename('/var/www', '/var/old_www', function (err) {
					expect(err).to.be.an.instanceof(Error);
					expect(err.message).to.be.equal("File or directory '/var/old_www' already exists.");
					done();
				});
			});

			it('should rename path', function (done) {
				fs.mkdirSync('/var/www');
				fs.rename('/var/www', '/var/old_www', function (err) {
					expect(err).to.not.exists;
					expect(fs.existsSync('/var/www')).to.be.false;
					expect(fs._data).to.have.keys(['/', '/var', '/var/old_www']);
					done();
				});
			});

		});


		describe('#ftruncate()', function () {

			it('should return an error if file descriptor does not exists', function (done) {
				fs.ftruncate(1, 10, function (err) {
					expect(err).to.be.an.instanceof(Error);
					expect(err.message).to.be.equal("File descriptor 1 not exists.");
					done();
				});
			});

			it('should return an error if file is not opened for writening', function (done) {
				var fd;

				fs.writeFileSync('/var/www/index.php', '');
				fd = fs.openSync('/var/www/index.php', 'r');
				fs.ftruncate(fd, 10, function (err) {
					expect(err).to.be.an.instanceof(Error);
					expect(err.message).to.be.equal("File '/var/www/index.php' is not open for writing.");
					done();
				});
			});

			it('should truncate file data', function (done) {
				var fd;

				fs.writeFileSync('/var/www/index.php', 'hello word');
				fd = fs.openSync('/var/www/index.php', 'w+');
				fs.ftruncate(fd, 5, function () {
					expect(fs.readFileSync('/var/www/index.php', {
						encoding: 'utf8'
					})).to.be.equal('hello');

					done();
				});
			});

		});


		describe('#truncate()', function () {

			it('should return an error if path does not exists', function (done) {
				fs.truncate('/var/www/index.php', 10, function (err) {
					expect(err).to.be.an.instanceof(Error);
					expect(err.message).to.be.equal("File or directory '/var/www/index.php' does not exists.");
					done();
				});
			});

			it('should return an error if path is not file', function (done) {
				fs.mkdirSync('/var/www');
				fs.truncate('/var/www', 10, function (err) {
					expect(err).to.be.an.instanceof(Error);
					expect(err.message).to.be.equal("Path '/var/www' is not a file.");
					done();
				});
			});

			it('should leave file data if needed length is larger than data length', function (done) {
				fs.writeFileSync('/var/www/index.php', 'hello word');
				fs.truncate('/var/www/index.php', 15, function () {
					expect(fs.readFileSync('/var/www/index.php', {
						encoding: 'utf8'
					})).to.be.equal('hello word');

					done();
				});
			});

			it('should truncate file data', function (done) {
				fs.writeFileSync('/var/www/index.php', 'hello word');
				fs.truncate('/var/www/index.php', 5, function () {
					expect(fs.readFileSync('/var/www/index.php', {
						encoding: 'utf8'
					})).to.be.equal('hello');

					done();
				});
			});

		});


		describe('#chown()', function () {

			it('should return an error if path does not exists', function (done) {
				fs.chown('/var/www', 200, 200, function (err) {
					expect(err).to.be.an.instanceof(Error);
					expect(err.message).to.be.equal("File or directory '/var/www' does not exists.");
					done();
				});
			});

			it('should change uid and gid', function (done) {
				fs.mkdirSync('/var/www');
				fs.chown('/var/www', 300, 200, function () {
					var stats;

					stats = fs.statSync('/var/www');
					expect(stats.uid).to.be.equal(300);
					expect(stats.gid).to.be.equal(200);
					done();
				});
			});

		});


		describe('#fchown()', function () {

			it('should return an error if descriptor does not exists', function (done) {
				fs.fchown(1, 200, 200, function (err) {
					expect(err).to.be.an.instanceof(Error);
					expect(err.message).to.be.equal("File descriptor 1 not exists.");
					done();
				});
			});

			it('should change uid and  gid', function (done) {
				fs.mkdirSync('/var/www');
				fs.open('/var/www', 'r', function (err, fd) {
					fs.fchown(fd, 300, 400, function () {
						var stats;

						stats = fs.fstatSync(fd);
						expect(stats.uid).to.be.equal(300);
						expect(stats.gid).to.be.equal(400);
						done()
					});
				});
			});

		});


		describe('#lchown()', function () {

			it('should return an error if path does not exists', function (done) {
				fs.lchown('/var/www/index.php', 200, 200, function (err) {
					expect(err).to.be.an.instanceof(Error);
					expect(err.message).to.be.equal("File or directory '/var/www/index.php' does not exists.");
					done();
				});
			});

			it('should return an error if path is not symlink', function (done) {
				fs.writeFileSync('/var/www/index.php', '');
				fs.lchown('/var/www/index.php', 200, 200, function (err) {
					expect(err).to.be.an.instanceof(Error);
					expect(err.message).to.be.equal("Path '/var/www/index.php' is not a symbolic link.");
					done();
				});
			});

			it('should change uid and gid of symlink', function (done) {
				fs.writeFileSync('/var/www/index.php', '');
				fs.symlinkSync('/var/www/index.php', '/var/www/default.php');
				fs.lchown('/var/www/default.php', 500, 600, function () {
					var stats;

					stats = fs.lstatSync('/var/www/default.php');
					expect(stats.uid).to.be.equal(500);
					expect(stats.gid).to.be.equal(600);
					done();
				});
			});

		});


		describe('#chmod()', function () {

			it('should return an error if path does not exists', function (done) {
				fs.chmod('/var/www', 777, function (err) {
					expect(err).to.be.an.instanceof(Error);
					expect(err.message).to.be.equal("File or directory '/var/www' does not exists.");
					done();
				});
			});

			it('should change mode', function (done) {
				fs.mkdirSync('/var/www');
				fs.chmod('/var/www', 777, function () {
					expect(fs.statSync('/var/www').mode).to.be.equal(777);
					done();
				});
			});

		});


		describe('#fchmod()', function () {

			it('should return an error if descriptor does not exists', function (done) {
				fs.fchmod(1, 777, function (err) {
					expect(err).to.be.an.instanceof(Error);
					expect(err.message).to.be.equal("File descriptor 1 not exists.");
					done();
				});
			});

			it('should change mode', function (done) {
				fs.writeFileSync('/var/www/index.php', '');
				fs.open('/var/www/index.php', 'r', function (err, fd) {
					fs.fchmod(fd, 777, function () {
						expect(fs.fstatSync(fd).mode).to.be.equal(777);
						done();
					});
				});
			});

		});


		describe('#lchmod()', function () {

			it('should return an error if path does not exists', function (done) {
				fs.lchmod('/var/www', 777, function (err) {
					expect(err).to.be.an.instanceof(Error);
					expect(err.message).to.be.equal("File or directory '/var/www' does not exists.");
					done();
				});
			});

			it('should return an error if path is not symlink', function (done) {
				fs.mkdirSync('/var/www');
				fs.lchmod('/var/www', 777, function (err) {
					expect(err).to.be.an.instanceof(Error);
					expect(err.message).to.be.equal("Path '/var/www' is not a symbolic link.");
					done();
				});
			});

			it('should change mode of symlink', function (done) {
				fs.writeFileSync('/var/www/index.php', '');
				fs.symlinkSync('/var/www/index.php', '/var/www/default.php');
				fs.lchmod('/var/www/default.php', 777, function () {
					expect(fs.lstatSync('/var/www/default.php').mode).to.be.equal(777);
					done();
				});
			});

		});


		describe('#stat()', function () {

			it('should return an error if path does not exists', function (done) {
				fs.stat('/var/www', function (err) {
					expect(err).to.be.an.instanceof(Error);
					expect(err.message).to.be.equal("File or directory '/var/www' does not exists.");
					done();
				});
			});

			it('should return stats object for path', function (done) {
				fs.writeFileSync('/var/www/index.php', '');
				fs.stat('/var/www/index.php', function (err, stats) {
					expect(stats).to.be.an.instanceof(Stats);
					expect(stats.isFile()).to.be.true;
					done();
				});
			});

		});


		describe('#lstat()', function () {

			it('should return an error if path does not exists', function (done) {
				fs.lstat('/var/www', function (err) {
					expect(err).to.be.an.instanceof(Error);
					expect(err.message).to.be.equal("File or directory '/var/www' does not exists.");
					done();
				});
			});

			it('should return an error if path is not a symlink', function (done) {
				fs.mkdirSync('/var/www');
				fs.lstat('/var/www', function (err) {
					expect(err).to.be.an.instanceof(Error);
					expect(err.message).to.be.equal("Path '/var/www' is not a symbolic link.");
					done();
				});
			});

			it('should return stats for symlink', function (done) {
				fs.mkdirSync('/var/www');
				fs.symlinkSync('/var/www', '/var/document_root');
				fs.lstat('/var/document_root', function (err, stats) {
					expect(stats.isSymbolicLink()).to.be.true;
					done();
				});
			});

		});


		describe('#fstat()', function () {

			it('should return an error if descriptor does not exists', function (done) {
				fs.fstat(1, function (err) {
					expect(err).to.be.an.instanceof(Error);
					expect(err.message).to.be.equal("File descriptor 1 not exists.");
					done();
				});
			});

			it('should return stat object', function (done) {
				fs.writeFileSync('/var/www/index.php', '');
				fs.open('/var/www/index.php', 'r', function (err, fd) {
					fs.fstat(fd, function (err, stats) {
						expect(stats).to.be.an.instanceof(Stats);
						expect(stats._path).to.be.equal('/var/www/index.php');
						done();
					});
				});
			});

		});


		describe('#link()', function () {

			it('should return an error if source path does not exists', function (done) {
				fs.link('/var/www/index.php', '/var/www/default.php', function (err) {
					expect(err).to.be.an.instanceof(Error);
					expect(err.message).to.be.equal("File or directory '/var/www/index.php' does not exists.");
					done();
				});
			});

			it('should create link to file', function (done) {
				fs.writeFileSync('/var/www/index.php', '');
				fs.link('/var/www/index.php', '/var/www/default.php', function () {
					expect(fs.existsSync('/var/www/default.php')).to.be.true;
					expect(fs.statSync('/var/www/default.php').isFile()).to.be.true;
					done();
				});
			});

		});


		describe('#symlink()', function () {

			it('should return an error if source path does not exists', function (done) {
				fs.symlink('/var/www/index.php', '/var/www/default.php', function (err) {
					expect(err).to.be.an.instanceof(Error);
					expect(err.message).to.be.equal("File or directory '/var/www/index.php' does not exists.");
					done();
				});
			});

			it('should create link to file', function (done) {
				fs.writeFileSync('/var/www/index.php', '');
				fs.symlink('/var/www/index.php', '/var/www/default.php', function () {
					expect(fs.existsSync('/var/www/default.php')).to.be.true;
					done();
				});
			});

		});


		describe('#readlink()', function () {

			it('should return an error if source path does not exists', function (done) {
				fs.readlink('/var/www/default.php', function (err) {
					expect(err).to.be.an.instanceof(Error);
					expect(err.message).to.be.equal("File or directory '/var/www/default.php' does not exists.");
					done();
				});
			});

			it('should get path of hard link', function (done) {
				fs.writeFileSync('/var/www/index.php', '');
				fs.link('/var/www/index.php', '/var/www/default.php', function () {
					fs.readlink('/var/www/../../var/www/something/../default.php', function (err, path) {
						expect(path).to.be.equal('/var/www/default.php');
						done();
					});
				});
			});

			it('should get path to source file of symlink', function (done) {
				fs.writeFileSync('/var/www/index.php', '');
				fs.symlink('/var/www/index.php', '/var/www/default.php', function () {
					fs.readlink('/var/www/../../var/www/something/../default.php', function (err, path) {
						expect(path).to.be.equal('/var/www/index.php');
						done();
					});
				});
			});

			it('should get normalized path to file if it is not link', function (done) {
				fs.writeFileSync('/var/www/index.php', '');
				fs.readlink('/var/www/../../var/www/something/../index.php', function (err, path) {
					expect(path).to.be.equal('/var/www/index.php');
					done();
				});
			});

		});


		describe('#realpath()', function () {

			it('should return an error if path does not exists', function (done) {
				fs.realpath('/var/www', function (err) {
					expect(err).to.be.an.instanceof(Error);
					expect(err.message).to.be.equal("File or directory '/var/www' does not exists.");
					done();
				});
			});

			it('should load realpath from cache object', function (done) {
				fs.realpath('/var/www', {'/var/www': '/var/data/www'}, function (err, resolvedPath) {
					expect(resolvedPath).to.be.equal('/var/data/www');
					done();
				});
			});

			it('should return resolved realpath', function (done) {
				fs.writeFileSync('/var/www/index.php', '');
				fs.realpath('/var/www/data/../../www/index.php', function (err, resolvedPath) {
					expect(resolvedPath).to.be.equal('/var/www/index.php');
					done();
				});
			});

		});


		describe('#unlink()', function () {

			it('should return an error if path does not exists', function (done) {
				fs.unlink('/var/www/index.php', function (err) {
					expect(err).to.be.an.instanceof(Error);
					expect(err.message).to.be.equal("File or directory '/var/www/index.php' does not exists.");
					done();
				});
			});

			it('should return an error if path is not file', function (done) {
				fs.mkdirSync('/var/www');
				fs.unlink('/var/www', function (err) {
					expect(err).to.be.an.instanceof(Error);
					expect(err.message).to.be.equal("Path '/var/www' is not a file.");
					done();
				});
			});

			it('should remove file', function (done) {
				fs.writeFileSync('/var/www/index.php', '');
				fs.unlink('/var/www/index.php', function () {
					expect(fs._data).to.have.keys(['/', '/var/www', '/var']);
					done();
				});
			});

		});


		describe('#rmdir()', function () {

			it('should return an error if path does not exists', function (done) {
				fs.rmdir('/var/www', function (err) {
					expect(err).to.be.an.instanceof(Error);
					expect(err.message).to.be.equal("File or directory '/var/www' does not exists.");
					done();
				});
			});

			it('should return an error if path is not directory', function (done) {
				fs.writeFileSync('/var/www/index.php', '');
				fs.rmdir('/var/www/index.php', function (err) {
					expect(err).to.be.an.instanceof(Error);
					expect(err.message).to.be.equal("Path '/var/www/index.php' is not a directory.");
					done();
				});
			});

			it('should return an error if directory is not empty', function (done) {
				fs.mkdirSync('/var/www');
				fs.writeFileSync('/var/www/index.php', '');
				fs.rmdir('/var/www', function (err) {
					expect(err).to.be.an.instanceof(Error);
					expect(err.message).to.be.equal("Directory '/var/www' is not empty.");
					done();
				});
			});

			it('should remove directory', function (done) {
				fs.mkdirSync('/var/www');
				fs.rmdir('/var/www', function () {
					expect(fs._data).to.have.keys(['/', '/var']);
					done();
				});
			});

		});


		describe('#mkdir()', function () {

			it('should return an error if path already exists', function (done) {
				fs.mkdirSync('/var/www');
				fs.mkdir('/var/www', function (err) {
					expect(err).to.be.an.instanceof(Error);
					expect(err.message).to.be.equal("File or directory '/var/www' already exists.");
					done();
				});
			});

			it('should create new directory', function (done) {
				fs.mkdir('/var/www', function () {
					expect(fs._data).to.have.keys(['/', '/var', '/var/www']);
					done();
				});
			});

		});


		describe('#readdir()', function () {

			it('should return an error if path does not exists', function (done) {
				fs.readdir('/var/www', function (err) {
					expect(err).to.be.an.instanceof(Error);
					expect(err.message).to.be.equal("File or directory '/var/www' does not exists.");
					done();
				});
			});

			it('should throw an error if path is not directory', function (done) {
				fs.writeFileSync('/var/www/index.php', '');
				fs.readdir('/var/www/index.php', function (err) {
					expect(err).to.be.an.instanceof(Error);
					expect(err.message).to.be.equal("Path '/var/www/index.php' is not a directory.");
					done();
				});
			});

			it('should load all files and directories from directory', function (done) {
				var fs;

				fs = new FS({
					'/var/www': {
						'index.php': '',
						'project': {
							'school': {}
						}
					},
					'/home/david': {}
				});

				fs.readdir('/var/www', function (err, files) {
					expect(files).to.be.eql([
						'index.php',
						'project'
					]);

					expect(fs.statSync('/var/www/index.php').isFile()).to.be.true;
					expect(fs.statSync('/var/www/project').isDirectory()).to.be.true;

					done()
				});
			});

		});


		describe('#close()', function () {

			it('should return an error if file descriptor does not exists', function (done) {
				fs.close(1, function (err) {
					expect(err).to.be.an.instanceof(Error);
					expect(err.message).to.be.equal("File descriptor 1 not exists.");
					done();
				});
			});

			it('should close opened file', function (done) {
				var fd;

				fs.writeFileSync('/var/www/index.php', '');
				fd = fs.openSync('/var/www/index.php', 'r');
				fs.close(fd, function () {
					expect(fs._fileDescriptors).to.be.eql([]);
					done();
				});
			});

		});


		describe('#open()', function () {

			it('should return an error if file does not exists (flag: r)', function (done) {
				fs.open('/var/www/index.php', 'r', function (err) {
					expect(err).to.be.an.instanceof(Error);
					expect(err.message).to.be.equal("File or directory '/var/www/index.php' does not exists.");
					done();
				});
			});

			it('should return an error if file does not exists (flag: r+)', function (done) {
				fs.open('/var/www/index.php', 'r+', function (err) {
					expect(err).to.be.an.instanceof(Error);
					expect(err.message).to.be.equal("File or directory '/var/www/index.php' does not exists.");
					done();
				});
			});

			it('should return an error if file already exists (flag: wx)', function (done) {
				fs.writeFileSync('/var/www/index.php', '');
				fs.open('/var/www/index.php', 'wx', function (err) {
					expect(err).to.be.an.instanceof(Error);
					expect(err.message).to.be.equal("File or directory '/var/www/index.php' already exists.");
					done();
				});
			});

			it('should return an error if file already exists (flag: wx+)', function (done) {
				fs.writeFileSync('/var/www/index.php', '');
				fs.open('/var/www/index.php', 'wx+', function (err) {
					expect(err).to.be.an.instanceof(Error);
					expect(err.message).to.be.equal("File or directory '/var/www/index.php' already exists.");
					done();
				});
			});

			it('should return an error if file already exists (flag: ax)', function (done) {
				fs.writeFileSync('/var/www/index.php', '');
				fs.open('/var/www/index.php', 'ax', function (err) {
					expect(err).to.be.an.instanceof(Error);
					expect(err.message).to.be.equal("File or directory '/var/www/index.php' already exists.");
					done();
				});
			});

			it('should return an error if file already exists (flag: ax+)', function (done) {
				fs.writeFileSync('/var/www/index.php', '');
				fs.open('/var/www/index.php', 'ax+', function (err) {
					expect(err).to.be.an.instanceof(Error);
					expect(err.message).to.be.equal("File or directory '/var/www/index.php' already exists.");
					done();
				});
			});

			it('should create new file if it does not exists (flag: w)', function (done) {
				fs.open('/var/www/index.php', 'w', function (err, fd) {
					expect(fs.fstatSync(fd).isFile()).to.be.true;
					done();
				});
			});

			it('should create new file if it does not exists (flag: w+)', function (done) {
				fs.open('/var/www/index.php', 'w+', function (err, fd) {
					expect(fs.fstatSync(fd).isFile()).to.be.true;
					done();
				});
			});

			it('should create new file if it does not exists (flag: a)', function (done) {
				fs.open('/var/www/index.php', 'a', function (err, fd) {
					expect(fs.fstatSync(fd).isFile()).to.be.true;
					done();
				});
			});

			it('should create new file if it does not exists (flag: a+)', function (done) {
				fs.open('/var/www/index.php', 'a+', function (err, fd) {
					expect(fs.fstatSync(fd).isFile()).to.be.true;
					done();
				});
			});

		});


		describe('#utimes()', function () {

			it('should change atime and mtime', function (done) {
				var atime, mtime;

				fs.writeFileSync('/var/www/index.php', '');
				atime = fs.statSync('/var/www/index.php').atime;
				mtime = fs.statSync('/var/www/index.php').mtime;

				setTimeout(function () {
					fs.utimes('/var/www/index.php', new Date, new Date, function () {
						expect(fs.statSync('/var/www/index.php').atime.getTime()).not.to.be.equal(atime.getTime());
						expect(fs.statSync('/var/www/index.php').mtime.getTime()).not.to.be.equal(mtime.getTime());
						done();
					});
				}, 100);
			});

		});


		describe('#futimes()', function () {

			it('should return an error if file descriptor does not exists', function (done) {
				fs.futimes(1, new Date, new Date, function (err) {
					expect(err).to.be.an.instanceof(Error);
					expect(err.message).to.be.equal("File descriptor 1 not exists.");
					done();
				});
			});

			it('should change atime and mtime', function (done) {
				fs.mkdirSync('/var/www');

				fs.open('/var/www', 'r', function (err, fd) {
					var atime, mtime;

					atime = fs.fstatSync(fd).atime;
					mtime = fs.fstatSync(fd).mtime;

					setTimeout(function () {
						fs.futimes(fd, new Date, new Date, function () {
							expect(fs.fstatSync(fd).atime.getTime()).not.to.be.equal(atime.getTime());
							expect(fs.fstatSync(fd).mtime.getTime()).not.to.be.equal(mtime.getTime());
							done();
						});
					}, 100);
				});
			});

		});


		describe('#fsync()', function () {

			it('should return an error if file descriptor does not exists', function (done) {
				fs.fsync(1, function (err) {
					expect(err).to.be.an.instanceof(Error);
					expect(err.message).to.be.equal("File descriptor 1 not exists.");
					done();
				});
			});

		});


		describe('#write()', function () {

			it('should return an error if file descriptor does not exists', function (done) {
				fs.write(1, new Buffer(''), 0, 0, 0, function (err) {
					expect(err).to.be.an.instanceof(Error);
					expect(err.message).to.be.equal("File descriptor 1 not exists.");
					done();
				});
			});

			it('should return an error if file is not open for writing', function (done) {
				fs.writeFileSync('/var/www/index.php', '');
				fs.open('/var/www/index.php', 'r', function (err, fd) {
					fs.write(fd, new Buffer(''), 0, 0, 0, function (err) {
						expect(err).to.be.an.instanceof(Error);
						expect(err.message).to.be.equal("File '/var/www/index.php' is not open for writing.");
						done();
					});
				});
			});

			it('should write data to file', function (done) {
				fs.writeFileSync('/var/www/index.php', 'hello word');
				fs.open('/var/www/index.php', 'w', function (err, fd) {
					fs.write(fd, new Buffer('hello'), 0, 5, null, function () {
						expect(fs.readFileSync('/var/www/index.php', {
							encoding: 'utf8'
						})).to.be.equal('hello');

						done();
					});
				});
			});

			it('should write data to exact position in file', function (done) {
				fs.writeFileSync('/var/www/index.php', 'helloword');
				fs.open('/var/www/index.php', 'w', function (err, fd) {
					fs.write(fd, new Buffer(' '), 0, 1, 5, function () {
						expect(fs.readFileSync('/var/www/index.php', {
							encoding: 'utf8'
						})).to.be.equal('hello word');

						done();
					});
				});
			});

		});


		describe('#read()', function () {

			it('should return an error if file descriptor does not exists', function (done) {
				fs.read(1, new Buffer(1), 0, 1, null, function (err) {
					expect(err).to.be.an.instanceof(Error);
					expect(err.message).to.be.equal("File descriptor 1 not exists.");
					done();
				});
			});

			it('should return an error if file is not open for reading', function (done) {
				fs.writeFileSync('/var/www/index.php', '');
				fs.open('/var/www/index.php', 'w', function (err, fd) {
					fs.read(fd, new Buffer(1), 0, 1, null, function (err) {
						expect(err).to.be.an.instanceof(Error);
						expect(err.message).to.be.equal("File '/var/www/index.php' is not open for reading.");
						done();
					});
				});
			});

			it('should read all data', function (done) {
				fs.writeFileSync('/var/www/index.php', 'hello word');
				fs.open('/var/www/index.php', 'r', function (err, fd) {
					var size, buffer;

					size = fs.fstatSync(fd).size;
					buffer = new Buffer(size);

					fs.read(fd, buffer, 0, size, null, function (err, bytesRead, buffer) {
						expect(bytesRead).to.be.equal(size);
						expect(bytesRead).to.be.equal(10);
						expect(buffer.toString('utf8')).to.be.equal('hello word');
						done();
					});
				});
			});

			it('should read all data byte by byte', function (done) {
				fs.writeFileSync('/var/www/index.php', 'hello word');
				fs.open('/var/www/index.php', 'r', function (err, fd) {
					var size, buffer, bytesRead;

					size = fs.fstatSync(fd).size;
					buffer = new Buffer(size);
					bytesRead = 0;

					while (bytesRead < size) {
						fs.read(fd, buffer, bytesRead, 1, bytesRead);
						bytesRead++;
					}

					expect(buffer.toString('utf8')).to.be.equal('hello word');
					done();
				});
			});

		});


		describe('#readFile()', function () {

			it('should return an error if path does not exists', function (done) {
				fs.readFile('/var/www/index.php', function (err) {
					expect(err).to.be.an.instanceof(Error);
					expect(err.message).to.be.equal("File or directory '/var/www/index.php' does not exists.");
					done();
				});
			});

			it('should throw an error if path is not file', function (done) {
				fs.mkdirSync('/var/www');
				fs.readFile('/var/www', function (err) {
					expect(err).to.be.an.instanceof(Error);
					expect(err.message).to.be.equal("Path '/var/www' is not a file.");
					done();
				});
			});

			it('should read data from file as buffer', function (done) {
				var s;

				s = '<?php echo "hello";';
				fs.writeFileSync('/var/www/index.php', s);
				fs.readFile('/var/www/index.php', function (err, data) {
					expect(data).to.be.an.instanceof(Buffer);
					expect(data.toString('utf8')).to.be.equal(s);
					done();
				});
			});

			it('should read data from file as string', function (done) {
				var s;

				s = '<?php echo "hello";';
				fs.writeFileSync('/var/www/index.php', s);
				fs.readFile('/var/www/index.php', {encoding: 'utf8'}, function (err, data) {
					expect(data).to.be.equal(s);
					done();
				});
			});

		});


		describe('#writeFile()', function () {

			it('should create new file', function (done) {
				fs.writeFile('/var/www/index.php', '', function () {
					expect(fs._data).to.have.keys(['/', '/var/www/index.php', '/var/www', '/var']);
					expect(fs.statSync('/var/www/index.php').isFile()).to.be.true;
					done();
				});
			});

			it('should rewrite old file', function (done) {
				fs.writeFileSync('/var/www/index.php', 'old');
				fs.writeFile('/var/www/index.php', 'new', function () {
					expect(fs.readFileSync('/var/www/index.php', {
						encoding: 'utf8'
					})).to.be.equal('new');

					done();
				});
			});

		});


		describe('#appendFile()', function () {

			it('should return an error if path is not file', function (done) {
				fs.mkdirSync('/var/www');
				fs.appendFile('/var/www', '', function (err) {
					expect(err).to.be.an.instanceof(Error);
					expect(err.message).to.be.equal("Path '/var/www' is not a file.");
					done();
				});
			});

			it('should create new file', function (done) {
				fs.appendFile('/var/www/index.php', 'hello', function () {
					expect(fs.readFileSync('/var/www/index.php', {
						encoding: 'utf8'
					})).to.be.equal('hello');

					done();
				});
			});

			it('should append data to file with buffer', function (done) {
				fs.writeFileSync('/var/www/index.php', 'one');
				fs.appendFile('/var/www/index.php', new Buffer(', two'), function () {
					expect(fs.readFileSync('/var/www/index.php', {
						encoding: 'utf8'
					})).to.be.equal('one, two');

					done();
				});
			});

		});


		describe('#watch()', function () {

			it('should throw an error if path does not exists', function () {
				expect(function () {
					fs.watch('/var/www');
				}).to.throw(Error, "File or directory '/var/www' does not exists.");
			});

			it('should call listener when attributes were changed', function (done) {
				fs.writeFileSync('/var/www/index.php', '');
				fs.watch('/var/www/index.php', function (event, filename) {
					expect(event).to.be.equal('change');
					expect(filename).to.be.equal('/var/www/index.php');
					done();
				});

				fs.utimesSync('/var/www/index.php', new Date, new Date);
			});

			it('should call listener when file was renamed', function (done) {
				fs.writeFileSync('/var/www/index.php', '');
				fs.watch('/var/www/index.php', function (event, filename) {
					expect(event).to.be.equal('rename');
					expect(filename).to.be.equal('/var/www/default.php');
					done();
				});

				fs.renameSync('/var/www/index.php', '/var/www/default.php');
			});

			it('should call listener when data was changed', function (done) {
				fs.writeFileSync('/var/www/index.php', '');
				fs.watch('/var/www/index.php', function (event, filename) {
					expect(event).to.be.equal('change');
					expect(filename).to.be.equal('/var/www/index.php');
					expect(fs.readFileSync('/var/www/index.php', {
						encoding: 'utf8'
					})).to.be.equal('hello word');

					done();
				});

				fs.writeFileSync('/var/www/index.php', 'hello word');
			});

			it('should close watching', function (done) {
				var called, watcher;

				fs.writeFileSync('/var/www/index.php', '');
				called = false;

				watcher = fs.watch('/var/www/index.php', function (event, filename) {
					called = true;
				});

				watcher.close();
				fs.utimesSync('/var/www/index.php', new Date, new Date);

				setTimeout(function () {
					expect(called).to.be.false;
					done();
				}, 50);
			});

		});


		describe('#exists()', function () {

			it('should return false when file does not exists', function (done) {
				fs.exists('/var/www/index.php', function (exists) {
					expect(exists).to.be.false;
					done();
				});
			});

			it('should return true when file exists', function (done) {
				fs.writeFileSync('/var/www/index.php', '');
				fs.exists('/var/www/index.php', function (exists) {
					expect(exists).to.be.true;
					done();
				});
			});

		});


		describe('#createReadStream()', function () {

			it('should emit an open event with the file descriptor when it opens a file', function (done) {
				var rs;

				fs.writeFileSync('/var/www/index.php', '');

				rs = fs.createReadStream('/var/www/index.php');

				rs.on('open', function (fd) {
					expect(fd).to.be.a('number');
					done();
				});
			});

			it('should not emit an open event if file does not exist', function (done) {
				var rs;

				rs = fs.createReadStream('/var/www/index.php');

				rs.on('open', function () {
					expect().fail();
				});

				rs.on('error', function () {
					done();
				});
			});

			it('should emit an error event if file does not exist', function (done) {
				var rs;

				rs = fs.createReadStream('/var/www/index.php');
				rs.on('error', function (err) {
					expect(err).to.be.an.instanceof(Error);
					done();
				});
			});

			it('should create readable stream', function (done) {
				var rs;

				fs.writeFileSync('/var/www/index.php', 'hello word');
				rs = fs.createReadStream('/var/www/index.php');
				rs.setEncoding('utf8');

				rs.on('data', function (chunk) {
					expect(chunk).to.be.equal('hello word');
					done();
				});
			});

			it('should create readable stream with start and end', function (done) {
				var rs;

				fs.writeFileSync('/var/www/index.php', 'hello word');
				rs = fs.createReadStream('/var/www/index.php', {start: 6, end: 10});
				rs.setEncoding('utf8');

				rs.on('data', function (chunk) {
					expect(chunk).to.be.equal('word');
					done();
				});
			});

			it('should create readable stream with custom fd', function (done) {
				var fd, rs;

				fs.writeFileSync('/var/www/index.php', 'hello word');

				fd = fs.openSync('/var/www/index.php', 'r', 666);
				rs = fs.createReadStream('/var/www/index.php', {fd: fd, autoClose: false});
				rs.setEncoding('utf8');

				rs.on('data', function (chunk) {
					expect(chunk).to.be.equal('hello word');
					expect(fs._hasFd(fd)).to.be.true;

					fs.closeSync(fd);
					done();
				});
			});

		});


		describe('#createWriteStream()', function () {

			it('should emit an open event with the file descriptor when it opens a file', function (done) {
				var ws;

				fs.writeFileSync('/var/www/index.php', '');
				ws = fs.createWriteStream('/var/www/index.php');

				ws.on('open', function (fd) {
					expect(fd).to.be.a('number');
					done();
				});
			});

			it('should not emit an open event if creating write stream fails', function (done) {
				var ws;

				fs.writeFileSync('/var/www/index.php', '');
				ws = fs.createWriteStream('/var/www/index.php', {flags: 'wx'});

				ws.on('open', function () {
					expect().fail();
				});

				ws.on('error', function () {
					done();
				});
			});

			it('should emit an error event if mode is wx and file already exists', function (done) {
				var ws;

				fs.writeFileSync('/var/www/index.php', '');
				ws = fs.createWriteStream('/var/www/index.php', {flags: 'wx'});

				ws.on('error', function (err) {
					expect(err).to.be.an.instanceof(Error);
					done();
				});
			});

			it('should not emit an finish event when valid read stream is piped to invalid write stream', function (done) {
				var rs, ws;

				fs.mkdirSync('/var/www');
				fs.writeFileSync('/var/www/index.php', 'hello');
				rs = fs.createReadStream('/var/www/index.php');

				ws = fs.createWriteStream('/var/www');

				ws.on('finish', function () {
					throw new Error("should not finish");
				});

				ws.on('error', function () {
					done();
				});

				rs.pipe(ws);
			});

			it('should emit an error event if file is a directory', function (done) {
				var ws;

				fs.mkdirSync('/var/www');
				ws = fs.createWriteStream('/var/www');
				ws.on('error', function (err) {
					expect(err).to.be.an.instanceof(Error);
					done();
				});

				ws.write('hello');
			});

			it('should create writable stream', function (done) {
				var ws;

				fs.writeFileSync('/var/www/index.php', '');
				ws = fs.createWriteStream('/var/www/index.php');
				ws.on('finish', function () {
					expect(fs.readFileSync('/var/www/index.php', {
						encoding: 'utf8'
					})).to.be.equal('hello word');

					done();
				});

				ws.write('hello');
				ws.write(' ');
				ws.write('word');
				ws.end();
			});

		});

	});

}).call(this);
