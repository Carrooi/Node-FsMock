(function() {

	var Helpers = require('../src/Helpers');

	var expect = require('chai').expect;


	describe('Helpers', function() {


		describe('#normalizeUNCRoot()', function() {

			it('should normalize UNC root', function() {
				expect(Helpers.normalizeUNCRoot('c:/')).to.be.equal('\\\\c:\\');
			});

		});


		describe('#joinPathsWindows()', function() {

			it('should join paths', function() {
				expect(Helpers.joinPathsWindows(['c:', 'xampp', 'htdocs', 'index.php'])).to.be.equal('c:\\xampp\\htdocs\\index.php');
			});

		});


		describe('#joinPathsPosix()', function() {

			it('should join paths', function() {
				expect(Helpers.joinPathsPosix(['var', 'www', 'index.php'])).to.be.equal('var/www/index.php');
			});

		});


		describe('#normalizePathWindows()', function() {

			it('should return normalized windows path', function() {
				expect(Helpers.normalizePathWindows('c:/xampp/../xampp/htdocs/../../././xampp/htdocs/index.php')).to.be.equal('c:\\xampp\\htdocs\\index.php');
			});

			it('should return normalized drive', function() {
				expect(Helpers.normalizePathWindows('c:')).to.be.equal('c:');
			});

			it('should return normalized path with trailing /', function() {
				expect(Helpers.normalizePathWindows('c:\\xampp\\htdocs\\')).to.be.equal('c:\\xampp\\htdocs');
			});

		});


		describe('#normalizePathPosix()', function() {

			it('should return normalized posix path', function() {
				expect(Helpers.normalizePathPosix('/var/../var/www/../../././var/www/index.php')).to.be.equal('/var/www/index.php');
			});

			it('should return normalized path with trailing /', function() {
				expect(Helpers.normalizePathPosix('/var/www/')).to.be.equal('/var/www');
			});

		});


		describe('#isAbsoluteWindows()', function() {

			it('should return true for absolute path', function() {
				expect(Helpers.isAbsoluteWindows('c:\\xampp')).to.be.true;
			});

			it('should return true for absolute UNC path', function() {
				expect(Helpers.isAbsoluteWindows('\\\\xampp')).to.be.true;
			});

			it('should return false for relative path', function() {
				expect(Helpers.isAbsoluteWindows('..\\xampp')).to.be.false;
			});

		});


		describe('#isAbsolutePosix()', function() {

			it('should return true for absolute path', function() {
				expect(Helpers.isAbsolutePosix('/var')).to.be.true;
			});

			it('should return false for relative path', function() {
				expect(Helpers.isAbsolutePosix('../var')).to.be.false;
			});

		});


	});

}).call(this);
