# fs-mock

[![NPM version](https://img.shields.io/npm/v/fs-mock.svg?style=flat-square)](http://badge.fury.io/js/fs-mock)
[![Dependency Status](https://img.shields.io/gemnasium/Carrooi/Node-FsMock.svg?style=flat-square)](https://gemnasium.com/Carrooi/Node-FsMock)
[![Build Status](https://img.shields.io/travis/Carrooi/Node-FsMock.svg?style=flat-square)](https://travis-ci.org/Carrooi/Node-FsMock)

[![Donate](https://img.shields.io/badge/donate-PayPal-brightgreen.svg?style=flat-square)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=89MDP3DHWXYPW)

Simple fs mock with posix and windows file system styles.

## Help

Unfortunately I don't have any more time to maintain this repository :-( 

Don't you want to save me and this project by taking over it?

![sad cat](https://raw.githubusercontent.com/sakren/sakren.github.io/master/images/sad-kitten.jpg)

## Installation

```
$ npm install fs-mock
```

## Usage

**This module does not change original fs module in any way.**

If you want to pass this module into other module, you will have to use for example [rewire](https://github.com/jhnns/rewire)
package.

```
var FS = require('fs-mock');
var fs = new FS({
	'var': {},											// empty directory
	'var/www/index.php': '',							// empty file in /var/www, so directory var is now not empty
	'home/david/documents/school/projects': {},
	'home': {
		'david': {},
		'john': {
			'password.txt': 'my super password'			// file
		}
	}
});

var myPassword = fs.readFileSync('/home/john/password.txt', {encoding: 'utf8'});		// my super password
```

If you write some path like this: `home/david/documents/school/projects`, it will be automatically expanded and all its
parent directories will be also added to mocked file system.

## Windows

```
var fs = new FS({
	'Users': {
		'David': {
			'password.txt': 'my super password'
		}
	}
}, {
	windows: true
});
```

This will change delimiter from `/` to `\` and add root directory to `c:`.

### Other drives

```
new FS({ ... }, {
	windows: true,
	drives: ['c:', 'd:', 'z:']
});
```

### Another root directory

```
new FS({ ... }, {
	windows: true,
	drives: ['c:', 'd:', 'z:'],
	root: 'z:'
});
```

Now every path will be saved into `z:` drive.

If you want to save paths to custom drives, you need to disable auto saving into `options.root`.

```
new FS({
	'c:': {
		'Users': {}
	},
	'x:': {
		'xampp': {
			'htdocs': {}
		}
	}
}, {
	windows: true,
	root: false
});
```

**I haven't got any machine with Windows so all methods (like chmod) works just like in Unix systems. Please let me know
if you want to improve this and how.**

## Supported functions

There are also all *Sync methods.

Calling unsupported methods will throw an exception.

### Fs object:

* `fs.rename()`: yes
* `fs.ftruncate()`: yes
* `fs.truncate()`: yes
* `fs.chown()`: yes
* `fs.fchown()`: yes
* `fs.lchown()`: yes
* `fs.chmod()`: yes
* `fs.fchmod()`: yes
* `fs.lchmod()`: yes
* `fs.stat()`: yes
* `fs.lstat()`: yes
* `fs.fstat()`: yes
* `fs.link()`: yes
* `fs.symlink()`: yes (type argument is ignored)
* `fs.readlink()`: yes
* `fs.realpath()`: yes
* `fs.unlink()`: yes
* `fs.rmdir()`: yes
* `fs.mkdir()`: yes
* `fs.readdir()`: yes
* `fs.close()`: yes
* `fs.open()`: yes
* `fs.utimes()`: yes
* `fs.futimes()`: yes
* `fs.write()`: yes
* `fs.read()`: yes
* `fs.readFile()`: yes
* `fs.writeFile()`: yes
* `fs.appendFile()`: yes
* `fs.watchFile()`: no (use fs.watch())
* `fs.unwatchFile()`: no (use fs.watch())
* `fs.watch()`: yes (persistent option is ignored)
* `fs.exists()`: yes
* `fs.createReadStream()`: yes
* `fs.createWriteStream()`: yes

### Stats object:

* `dev`: no
* `ino`: no
* `mode`: yes
* `nlink`: no
* `uid`: yes
* `gid`: yes
* `rdev`: no
* `size`: yes
* `blksize`: yes
* `blocks`: yes
* `atime`: yes
* `mtime`: yes
* `ctime`: yes
* `isFile()`: yes
* `isDirectory()`: yes
* `isBlockDevice()`: no
* `isCharacterDevice()`: no
* `isSymbolicLink()`: yes
* `isFIFO()`: no
* `isSocket()`: no

## Tests

```
$ npm test
```

## Changelog

* 1.2.0 - 1.2.1
	+ Move repository under Carrooi organization
	+ Abandon project
	+ Rewritten to pure javascript
	+ Rebind all methods so they can be called event when they are unbound [#11](https://github.com/Carrooi/Node-FsMock/issues/11)
	+ Updated dependencies
	+ Fixed root directories [#15](https://github.com/Carrooi/Node-FsMock/issues/15)
	+ Added some tests
	+ Some fixes for Windows
	+ Fixed paths with trailing slashes [#13](https://github.com/Carrooi/Node-FsMock/issues/13)
	+ Fixed lstat called on non symbolic links [#14](https://github.com/Carrooi/Node-FsMock/issues/14)
	+ Allow writing raw buffer [#7](https://github.com/Carrooi/Node-FsMock/issues/7)

* 1.1.3
	+ Bug with createReadStream and createWriteStream not emitting 'open' event [#10](https://github.com/Carrooi/Node-FsMock/pull/10)

* 1.1.2
	+ Bug with createWriteStream sending improper 'finish' event

* 1.1.1
	+ Setup coffee-script for development
	+ createReadStream/createWriteStream send error events instead of exceptions
	+ createReadStream could not use custom `fd` in options

* 1.1.0
	+ Added support for windows file systems
	+ Added many tests

* 1.0.1
	+ Bug with root directories and readdir method

* 1.0.0
	+ First version
