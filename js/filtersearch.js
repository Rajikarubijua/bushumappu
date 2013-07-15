// Generated by CoffeeScript 1.6.2
(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  define(['utils'], function(_arg) {
    var FilterSearch, InputHandler, P;

    P = _arg.P;
    FilterSearch = (function() {
      function FilterSearch() {}

      FilterSearch.prototype.setup = function(view, isInitial) {
        this.view = view;
        if (this.view.graph === void 0 || isInitial) {
          this.kanjis = this.view.kanjis;
        } else {
          this.kanjis = this.view.graph.kanjis();
        }
        if (isInitial == null) {
          isInitial = false;
        }
        this.inHandler = new InputHandler({
          kanjis: this.kanjis
        });
        this.inHandler.fillStandardInput('', true);
        this.inHandler.setupFilterSearchEvents(this, isInitial);
        if (isInitial) {
          this.inHandler.renderKanjiList();
        }
        if (isInitial) {
          return this.inHandler.reloadInitialSwitch(this);
        }
      };

      FilterSearch.prototype.filter = function(graph) {
        var criteria, edge, nearHidden, node, _i, _j, _len, _len1, _ref, _ref1;

        criteria = this.inHandler.getInputData();
        _ref = graph.nodes;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          node = _ref[_i];
          if (this.isWithinCriteria(node.data, criteria)) {
            node.style.filtered = false;
          } else {
            node.style.filtered = true;
          }
        }
        _ref1 = graph.edges;
        for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
          edge = _ref1[_j];
          nearHidden = edge.source.style.filtered || edge.target.style.filtered;
          if (nearHidden) {
            edge.style.filtered = true;
          }
        }
        return this.view.update();
      };

      FilterSearch.prototype.search = function(graph) {
        var criteria, node, searchresult, _i, _len, _ref;

        searchresult = [];
        criteria = this.inHandler.getInputData();
        _ref = graph.nodes;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          node = _ref[_i];
          node.style.isSearchresult = false;
          if (this.isWithinCriteria(node.data, criteria)) {
            node.style.isSearchresult = true;
            searchresult.push(node);
          }
        }
        this.view.update();
        return searchresult;
      };

      FilterSearch.prototype.update = function() {
        var criteria, k, searchresult, _i, _len, _ref;

        searchresult = [];
        criteria = this.inHandler.getInputData();
        _ref = this.kanjis;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          k = _ref[_i];
          if (this.isWithinCriteria(k, criteria)) {
            searchresult.push(k);
          }
        }
        this.inHandler.renderKanjiList(searchresult);
        return this.inHandler.reloadInitialSwitch(this);
      };

      FilterSearch.prototype.resetFilter = function(id) {
        return this.inHandler.fillStandardInput(id);
      };

      FilterSearch.prototype.resetAll = function(graph) {
        var edge, node, _i, _j, _len, _len1, _ref, _ref1;

        _ref = graph.nodes;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          node = _ref[_i];
          node.style.isSearchresult = false;
          node.style.filtered = false;
        }
        _ref1 = graph.edges;
        for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
          edge = _ref1[_j];
          edge.style.isSearchresult = false;
          edge.style.filtered = false;
        }
        this.inHandler.clearInput();
        this.inHandler.clearSearchResult();
        return this.view.update();
      };

      FilterSearch.prototype.autoFocus = function(kanji) {
        return this.view.autoFocus(kanji);
      };

      FilterSearch.prototype.isWithinCriteria = function(kanji, criteria) {
        var frqMax, frqMin, gradeMax, gradeMin, inKanji, inKun, inMean, inOn, strokeMax, strokeMin, withinFrq, withinGrade, withinInKanji, withinInKun, withinInMean, withinInOn, withinStroke;

        strokeMin = criteria.strokeMin, strokeMax = criteria.strokeMax, frqMin = criteria.frqMin, frqMax = criteria.frqMax, gradeMin = criteria.gradeMin, gradeMax = criteria.gradeMax, inKanji = criteria.inKanji, inOn = criteria.inOn, inKun = criteria.inKun, inMean = criteria.inMean;
        withinStroke = kanji.stroke_n >= strokeMin && kanji.stroke_n <= strokeMax;
        withinFrq = kanji.freq <= frqMin && kanji.freq >= frqMax;
        withinGrade = kanji.grade >= gradeMin && kanji.grade <= gradeMax;
        withinInKanji = this.check(kanji.kanji, inKanji);
        withinInOn = this.check(kanji.onyomi, inOn);
        withinInKun = this.check(kanji.kunyomi, inKun);
        withinInMean = this.check(kanji.meaning, inMean);
        return withinStroke && withinFrq && withinGrade && withinInKanji && withinInOn && withinInKun && withinInMean;
      };

      FilterSearch.prototype.check = function(arrValueData, arrFieldData) {
        var item, token_dt, token_jp, value, _i, _j, _len, _len1;

        if (arrFieldData === void 0 || arrFieldData === '') {
          return true;
        }
        if (arrValueData === void 0) {
          return false;
        }
        token_jp = '、';
        token_dt = ',';
        if (arrValueData.indexOf(token_jp) === -1) {
          arrValueData = arrValueData.split(token_dt);
        } else {
          arrValueData = arrValueData.split(token_jp);
        }
        if (arrFieldData.indexOf(token_jp) === -1) {
          arrFieldData = arrFieldData.split(token_dt);
        } else {
          arrFieldData = arrFieldData.split(token_jp);
        }
        for (_i = 0, _len = arrFieldData.length; _i < _len; _i++) {
          item = arrFieldData[_i];
          for (_j = 0, _len1 = arrValueData.length; _j < _len1; _j++) {
            value = arrValueData[_j];
            if (item !== '' && value.indexOf(item)) {
              return true;
            }
          }
        }
        return false;
      };

      return FilterSearch;

    })();
    InputHandler = (function() {
      function InputHandler(_arg1) {
        this.kanjis = _arg1.kanjis;
        this.reloadInitialSwitch = __bind(this.reloadInitialSwitch, this);
      }

      InputHandler.prototype.displayResult = function(result, length) {
        var i, node, resultString, _i, _len;

        if (length == null) {
          length = 7;
        }
        resultString = '';
        i = 0;
        for (_i = 0, _len = result.length; _i < _len; _i++) {
          node = result[_i];
          if (i === length) {
            resultString = "" + resultString + " <span class=lower> [...] </span>";
            break;
          }
          i++;
          resultString = "" + resultString + " <div class='searchKanji'>" + node.data.kanji + "</div>";
        }
        if (resultString === '') {
          resultString = 'nothing found in current view';
        }
        d3.select('#kanjiresultCount')[0][0].innerHTML = "" + result.length + " found";
        return d3.select('#kanjiresult')[0][0].innerHTML = "" + resultString;
      };

      InputHandler.prototype.renderKanjiList = function(arrKanjis) {
        var count, k, list, _i, _len;

        if (arrKanjis == null) {
          arrKanjis = this.kanjis;
        }
        list = '';
        count = '';
        for (_i = 0, _len = arrKanjis.length; _i < _len; _i++) {
          k = arrKanjis[_i];
          list = "" + list + " <div class='searchKanji'>" + k.kanji + "</div>";
        }
        if (list === '') {
          count = 'no kanji found';
        } else {
          count = "<div> " + arrKanjis.length + " kanji have been found. </div>";
        }
        d3.select('#kanjicount').node().innerHTML = count;
        return d3.select('#kanjilist').node().innerHTML = list;
      };

      InputHandler.prototype.fillStandardInput = function(id, flag) {
        if (flag == null) {
          flag = false;
        }
        if (id === 'btn_clear1' || flag) {
          this.fillInputData('#count_min', 1);
          this.fillInputData('#count_max', this.getStrokeCountMax(this.kanjis));
        }
        if (id === 'btn_clear2' || flag) {
          this.fillInputData('#frq_min', this.getFreqMax(this.kanjis));
          this.fillInputData('#frq_max', 1);
        }
        if (id === 'btn_clear3' || flag) {
          this.fillInputData('#grade_min', 1);
          return this.fillInputData('#grade_max', Object.keys(my.jouyou_grade).length);
        }
      };

      InputHandler.prototype.fillSeaFilTest = function() {
        this.fillStandardInput('', true);
        this.fillInputData('#kanjistring', '日,木,森');
        this.fillInputData('#onyomistring', 'ニチ');
        this.fillInputData('#kunyomistring', 'ひ,き');
        return this.fillInputData('#meaningstring', 'day');
      };

      InputHandler.prototype.clearInput = function() {
        this.fillStandardInput('', true);
        this.fillInputData('#kanjistring', '');
        this.fillInputData('#onyomistring', '');
        this.fillInputData('#kunyomistring', '');
        return this.fillInputData('#meaningstring', '');
      };

      InputHandler.prototype.clearSearchResult = function() {
        d3.select('#kanjiresult')[0][0].innerHTML = '';
        return d3.select('#kanjiresultCount')[0][0].innerHTML = "";
      };

      InputHandler.prototype.fillInputData = function(id, value) {
        var path;

        path = "form " + id;
        return d3.selectAll(path).property('value', value);
      };

      InputHandler.prototype.getInputInt = function(id) {
        var path;

        path = "form " + id;
        return +d3.selectAll(path).property('value').trim();
      };

      InputHandler.prototype.getInput = function(id) {
        var path;

        path = "form " + id;
        return d3.selectAll(path).property('value').trim();
      };

      InputHandler.prototype.getInputData = function() {
        return {
          strokeMin: this.getInputInt('#count_min'),
          strokeMax: this.getInputInt('#count_max'),
          frqMin: this.getInputInt('#frq_min'),
          frqMax: this.getInputInt('#frq_max'),
          gradeMin: this.getInputInt('#grade_min'),
          gradeMax: this.getInputInt('#grade_max'),
          inKanji: this.getInput('#kanjistring'),
          inOn: this.getInput('#onyomistring'),
          inKun: this.getInput('#kunyomistring'),
          inMean: this.getInput('#meaningstring')
        };
      };

      InputHandler.prototype.getStrokeCountMax = function(kanjis) {
        var kanji, max, _i, _len;

        max = 1;
        for (_i = 0, _len = kanjis.length; _i < _len; _i++) {
          kanji = kanjis[_i];
          if (kanji.stroke_n > max) {
            max = kanji.stroke_n;
          }
        }
        return max;
      };

      InputHandler.prototype.getFreqMax = function(kanjis) {
        var kanji, max, _i, _len;

        max = 1;
        for (_i = 0, _len = kanjis.length; _i < _len; _i++) {
          kanji = kanjis[_i];
          if (kanji.freq > max) {
            max = kanji.freq;
          }
        }
        return max;
      };

      InputHandler.prototype.setupFilterSearchEvents = function(filsea, isInitial) {
        var autoFocus, filter, resetAll, resetFilter, search, update;

        filter = function() {
          return filsea.filter(filsea.view.graph);
        };
        autoFocus = function() {
          var kanji;

          kanji = d3.event.srcElement.innerHTML;
          return filsea.autoFocus(kanji);
        };
        search = function() {
          var result;

          result = filsea.search(filsea.view.graph);
          filsea.inHandler.displayResult(result);
          return d3.selectAll('#kanjiresult .searchKanji').on('click', autoFocus);
        };
        resetFilter = function() {
          filsea.resetFilter(d3.event.srcElement.id);
          if (isInitial) {
            return filsea.update();
          }
        };
        resetAll = function() {
          return filsea.resetAll(filsea.view.graph);
        };
        update = function() {
          return filsea.update();
        };
        d3.selectAll('#btn_clear1').on('click', resetFilter);
        d3.selectAll('#btn_clear2').on('click', resetFilter);
        d3.selectAll('#btn_clear3').on('click', resetFilter);
        if (!isInitial) {
          d3.select('#btn_filter').on('click', filter);
          d3.select('#btn_search').on('click', search);
          return d3.select('#btn_reset').on('click', resetAll);
        } else {
          return d3.selectAll('#overlay form input[type=text]').on('change', update);
        }
      };

      InputHandler.prototype.reloadInitialSwitch = function(filsea) {
        var switchToMain,
          _this = this;

        switchToMain = function() {
          var strKanji;

          d3.select('#overlay').remove();
          strKanji = d3.event.srcElement.innerHTML;
          filsea.view.changeToCentralFromStr(strKanji);
          return _this.setupFilterSearchEvents(filsea, false);
        };
        return d3.selectAll('#overlay .searchKanji').on('click', switchToMain);
      };

      return InputHandler;

    })();
    return {
      FilterSearch: FilterSearch
    };
  });

}).call(this);

/*
//@ sourceMappingURL=filtersearch.map
*/
