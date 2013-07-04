self.require = urlArgs: "bust=" +  (new Date()).getTime()
importScripts '/lib/require.js'
self.document = documentElement: ->
self.window = self
window.CSSStyleDeclaration = ->
importScripts '/lib/d3.v3.js'
self.console = log: (xs...) -> postMessage type: 'log', log: xs.join ' '
console.debug = console.info = console.log
self.my = debug: true

require { baseUrl: './' }, ['utils', 'criteria', 'grid', 'graph'], (utils, criteria, grid, { Node, Edge, Line, Graph }) ->
	{ P } = utils
	{ Grid, GridCoordGenerator } = grid
	my_criteria = criteria.lineStraightness
	addEventListener 'message', (ev) -> handler[ev.data.type] ev.data
	handler =
		my_graph:	null
		grid:		null
		
		graph: ({ graph }) ->
			@my_graph = graph = new Graph graph
			@grid = new Grid
			for node in graph.nodes or []
				@grid.set node, node
			for node in graph.nodes
				node.crit = my_criteria node if not node.crit?
			mainloop = =>
				setTimeout (=>
					@optimize @my_graph
					mainloop()
				), 10
			mainloop()

		optimize: (graph) ->
			gridSpacing = 12
			{ nodes, edges, lines } = graph
			i = Math.floor Math.random() * nodes.length
			node = nodes[i]
			node = @moveNode node, my_criteria
			if node
				msg = x: node.x, y: node.y, id: node.id
				postMessage { type: 'node', node: msg }
			
		moveNode: (node, criteria) ->
			gridSpacing = 12 * 4
			update = (crit) -> n.crit = criteria n for n in crit.deps
			sum = (crit) -> crit.value + d3.sum (n.crit.value for n in crit.deps)
			
			generator = new GridCoordGenerator
				x: node.x
				y: node.y
				spacing: gridSpacing
				filter: (coord) => not @grid.has coord
			coords = []
			for [1..2]
				coords = [ coords..., generator.next()... ]
			
			copy   = x: node.x, y: node.y
			update node.crit
			before = sum node.crit
			min    = value: before, coord: [ node.x, node.y ]
			
			for coord in coords
				node.x = coord[0]
				node.y = coord[1]
				node.crit = criteria node
				update node.crit
				value = sum node.crit
				value = 0 if value < 0.0001
				if min.value > value
					min.value = value
					min.coord = coord
					break if min.value == 0
			[ x, y ] = min.coord
			if x != copy.x or y != copy.y
				@grid.remove copy
				@grid.set [x,y], node
				node.crit = criteria node
				update node.crit
				node
			else
				node.x = copy.x
				node.y = copy.y
				null

	postMessage type: 'start'
