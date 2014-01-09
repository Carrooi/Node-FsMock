# fs-mock

Mock for fs module

## Installation

```
$ npm install fs-mock
```

## Supported functions

When async function is supported, there is also it's sync version.

Calling unsupported methods will throw an exception.

### Fs object

* `fs.rename()`: yes
* `fs.ftruncate()`: yes
* `fs.truncate()`: yes
* `fs.chown()`: yes
* `fs.fchown()`: yes
* `fs.lchown()`: no
* `fs.chmod()`: yes
* `fs.fchmod()`: yes
* `fs.lchmod()`: no
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

### Stats:

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

* 1.0.0
	+ First version