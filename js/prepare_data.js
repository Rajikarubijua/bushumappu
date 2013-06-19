// Generated by CoffeeScript 1.6.2
(function() {
  var __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  define(['utils'], function(_arg) {
    var P, getRadicalVector, setupClusterAssignment, setupKanjiGrades, setupKanjiVectors, setupRadicalJouyous;

    P = _arg.P;
    setupRadicalJouyous = function() {
      var jouyou_kanjis, k, kanjis, radical, _i, _len, _ref;

      jouyou_kanjis = [];
      _ref = my.jouyou_radicals;
      for (radical in _ref) {
        kanjis = _ref[radical];
        kanjis = (function() {
          var _i, _len, _results;

          _results = [];
          for (_i = 0, _len = kanjis.length; _i < _len; _i++) {
            k = kanjis[_i];
            _results.push(my.kanjis[k]);
          }
          return _results;
        })();
        my.radicals[radical].jouyou = kanjis;
        for (_i = 0, _len = kanjis.length; _i < _len; _i++) {
          k = kanjis[_i];
          if (__indexOf.call(jouyou_kanjis, k) < 0) {
            jouyou_kanjis.push(k);
          }
        }
      }
      return jouyou_kanjis;
    };
    setupKanjiGrades = function() {
      var grade, kanji, kanjis, _ref, _results;

      _ref = my.jouyou_grade;
      _results = [];
      for (grade in _ref) {
        kanjis = _ref[grade];
        _results.push((function() {
          var _i, _len, _results1;

          _results1 = [];
          for (_i = 0, _len = kanjis.length; _i < _len; _i++) {
            kanji = kanjis[_i];
            _results1.push(my.kanjis[kanji].grade = +grade);
          }
          return _results1;
        })());
      }
      return _results;
    };
    setupKanjiVectors = function(kanjis, radicals) {
      var kanji, radical, radical_i, vectors, _i, _len, _results;

      vectors = [];
      _results = [];
      for (_i = 0, _len = kanjis.length; _i < _len; _i++) {
        kanji = kanjis[_i];
        vectors.push(kanji.vector = []);
        _results.push((function() {
          var _j, _len1, _ref, _results1;

          _results1 = [];
          for (radical_i = _j = 0, _len1 = radicals.length; _j < _len1; radical_i = ++_j) {
            radical = radicals[radical_i];
            _results1.push(kanji.vector[radical_i] = +(_ref = radical.radical, __indexOf.call(kanji.radicals, _ref) >= 0));
          }
          return _results1;
        })());
      }
      return _results;
    };
    getRadicalVector = function(char, radicals) {
      var radical, radical_i, vector, _i, _len, _ref;

      vector = [];
      if (char.radical) {
        vector = (function() {
          var _i, _ref, _results;

          _results = [];
          for (_i = 0, _ref = radicals.length; 0 <= _ref ? _i < _ref : _i > _ref; 0 <= _ref ? _i++ : _i--) {
            _results.push(0);
          }
          return _results;
        })();
        vector[radicals.indexOf(char)] = 1;
      } else if (char.kanji) {
        for (radical_i = _i = 0, _len = radicals.length; _i < _len; radical_i = ++_i) {
          radical = radicals[radical_i];
          vector[radical_i] = +(_ref = radical.radical, __indexOf.call(char.radicals, _ref) >= 0);
        }
      }
      return vector;
    };
    setupClusterAssignment = function(nodes, initial_vectors, clusters_n) {
      var assignment, assignment_i, assignments, centroid, centroids, cluster, clusters, n, node, vectors, _i, _len, _ref;

      vectors = (function() {
        var _i, _len, _results;

        _results = [];
        for (_i = 0, _len = nodes.length; _i < _len; _i++) {
          n = nodes[_i];
          _results.push(n.vector);
        }
        return _results;
      })();
      if (__indexOf.call(vectors, void 0) >= 0) {
        throw "node need .vector";
      }
      if (clusters_n == null) {
        clusters_n = initial_vectors != null ? initial_vectors.length : void 0;
      }
      if (clusters_n == null) {
        clusters_n = Math.floor(Math.sqrt(nodes.length / 2));
      }
      _ref = figue.kmeans(clusters_n, vectors, initial_vectors), centroids = _ref.centroids, assignments = _ref.assignments;
      clusters = (function() {
        var _i, _len, _results;

        _results = [];
        for (_i = 0, _len = centroids.length; _i < _len; _i++) {
          centroid = centroids[_i];
          _results.push({
            centroid: centroid,
            nodes: []
          });
        }
        return _results;
      })();
      for (assignment_i = _i = 0, _len = assignments.length; _i < _len; assignment_i = ++_i) {
        assignment = assignments[assignment_i];
        cluster = clusters[assignment];
        node = nodes[assignment_i];
        node.cluster = cluster;
        cluster.nodes.push(node);
      }
      return clusters;
    };
    return {
      setupRadicalJouyous: setupRadicalJouyous,
      setupKanjiGrades: setupKanjiGrades,
      setupKanjiVectors: setupKanjiVectors,
      setupClusterAssignment: setupClusterAssignment,
      getRadicalVector: getRadicalVector
    };
  });

}).call(this);

/*
//@ sourceMappingURL=prepare_data.map
*/
