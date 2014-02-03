// Generated by CoffeeScript 1.6.3
(function() {
  var Helpers, path,
    __slice = [].slice;

  path = require('path');

  Helpers = (function() {
    function Helpers() {}

    Helpers.splitDeviceRe = /^([a-zA-Z]:|[\\\/]{2}[^\\\/]+[\\\/]+[^\\\/]+)?([\\\/])?([\s\S]*?)$/;

    Helpers.normalizeArray = function(parts, allowAboveRoot) {
      var i, last, up;
      up = 0;
      i = parts.length - 1;
      while (i >= 0) {
        last = parts[i];
        if (last === ".") {
          parts.splice(i, 1);
        } else if (last === "..") {
          parts.splice(i, 1);
          up++;
        } else if (up) {
          parts.splice(i, 1);
          up--;
        }
        i--;
      }
      if (allowAboveRoot) {
        while (up--) {
          parts.unshift("..");
          up;
        }
      }
      return parts;
    };

    Helpers.normalizeDriveWindows = function(drive) {
      drive = this.normalizePathWindows(drive);
      if (drive.length === 3 && drive.charAt(2) === '.') {
        drive = drive.substr(0, 2);
      }
      return drive;
    };

    Helpers.normalizeUNCRoot = function(device) {
      return '\\\\' + device.replace(/^[\\\/]+/, '').replace(/[\\\/]+/g, '\\');
    };

    Helpers.joinPaths = function() {
      var isWindows, paths;
      isWindows = arguments[0], paths = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      if (isWindows == null) {
        isWindows = false;
      }
      if (isWindows) {
        return this.joinPathsWindows(paths);
      } else {
        return this.joinPathsPosix(paths);
      }
    };

    Helpers.normalizePath = function(isWindows, path) {
      if (isWindows == null) {
        isWindows = false;
      }
      if (isWindows) {
        return this.normalizePathWindows(path);
      } else {
        return this.normalizePathPosix(path);
      }
    };

    Helpers.joinPathsWindows = function(paths) {
      var f, joined;
      f = function(p) {
        if (typeof p !== 'string') {
          throw new TypeError('Arguments to path.join must be strings');
        }
        return p;
      };
      paths = Array.prototype.filter.call(paths, f);
      joined = paths.join('\\');
      if (!/^[\\\/]{2}[^\\\/]/.test(paths[0])) {
        joined = joined.replace(/^[\\\/]{2,}/, '\\');
      }
      return this.normalizePathWindows(joined);
    };

    Helpers.joinPathsPosix = function(paths) {
      var segment, _i, _len;
      path = '';
      for (_i = 0, _len = paths.length; _i < _len; _i++) {
        segment = paths[_i];
        if (typeof segment !== 'string') {
          throw new TypeError('Arguments to path.join must be strings');
        }
        if (segment) {
          if (!path) {
            path += segment;
          } else {
            path += '/' + segment;
          }
        }
      }
      return this.normalizePathPosix(path);
    };

    Helpers.normalizePathWindows = function(path) {
      var device, isAbsolute, isUnc, result, tail, trailingSlash;
      result = this.splitDeviceRe.exec(path);
      device = result[1] || '';
      isUnc = device && device.charAt(1) !== ':';
      isAbsolute = this.isAbsoluteWindows(path);
      tail = result[3];
      trailingSlash = /[\\\/]$/.test(tail);
      if (device && device.charAt(1) === ':') {
        device = device[0].toLowerCase() + device.substr(1);
      }
      tail = this.normalizeArray(tail.split(/[\\\/]+/).filter(function(p) {
        return !!p;
      }), !isAbsolute).join('\\');
      if (!tail && !isAbsolute) {
        tail = '.';
      }
      if (tail && trailingSlash) {
        tail += '\\';
      }
      if (isUnc) {
        device = this.normalizeUNCRoot(device);
      }
      return device + (isAbsolute ? '\\' : '') + tail;
    };

    Helpers.normalizePathPosix = function(path) {
      var i, isAbsolute, nonEmptySegments, segments, trailingSlash;
      isAbsolute = this.isAbsolutePosix(path);
      trailingSlash = path[path.length - 1] === '/';
      segments = path.split('/');
      nonEmptySegments = [];
      i = 0;
      while (i < segments.length) {
        if (segments[i]) {
          nonEmptySegments.push(segments[i]);
        }
        i++;
      }
      path = this.normalizeArray(nonEmptySegments, !isAbsolute).join('/');
      if (!path && !isAbsolute) {
        path = '.';
      }
      if (path && trailingSlash) {
        path += '/';
      }
      return (isAbsolute ? '/' : '') + path;
    };

    Helpers.isAbsoluteWindows = function(path) {
      var device, isUnc, result;
      result = this.splitDeviceRe.exec(path);
      device = result[1] || '';
      isUnc = device && device.charAt(1) !== ':';
      return !!result[2] || isUnc;
    };

    Helpers.isAbsolutePosix = function(path) {
      return path.charAt(0) === '/';
    };

    return Helpers;

  })();

  module.exports = Helpers;

}).call(this);