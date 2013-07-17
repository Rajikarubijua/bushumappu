Entwicklungsumgebung, genereller Aufbau, Aufbau vom View im Detail, Optimierung vom Layout

# Entwicklungsumgebung
* [CoffeeScript 1.6.2](http://coffeescript.org/)
* [Chromium 28](http://www.chromium.org/Home), [SVG 1.1](http://www.w3.org/TR/SVG11/) und [CSS 2010](http://www.w3.org/TR/css-2010/)
* [d3.js 3.1.6](http://d3js.org/)
* [require.js 2.1.6](http://requirejs.org/)
* [GNU Make 3.81](https://www.gnu.org/software/make/)
* [reactor.js commit cdbf994](https://github.com/fynyky/reactor.js)

# Aufbau

* krad, radk, jouyou, kext

                  ↓ config ↓
* load → parse → prepare → kanjis, radicals → view

## View
* [selection.data](https://github.com/mbostock/d3/wiki/Selections#wiki-data)
* General Update Pattern, Parts I, II & III in [Tutorials](https://github.com/mbostock/d3/wiki/Tutorials)

* update
* updateNodes, enterNodes detailTable
* updateEdges, mini-labels, tubes is hidden in edge.coords()
* updateStationLabels
* updateCentralNode

### changeToCentral
* history
* embedder → optimizer
* configures search and filter
* update is called when optimizer posts node positions

# Optimierung vom Layout
* runs in own [Worker](http://www.whatwg.org/specs/web-apps/current-work/multipage/workers.html)
* snapNodes
* applyRules

* Nimm einen Node, berechne Qualität des Graphen für die aktuelle Position des Nodes und für Fälle, in denen der Node eine Position in der Umgebung angenommen hätte. Wähle die Position, bei der die Qualität des Graphen am größten war und setze den Node entsprechend.

## Qualität des Graphen
* ruleViolations und critQuality
* wrongEdgesUnderneath
* edgeCrossings
* lineStraightness
* lengthOfEdges
* tooNearCentralNode

