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

require { baseUrl: './' }, ['utils', 'criteria', 'grid', 'graph'], (utils, criteria, grid, { Cluster, Node, Edge, Line, Graph }) ->
	{ P } = utils
	{ Grid, GridCoordGenerator } = grid
	my_criteria = criteria.edgeLength
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
			nodes = for node in nodes
				x: node.x
				y: node.y
				id: node.id
				debug_fill: node.style.debug_fill
			postMessage { type: 'nodes', nodes: graph.nodes, cb }
			
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
