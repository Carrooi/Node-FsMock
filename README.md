# fs-mock

Mock for fs module

## Installation

```
$ npm install fs-mock
```

## Supported functions

When async function is supported, there is also it's sync version.

Calling unsupported methods will throw an exception.

* `fs.rename`: yes
* `fs.ftruncate`: yes
* `fs.truncate`: yes
* `fs.chown`: yes
* `fs.fchown`: no
* `fs.lchown`: no
* `fs.chmod`: yes
* `fs.fchmod`: no
* `fs.lchmod`: no
* `fs.stat`: yes
* `fs.lstat`: no
* `fs.fstat`: no
* `fs.link`: no
* `fs.symlink`: no
* `fs.readlink`: no
* `fs.realpath`: no
* `fs.unlink`: yes
* `fs.rmdir`: yes
* `fs.mkdir`: yes
* `fs.readdir`: yes
* `fs.close`: yes
* `fs.open`: yes
* `fs.utimes`: no
* `fs.futimes`: no
* `fs.write`: yes
* `fs.read`: yes
* `fs.readFile`: yes
* `fs.writeFile`: yes
* `fs.appendFile`: yes
* `fs.watchFile`: no
* `fs.unwatchFile`: no
* `fs.watch`: no
* `fs.exists`: yes
* `fs.createReadStream`: no
* `fs.createWriteStream`: no

## Tests

```
$ npm test
```

## Changelog

* 1.0.0
	+ First version