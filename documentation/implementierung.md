# Implementierung

Die Software ist eine vollständig Client-seitige Webanwendung. Diese Entscheidung wurde in Abwägung gegenüber C++ mit Qt 5 getroffen.
Ausschlaggebende Argumente waren die Verfügbarkeit von CSS und SVG zur Darstellung im Gegensatz zu imperativen und Objekt-orientierten Ansätzen sowie das einfache Zeigen und Teilen mit anderen Menschen über einen Link und einen Browser.

## Entwicklungsumgebung

Mit der Entscheidung zur Webanwendung war die erste Frage, welche Programmiersprache die vorherrschende sein sollte. Zwischen JavaScript, CoffeeScript, Java und Haxe fiel die Wahl auf [CoffeeScript 1.6.2](http://coffeescript.org/). Stark typisierte Sprachen, die zu JavaScript compilieren, wie Java und Haxe, haben das Problem, dass JavaScript Bibliotheken wie d3.js, einen abschreckenden Aufwand erfordern, die Interfaces zu definieren, so dass der Vorteil der starken Typisierung auch genutzt werden kann. CoffeeScript ist JavaScript in sofern überlegen, da es ein Klassen-Pattern bereits in die Sprache integriert und auch vor anderen Unklarheiten in JavaScript schützt.

Zur Darstellung selbst wird [SVG 1.1](http://www.w3.org/TR/SVG11/) und [CSS 2010](http://www.w3.org/TR/css-2010/) verwendet, um mit Hilfe von CSS schnell schicke Effekte und Transitionen nach Bedarf zu definieren und sie vom Browser bereits effizient umgesetzt werden. CSS Effekte sind jedoch nur auf DOM Elemente anwendbar, was wiederum SVG verlangt als Darstellungsframework. [d3.js 3.1.6](http://d3js.org/) ist darauf ausgelegt DOM Elemente basierend auf Daten zu erstellen. Andere Darstellungsbibliotheken für Webanwendungen legen entweder ihren Fokus nicht auf SVG und CSS oder sind nicht Daten-gebunden.

Zwischen Firefox 23 und [Chromium 28](http://www.chromium.org/Home) fiel die Wahl auf letzteren, da der Chromium SVG mit Text effizient darstellt. Der Firefox stößt hier an eine Grenze.

Weitere verwendete Technologien sind [require.js 2.1.6](http://requirejs.org/) um die Software in Module zu teilen, [reactor.js commit cdbf994](https://github.com/fynyky/reactor.js) als marginale Abhängigkeit, die lediglich für einen simplen Fall mal ausprobiert wurde, [GNU Make 3.81](https://www.gnu.org/software/make/) um typische Entwicklungsprozesse zu automatisieren und [Python 3.2.3](http://python.org/) als lokaler Webserver.

## Tubemap Layout

Die Software für ein ansehnliches Layout für die Tubemap zu implementieren, gestaltete sich als sehr schwierig. Die Doktorarbeit von \cite{automaticlayoutmetro08} nahmen wir als Inspiration, jedoch eignete sich diese Arbeit lediglich für einen groben Ansatz. Im Detail mussten viele andere Entscheidungen getroffen werden und andere Ansätze ausprobiert werden.

Prinzipiell besteht der Layout Prozess aus zwei Phasen. Zuerst wird eine initiale Einbettung bestimmt. Dabei sollen Positionen der Knoten bestimmt werden und wie diese untereinander verbunden sind. Danach wird der entstandene Graph optimiert. Dies geschieht durch eine kontinuierlich Bewertung und Veränderung um eine bessere Bewertung zu erzielen. Die Bewertung richtet sich nach mehreren Kriterien und Regeln.

Konkret ist das Ergebnis der initialen Einbettung, dass das zentrale Kanji in der Mitte ist. Die Radikale des zentralen Kanji werden hier als relevante Radikale bezeichnet. Von dem zentralen Kanji ausgehend, denkt man sich für jedes relvante Kanji Strahlen in 90° und 45° Winkel zueinander. Für jedes relevante Radikal werden die Kanji genommen, die dieses Radikal enthalten und eingeteilt in solche, die von allen relevanten Radikalen nur eins enthalten (Lo-Kanjis), und solche, die mehrere relevante Radikale enthalten (Hi-Kanjis). Hi-Kanjis werden unter den Strahlen verteilt, Lo-Kanjis am entprechenden Strahl hinten angefügt. Alle Kanjis haben nun eine Position. Um Kanjis mit einandner zu verbinden, wird Verbindungen nacheinander gezogen für jedes relevante Radikal. Vom zentralen Kanji aus werden alle Hi-Kanjis des zum Radikal zugehörigen Strahls verbunden und anschließend wird jeder Strahl durchgegangen and alle dortigen Hi-Kanjis, die das aktuelle Radikal enthalten, nacheinander verbunden. Zum Schluss wird noch eine Verbindung zu den dazugehörigen Lo-Kanjis gezogen.

Die initiale Einbettung ist ausgesprochen wichtig für eine erfolgreiche Optimierung. Die Optimierung nach mehreren Kriterien wird von \cite{automaticmetromap11} beschrieben. Ein Teil dieser Optimierung ist in der vorliegenden Software implementiert, jedoch in entscheidenden Aspekten abgeändert um schneller zu einem guten Ergebnis zu kommen, die Entwicklung zu vereinfachen und auf spezielle Bedürfnisse der Kanji-Tubemap einzugehen. Die Optimierung findet parallel in einem [Worker](http://www.whatwg.org/specthes/web-apps/current-work/multipage/workers.html) statt um die Interaktivität der Anwendung nicht zu behindern. Kontinuierlich wird ein Knoten im Graph ausgewählt und geprüft ob in der Umgebung eine Position für den Knoten ist, bei der die Bewertung des Graphen besser wird. In die Bewertung fließen Regeln und Qualitätskriterien ein. Weniger Regeln zu verletzen ist stets besser als eine höhere Qualität zu erreichen.

Folgende Regeln möglichst nicht verletzt werden:

* keine Kanten, die unter einem Knoten durchgehen, die nicht zu dem Knoten selbst gehören (`wrongEdgesUnderneath`)
* der Knoten darf dem Knoten für das zentral Kanji nicht zu Nahe kommen (`tooNearCentralNode`)
* keine Kanten, die andere Kanten kreuzen (`edgeCrossings`)

Folgende Qualitätskriterien flossen in die Version der Software ein, die zur finalen Präsentation gezeigt wurde:

* aneinander liegende Kanten sollen möglichst gerade sein (`lineStraightness`)
* Kanten sollen möglichst kurz sein (`lengthOfEdges`)
