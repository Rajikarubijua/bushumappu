// Generated by CoffeeScript 1.8.0
(function() {
  var __slice = [].slice,
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; },
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  define("utils", function() {
    var Memo, P, PD, PN, W, angleBetween01, arrayUnique, async, compareNumber, consecutivePairs, copyAttrs, cssTranslateXY, distToSegment01, distToSegmentSqrXY, distToSegmentXY, distance01, distanceSqr01, distanceSqrXY, distanceXY, equidistantSelection, expect, extremaFunc, forall, getMinMax, groupBy, length, max, min, nearest, nearest01, nearestXY, parseMaybeNumber, prettyDebug, rasterCircle, somePrettyPrint, sort, sortSomewhat, strUnique, styleZoom, sunflower, vec, vecX, vecY;
    copyAttrs = function() {
      var a, b, bs, k, v, _i, _len;
      a = arguments[0], bs = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      for (_i = 0, _len = bs.length; _i < _len; _i++) {
        b = bs[_i];
        for (k in b) {
          v = b[k];
          a[k] = v;
        }
      }
      return a;
    };
    P = function() {
      var args;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      console.log.apply(console, args);
      return args.slice(-1)[0];
    };
    PN = function() {
      var args;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      console.log.apply(console, args.slice(0, -1));
      return args.slice(-1)[0];
    };
    PD = function() {
      var args, str;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      str = prettyDebug(args);
      if (my.debug) {
        console.debug(str);
      }
      return args.slice(-1)[0];
    };
    prettyDebug = function(x, known, depth) {
      var k, s, v, y, _ref;
      if (known == null) {
        known = [];
      }
      if (depth == null) {
        depth = 0;
      }
      if (__indexOf.call(known, x) >= 0) {
        return '###';
      } else if ((_ref = typeof x) === 'undefined' || _ref === 'boolean') {
        return '' + x;
      } else if (typeof x === 'string') {
        if (depth <= 1) {
          return x;
        } else {
          return '"' + x + '"';
        }
      } else if (typeof x === 'number') {
        return x = "" + (0.01 * Math.round(x * 100));
      } else if (typeof x === 'function') {
        return ("" + x).split('{')[0];
      } else if (Array.isArray(x)) {
        known.push(x);
        s = depth === 0 ? ' ' : ',';
        x = ((function() {
          var _i, _len, _results;
          _results = [];
          for (_i = 0, _len = x.length; _i < _len; _i++) {
            y = x[_i];
            _results.push(prettyDebug(y, known, depth + 1));
          }
          return _results;
        })()).join(s);
        if (depth === 0) {
          return x;
        } else {
          return '[' + x + ']';
        }
      } else {
        known.push(x);
        x = ((function() {
          var _results;
          _results = [];
          for (k in x) {
            v = x[k];
            v = prettyDebug(v, known, depth + 1);
            _results.push(k + ':' + v);
          }
          return _results;
        })()).join(',');
        return '{' + x + '}';
      }
    };
    W = function(width, str, fill) {
      str = "" + str;
      if (fill == null) {
        fill = " ";
      }
      width = Math.max(str.length, width);
      return str + ((function() {
        var _i, _ref, _results;
        _results = [];
        for (_i = 1, _ref = width - str.length; 1 <= _ref ? _i <= _ref : _i >= _ref; 1 <= _ref ? _i++ : _i--) {
          _results.push(fill);
        }
        return _results;
      })()).join('');
    };
    async = {
      parallel: function(funcs, cb) {
        var end, func, i, k, o, results, _i, _len, _results;
        results = [];
        i = funcs.length;
        end = function() {
          var args;
          args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
          results.push(args);
          if (--i === 0) {
            return cb(results);
          }
        };
        _results = [];
        for (_i = 0, _len = funcs.length; _i < _len; _i++) {
          func = funcs[_i];
          if (typeof func === "function") {
            _results.push(func(end));
          } else {
            o = func[0], k = func[1];
            _results.push(o[k] = end);
          }
        }
        return _results;
      },
      map: function(mapped, cb) {
        var end, func, label, mapped_n, results, _results;
        mapped_n = (Object.keys(mapped)).length;
        results = {};
        end = function(label) {
          return function() {
            var args;
            args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
            results[label] = args;
            if ((Object.keys(results)).length === mapped_n) {
              return cb(results);
            }
          };
        };
        _results = [];
        for (label in mapped) {
          func = mapped[label];
          _results.push(func(end(label)));
        }
        return _results;
      },
      seqTimeout: function() {
        var func, funcs, i, iter, timeout;
        timeout = arguments[0], funcs = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
        funcs = (function() {
          var _i, _len, _results;
          _results = [];
          for (_i = 0, _len = funcs.length; _i < _len; _i++) {
            func = funcs[_i];
            if (func) {
              _results.push(func);
            }
          }
          return _results;
        })();
        i = 0;
        iter = function() {
          return setTimeout((function() {
            return funcs[i++]((function() {
              if (i < funcs.length) {
                return iter();
              }
            }));
          }), timeout);
        };
        return iter();
      }
    };
    strUnique = function(str, base) {
      var c, _i, _len;
      if (base == null) {
        base = "";
      }
      for (_i = 0, _len = str.length; _i < _len; _i++) {
        c = str[_i];
        if (__indexOf.call(base, c) < 0) {
          base += c;
        }
      }
      return base;
    };
    arrayUnique = function(array, base) {
      var e, _i, _len;
      if (base == null) {
        base = [];
      }
      for (_i = 0, _len = array.length; _i < _len; _i++) {
        e = array[_i];
        if (__indexOf.call(base, e) < 0) {
          base.push(e);
        }
      }
      return base;
    };
    expect = function(regex, line, i) {
      var m;
      m = line.match(regex);
      if (m === null) {
        throw "expected " + regex + " at " + i;
      }
      return m;
    };
    somePrettyPrint = function(o) {
      var firstColumnWidth, k, lines, v, w;
      w = firstColumnWidth = 30;
      lines = (function() {
        var _i, _len, _ref, _results;
        _ref = (Object.keys(o)).sort();
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          k = _ref[_i];
          v = o[k];
          if (Array.isArray(v)) {
            k = W(w, "[" + k + "]");
            v = v.length;
          } else if (typeof v === 'object') {
            k = W(w, "{" + k + "}");
            v = (Object.keys(v)).length;
          } else {
            k = W(w, " " + k + " ");
            v = JSON.stringify(v);
          }
          _results.push(k + " " + v);
        }
        return _results;
      })();
      return lines.join("\n");
    };
    length = function(x) {
      if (x.length != null) {
        return x.length;
      }
      return (Object.keys(x)).length;
    };
    sort = function() {
      var args, x, _ref, _ref1;
      x = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      if ('sort' in x) {
        return x.sort.apply(x, args);
      }
      if (typeof x === 'string') {
        return (_ref = x.split('')).sort.apply(_ref, args).join('');
      }
      if (typeof x === 'object') {
        return (_ref1 = Object.keys(x)).sort.apply(_ref1, args);
      }
      throw "invalid argument ps type " + (typeof x);
    };
    compareNumber = function(a, b) {
      return -(a < b) || a > b || 0;
    };
    styleZoom = function(el, zoom, dontCall) {
      var func;
      func = function() {
        var t, z;
        t = zoom.translate();
        z = zoom.scale();
        return el.attr('style', "-webkit-transform: translate(" + t[0] + "px, " + t[1] + "px) scale(" + z + ")");
      };
      if (!dontCall) {
        func();
      }
      return func;
    };
    sunflower = function(_arg) {
      var a, factor, index, r, x, y;
      index = _arg.index, factor = _arg.factor, x = _arg.x, y = _arg.y;
      if (index == null) {
        throw "missing index";
      }
      if (factor == null) {
        throw "missing factor";
      }
      if (x == null) {
        x = 0;
      }
      if (y == null) {
        y = 0;
      }
      a = index * 55 / 144 * 2 * Math.PI;
      r = factor * Math.sqrt(index);
      x += r * Math.cos(a);
      y += r * Math.sin(a);
      return {
        x: x,
        y: y
      };
    };
    vecX = function(r, angle) {
      return r * Math.cos(angle);
    };
    vecY = function(r, angle) {
      return r * Math.sin(angle);
    };
    vec = function(r, angle) {
      return [vecX(r, angle), vecY(r, angle)];
    };
    parseMaybeNumber = function(str) {
      if (("" + (+str)) === str) {
        return +str;
      } else {
        return str;
      }
    };
    equidistantSelection = function(n, array, _arg) {
      var i, offset, step, _i, _results;
      offset = (_arg != null ? _arg : {}).offset;
      if (offset == null) {
        offset = 0;
      }
      step = Math.floor(array.length / n);
      _results = [];
      for (i = _i = 0; 0 <= n ? _i < n : _i > n; i = 0 <= n ? ++_i : --_i) {
        _results.push(array[(offset + i * step) % array.length]);
      }
      return _results;
    };
    groupBy = function(array, func) {
      var element, groups, _i, _len, _name;
      groups = {};
      for (_i = 0, _len = array.length; _i < _len; _i++) {
        element = array[_i];
        (groups[_name = func(element)] != null ? groups[_name] : groups[_name] = []).push(element);
      }
      return groups;
    };
    getMinMax = function(array, map) {
      var element, func, key, max, min, result, value, _i, _len;
      map = copyAttrs({}, map);
      for (key in map) {
        func = map[key];
        if (typeof func === 'string') {
          map[key] = (function(func) {
            return function(x) {
              return x[func];
            };
          })(func);
        }
      }
      result = {};
      for (_i = 0, _len = array.length; _i < _len; _i++) {
        element = array[_i];
        for (key in map) {
          func = map[key];
          value = func(element);
          min = result["min_" + key];
          max = result["max_" + key];
          if ((min == null) || value < func(min)) {
            result["min_" + key] = element;
          }
          if ((max == null) || value > func(max)) {
            result["max_" + key] = element;
          }
        }
      }
      return result;
    };
    extremaFunc = function(comp) {
      return function(array, func) {
        var e, ex_e, ex_value, value, _i, _len;
        if (typeof func === 'string') {
          func = (function(func) {
            return function(x) {
              return x[func];
            };
          })(func);
        }
        ex_value = ex_e = void 0;
        for (_i = 0, _len = array.length; _i < _len; _i++) {
          e = array[_i];
          value = func(e);
          if ((typeof max_value === "undefined" || max_value === null) || comp(value, max_value)) {
            ex_value = value;
            ex_e = e;
          }
        }
        return ex_e;
      };
    };
    max = extremaFunc((function(a, b) {
      return a > b;
    }));
    min = extremaFunc((function(a, b) {
      return a < b;
    }));
    distanceSqrXY = function(a, b) {
      return Math.pow(b.x - a.x, 2) + Math.pow(b.y - a.y, 2);
    };
    distanceSqr01 = function(a, b) {
      return Math.pow(b[0] - a[0], 2) + Math.pow(b[1] - a[1], 2);
    };
    distanceXY = function(a, b) {
      return Math.sqrt(distanceSqrXY(a, b));
    };
    distance01 = function(a, b) {
      return Math.sqrt(distanceSqr01(a, b));
    };
    nearest = function(a, array, distanceFunc) {
      var b, d, i, min_d, min_i, _i, _len;
      min_d = 1 / 0;
      min_i = null;
      for (i = _i = 0, _len = array.length; _i < _len; i = ++_i) {
        b = array[i];
        d = distanceFunc(a, b);
        if (d < min_d) {
          min_d = d;
          min_i = i;
        }
      }
      return {
        b: array[min_i],
        i: min_i
      };
    };
    nearestXY = function(a, array) {
      return nearest(a, array, distanceSqrXY);
    };
    nearest01 = function(a, array) {
      return nearest(a, array, distanceSqr01);
    };
    forall = function(func) {
      return function(xs) {
        var x, _i, _len, _results;
        _results = [];
        for (_i = 0, _len = xs.length; _i < _len; _i++) {
          x = xs[_i];
          _results.push(func(x));
        }
        return _results;
      };
    };
    rasterCircle = function(x0, y0, r) {
      var ddF_x, ddF_y, f, pxs, x, y;
      f = 1 - r;
      ddF_x = 1;
      ddF_y = -2 * r;
      x = 0;
      y = r;
      pxs = [[x0, y0 + r], [x0, y0 - r], [x0 + r, y0], [x0 - r, y0]];
      while (x < y) {
        if (f >= 0) {
          --y;
          ddF_y += 2;
          f += ddF_y;
        }
        ++x;
        ddF_x += 2;
        f += ddF_x;
      }
      return pxs = pxs.concat([[x0 + x, y0 + y], [x0 - x, y0 + y], [x0 + x, y0 - y], [x0 - x, y0 - y], [x0 + y, y0 + x], [x0 - y, y0 + x], [x0 + y, y0 - x], [x0 - y, y0 - x]]);
    };
    sortSomewhat = function(xs, cmp) {
      var a, b, i, l, sorted, x, _i, _j, _len, _ref, _ref1, _ref2;
      xs = xs.slice(0);
      min = {
        x: xs[0],
        i: 0
      };
      for (i = _i = 0, _len = xs.length; _i < _len; i = ++_i) {
        x = xs[i];
        if ((cmp(x, min.x)) === -1) {
          min = {
            x: x,
            i: i
          };
        }
      }
      a = min.x;
      [].splice.apply(xs, [(_ref = min.i), min.i - _ref + 1].concat(_ref1 = [])), _ref1;
      sorted = [a];
      l = xs.length;
      while (xs.length) {
        for (_j = 0, _ref2 = xs.length; 0 <= _ref2 ? _j < _ref2 : _j > _ref2; 0 <= _ref2 ? _j++ : _j--) {
          b = xs.shift();
          if ((cmp(a, b)) === -1) {
            sorted.push(b);
            a = b;
          } else {
            xs.push(b);
          }
        }
        if (xs.length >= l) {
          P(sorted, xs);
          throw "not somewhat sortable";
        }
      }
      return sorted;
    };
    Memo = (function() {
      var memo_id;

      memo_id = 0;

      function Memo() {
        this.onceObj = __bind(this.onceObj, this);
        this.memo = {};
        this.memoId = "__memo" + (memo_id++) + "__";
        this.funcId = 0;
        this.objId = 0;
      }

      Memo.prototype.onceObj = function(func) {
        var func_id;
        func_id = "" + this.funcId++;
        return (function(_this) {
          return function(obj) {
            var memo, obj_id, value, _base, _name;
            obj_id = obj[_name = _this.memoId] != null ? obj[_name] : obj[_name] = "" + _this.objId++;
            memo = (_base = _this.memo)[obj_id] != null ? _base[obj_id] : _base[obj_id] = {};
            return value = memo[func_id] != null ? memo[func_id] : memo[func_id] = func(obj);
          };
        })(this);
      };

      return Memo;

    })();
    distToSegmentSqrXY = function(p, a, b) {
      var l2, t, vx, vy, x, y;
      if (!((p.x != null) && (p.y != null))) {
        throw "p wrong";
      }
      if (!((a.x != null) && (a.y != null))) {
        throw "a wrong";
      }
      if (!((b.x != null) && (b.y != null))) {
        throw "b wrong";
      }
      l2 = distanceSqrXY(a, b);
      if (l2 === 0) {
        return distanceSqrXY(p, a);
      }
      vx = b.x - a.x;
      vy = b.y - a.y;
      t = ((p.x - a.x) * vx + (p.y - a.y) * vy) / l2;
      if (t <= 0) {
        return distanceSqrXY(p, a);
      }
      if (t >= 1) {
        return distanceSqrXY(p, b);
      }
      x = a.x + t * vx;
      y = a.y + t * vy;
      return distanceSqrXY(p, {
        x: x,
        y: y
      });
    };
    distToSegmentXY = function(p, a, b) {
      return Math.sqrt(distToSegmentSqrXY(p, a, b));
    };
    cssTranslateXY = function(_arg) {
      var x, y;
      x = _arg.x, y = _arg.y;
      return "translate(" + x + " " + y + ")";
    };
    distToSegment01 = function(p, a, b) {
      p = {
        x: p[0],
        y: p[1]
      };
      a = {
        x: a[0],
        y: a[1]
      };
      b = {
        x: b[0],
        y: b[1]
      };
      return Math.sqrt(distToSegmentSqrXY(p, a, b));
    };
    consecutivePairs = function(array) {
      var a, b, pairs, _i, _len, _ref;
      if (array.length < 2) {
        throw 'array.length < 2';
      }
      pairs = [];
      a = array[0];
      _ref = array.slice(1);
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        b = _ref[_i];
        pairs.push([a, b]);
        a = b;
      }
      return pairs;
    };
    angleBetween01 = function(_arg, _arg1) {
      var angle, x, x1, x2, y, y1, y2;
      x1 = _arg[0], y1 = _arg[1];
      x2 = _arg1[0], y2 = _arg1[1];
      x = x2 - x1;
      y = y2 - y1;
      return angle = Math.atan2(y, x);
    };
    return {
      copyAttrs: copyAttrs,
      P: P,
      PN: PN,
      PD: PD,
      W: W,
      async: async,
      strUnique: strUnique,
      expect: expect,
      somePrettyPrint: somePrettyPrint,
      length: length,
      sort: sort,
      styleZoom: styleZoom,
      sunflower: sunflower,
      vecX: vecX,
      vecY: vecY,
      vec: vec,
      compareNumber: compareNumber,
      max: max,
      min: min,
      parseMaybeNumber: parseMaybeNumber,
      equidistantSelection: equidistantSelection,
      getMinMax: getMinMax,
      arrayUnique: arrayUnique,
      distanceSqrXY: distanceSqrXY,
      nearestXY: nearestXY,
      nearest01: nearest01,
      distanceSqr01: distanceSqr01,
      nearest: nearest,
      forall: forall,
      rasterCircle: rasterCircle,
      prettyDebug: prettyDebug,
      sortSomewhat: sortSomewhat,
      Memo: Memo,
      distanceXY: distanceXY,
      distance01: distance01,
      distToSegmentXY: distToSegmentXY,
      distToSegmentSqrXY: distToSegmentSqrXY,
      cssTranslateXY: cssTranslateXY,
      consecutivePairs: consecutivePairs,
      distToSegment01: distToSegment01,
      angleBetween01: angleBetween01
    };
  });

}).call(this);

//# sourceMappingURL=utils.js.map
