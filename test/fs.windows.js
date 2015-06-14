(function() {

	var FS = require('../lib/fs');

	var expect = require('chai').expect;


	var fs = null;


	describe('fs.posix', function () {


		beforeEach(function () {
			fs = new FS;
		});


		describe('#constructor()', function () {

			it('should parse input data', function () {
				fs = new FS({
					'xampp': {},
					'xampp\\htdocs\\index.php': '',
					'Users\\david\\documents\\school\\projects': {},
					'Users': {
						'david': {},
						'john': {
							'passwords.txt': ''
						}
					}
				}, {windows: true});

				expect(fs._data).to.have.keys([
					'c:', 'c:\\xampp', 'c:\\xampp\\htdocs\\index.php', 'c:\\xampp\\htdocs',
					'c:\\Users\\david\\documents\\school\\projects', 'c:\\Users\\david\\documents\\school',
					'c:\\Users\\david\\documents', 'c:\\Users\\david', 'c:\\Users', 'c:\\Users\\john',
					'c:\\Users\\john\\passwords.txt'
				]);

				expect(fs.statSync('c:\\xampp\\htdocs\\index.php').isFile()).to.be.true;
				expect(fs.statSync('c:\\xampp\\htdocs').isDirectory()).to.be.true;
				expect(fs.statSync('c:\\Users\\john').isDirectory()).to.be.true;
				expect(fs.statSync('c:\\Users\\john\\passwords.txt').isFile()).to.be.true;
			});

		});


		describe('#options', function () {

			it('should create mocked fs with root directory', function () {
				fs = new FS({}, {windows: true});
				expect(fs._data).to.have.keys(['c:']);
			});

			it('should create mocked fs with different root', function () {
				fs = new FS({
					'xampp': {
						'htdocs': {
							'index.php': ''
						}
					},
					'Users\\David\\passwords.txt': ''
				}, {windows: true, root: 'd:'});

				expect(fs._data).to.have.keys([
					'd:', 'd:\\xampp', 'd:\\xampp\\htdocs', 'd:\\xampp\\htdocs\\index.php', 'd:\\Users', 'd:\\Users\\David',
					'd:\\Users\\David\\passwords.txt'
				]);
			});

			it('should create mocked fs with other drives', function () {
				fs = new FS({
					'Users\\David\\passwords.txt': ''
				}, {windows: true, drives: ['d:', 'z:', 'x:']});

				expect(fs._data).to.have.keys([
					'c:', 'c:\\Users', 'c:\\Users\\David', 'c:\\Users\\David\\passwords.txt', 'd:', 'z:', 'x:'
				]);
			});

			it('should create mocked fs with files in different drives', function () {
				fs = new FS({
					'c:\\Users\\David\\passwords.txt': {},
					'x:\\xampp\\htdocs\\index.php': ''
				}, {windows: true, root: false});

				expect(fs._data).to.have.keys([
					'c:', 'c:\\Users', 'c:\\Users\\David', 'c:\\Users\\David\\passwords.txt',
					'x:', 'x:\\xampp', 'x:\\xampp\\htdocs', 'x:\\xampp\\htdocs\\index.php'
				]);
			});

		});

	});

}).call(this);
