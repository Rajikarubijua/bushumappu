// Generated by CoffeeScript 1.8.0
(function() {
  var __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  define('detail_table', ['utils'], function(_arg) {
    var DetailTable, P, arrayUnique;
    P = _arg.P, arrayUnique = _arg.arrayUnique;
    DetailTable = (function() {
      function DetailTable() {
        this.list = [];
      }

      DetailTable.prototype.addKanji = function(kanji) {
        if (__indexOf.call(this.list, kanji) < 0) {
          this.list.unshift(kanji);
          this.list = arrayUnique(this.list);
          return this.render();
        } else {
          return P("cannot add: kanji is already in table");
        }
      };

      DetailTable.prototype.removeKanji = function(kanji) {
        var k, newlist, _i, _j, _len, _len1, _ref, _ref1;
        _ref = this.list;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          k = _ref[_i];
          if (k.kanji === kanji) {
            kanji = k;
          }
        }
        if (__indexOf.call(this.list, kanji) >= 0) {
          newlist = [];
          _ref1 = this.list;
          for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
            k = _ref1[_j];
            if (k.kanji !== kanji.kanji) {
              newlist.push(k);
            }
          }
          this.list = newlist;
          return this.render();
        } else {
          return P("cannot remove: kanji is not in table");
        }
      };

      DetailTable.prototype.render = function() {
        var k, r, radicals, table, table_data, table_td, table_tr, _i, _len, _ref;
        table = d3.select('table#details tbody');
        table_data = [[], [], [], [], []];
        table.selectAll('td.content').remove();
        _ref = this.list;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          k = _ref[_i];
          radicals = (function() {
            var _j, _len1, _ref1, _results;
            _ref1 = k.radicals;
            _results = [];
            for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
              r = _ref1[_j];
              _results.push(r.radical);
            }
            return _results;
          })();
          table_data[0].push(k.kanji);
          table_data[1].push(k.meaning);
          table_data[2].push(radicals);
          table_data[3].push(k.onyomi);
          table_data[4].push(k.kunyomi);
        }
        table_tr = table.selectAll('tr').data(table_data);
        table_td = table_tr.selectAll('td.content').data(function(d) {
          return d;
        });
        table_tr.enter().append('tr').classed('content', true);
        table_td.enter().append('td').classed("content", true);
        table_td.text(function(d) {
          return d;
        });
        return this.updateListener();
      };

      DetailTable.prototype.updateListener = function() {
        var clearFuncTimer, colLabels, displayDeleteTableCol, me, setFuncTimer, table;
        me = this;
        setFuncTimer = function(obj, ms, func) {
          return obj.funcTimer = setTimeout((function(d) {
            return func(d);
          }), ms);
        };
        clearFuncTimer = function(obj) {
          clearTimeout(obj.funcTimer);
          return obj.funcTimer = null;
        };
        displayDeleteTableCol = function(d) {
          var removeBtn;
          if (d === void 0) {
            return;
          }
          if (d3.select(this).selectAll('g')[0].length !== 0) {
            return;
          }
          removeBtn = d3.select(this).append('g').classed('remove-col-btn', true);
          removeBtn.append('text').text('X');
          removeBtn.on('click.removeTableCol', function(d) {
            me.removeKanji(d);
            return d3.event.stopPropagation();
          });
          return this.removeBtn = removeBtn;
        };
        table = d3.select('table#details tbody');
        return colLabels = table.select('tr').selectAll('td').on('mouseenter.hoverLabel', function(d) {
          var that;
          that = this;
          return setFuncTimer(that, 500, function() {
            return displayDeleteTableCol.call(that, d);
          });
        }).on('mouseleave.resetHoverLabel', function(d) {
          clearFuncTimer(this);
          return d3.select(d3.event.srcElement.childNodes[1]).remove();
        });
      };

      return DetailTable;

    })();
    return {
      DetailTable: DetailTable
    };
  });

}).call(this);

//# sourceMappingURL=detail_table.js.map
