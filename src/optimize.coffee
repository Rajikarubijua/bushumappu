self.require = urlArgs: "bust=" +  (new Date()).getTime()
importScripts '/lib/require.js'
self.document = documentElement: ->
self.window = self
window.CSSStyleDeclaration = ->
importScripts '/lib/d3.v3.js'
self.console = log: (xs...) -> postMessage type: 'log', log: xs.join ' '
console.debug = console.info = console.log
self.my = debug: true
importScripts 'config.js'

require { baseUrl: './' }, ['utils', 'grid', 'graph'], (utils, grid, { Cluster, Node, Edge, Line, Graph }) ->
	{ P } = utils
	{ Grid, GridCoordGenerator } = grid
	addEventListener 'message', (ev) ->
		console.log 'worker receive', ev.data.type
		handler[ev.data.type] ev.data
	a = once: true
	
	handler =
		my_graph:	null
		grid:		null
		
		graph: ({ graph }) ->
			@my_graph = graph = new Graph graph
			@grid = new Grid
			for node in graph.nodes
				@grid.set node, node

		snapNodes: ({ cb }) ->
			graph = @my_graph
			grid = @grid
			nodes = graph.nodes[..]
			old_length = nodes.length
			while nodes.length > 0
				toMove = {}
				for node in nodes
					[ x, y ] = @nearestFreeGrid node, grid
					(toMove[x+"x"+y] ?= []).push node
				nodes = []
				for coord, list of toMove
					[ x, y ] = (+d for d in coord.split 'x')
					{ b, i } = utils.nearestXY { x, y }, list
					grid.remove b
					if x == 0 and y == 0
						P b.id
					grid.set [x,y], b
					list[i..i] = []
					nodes = [ nodes..., list... ]
				if nodes.length >= old_length
					throw "no progress"
				old_length = nodes.length
			nodes = for node in graph.nodes
				x: node.x
				y: node.y
				id: node.id
			postMessage { type: 'nodes', nodes, cb }
			
		applyRules: ({ cb }) ->
			{ nodes, edges } = @my_graph
			
			changed_nodes = []
			for node in nodes
				moved = @moveNode node, (node) => node.compliant @my_graph
				if not moved and (node.compliant @my_graph) > 0
					P '!'
				if moved
					changed_nodes.push node
			
			nodes = for node in changed_nodes
				x: node.x
				y: node.y
				id: node.id
				debug_fill: 'red'
			postMessage { type: 'nodes', nodes, cb }
			
		moveNode: (node, quality) ->
			copy   = x: node.x, y: node.y
			coords = @coordsAroundNode node, 50
			before = quality node
			min    = value: before, coord: [ node.x, node.y ]
			for coord in coords
				node.move coord...
				value = quality node
				value = 0 if value < 0.0001
				if min.value > value
					min.value = value
					min.coord = coord
					break if min.value == 0
			[ x, y ] = min.coord
			a.once = false
			if x != copy.x or y != copy.y
				node.move x,y
				@grid.remove copy
				@grid.set node, node
				node
			else
				node.move copy.x, copy.y
				null
			
		coordsAroundNode: (node, n) ->
			generator = new GridCoordGenerator
				x: node.x
				y: node.y
				spacing: config.gridSpacing
				filter: (coord) => not @grid.has coord
			coords = []
			while coords.length < n
				coords = [ coords..., generator.next()... ]
			coords
			
		nearestFreeGrid: ({ x, y }, grid) ->
			g = config.gridSpacing
			generator = new GridCoordGenerator {
				x, y
				spacing: g
				filter: (coord) -> not grid.has coord
			}
			coord = [ (g*Math.round (x/g)), (g*Math.round (y/g)) ]
			coords = generator.next()
			coords.push coord if not grid.has coord
			{ b } = utils.nearest01 [ x, y ], coords
			return b

	postMessage 'ready'
