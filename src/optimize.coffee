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

		snapNodes: ->
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
					grid.set [x,y], b
					list[i..i] = []
					nodes = [ nodes..., list... ]
				if nodes.length >= old_length
					throw "no progress"
				old_length = nodes.length
			@postNodes nodes
			
		postNodes: (nodes) ->
			nodes = for node in nodes
				x: node.x
				y: node.y
				id: node.id
				debug_fill: node.style.debug_fill
			postMessage { type: 'nodes', nodes }
			
		applyRules: ->
			{ nodes, edges } = @my_graph
			
			changed_nodes = []
			for node in nodes
				moved = @moveNode node, (node) => node.compliant @my_graph
				if moved
					changed_nodes.push node
			
			@postNodes changed_nodes
			
		optimize: ->
			do foo = =>
				@optimizeStraightLineClusters ->
					setTimeout foo, 1000

		optimizeStraightLineClusters: (cb) ->
			{ nodes } = @my_graph
			used = {}
			clusters = for node in nodes
				continue if node.id of used
				cluster = @straightLineCluster node
				continue if not cluster 
				for node in cluster.nodes
					if node.id of used
						cluster = null
					used[node.id] = true
				continue if not cluster
				
				rnd = -> 128 + Math.floor Math.random() * 127
				color = "rgb(#{rnd()},#{rnd()},#{rnd()})"
				for n in cluster.nodes
					n.style.debug_fill = color
				
				cluster
			clusters.sort (a,b) =>
				d3.descending a.critValue(@my_graph), b.critValue(@my_graph)
			do foo = =>
				return cb?() if not clusters.length
				cluster = clusters.shift()
				if cluster.critValue(@my_graph) > 0
					@moveCluster cluster
				setTimeout foo, 1
				
		moveCluster: (cluster) ->
			graph = @my_graph
			min = coord: [0,0], value: cluster.critValue(graph)
			for coord in @coordsForClusterMovement()
				cluster.moveBy coord...
				if cluster.critValue(graph) < min.value
					min.coord = coord
					min.value = cluster.critValue(graph)
				cluster.resetPosition()
			if not (min.coord[0] == min.coord[1] == 0)
				cluster.moveBy min.coord...
				@postNodes cluster.nodes
			
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
			
		coordsForClusterMovement: do ->
			generator = new GridCoordGenerator
				spacing: config.gridSpacing
			coords = d3.merge (generator.next() for [1..20])
			-> coords
			
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
			
		straightNode: (node) ->
			okay = false
			for edge in node.edges
				other_edge = edge.otherEdge node.edges
				continue if not other_edge
				if (edge.getAngle other_edge) != 0
					return false
				okay = true
			okay
			
		straightLineCluster: (start) ->
			if not @straightNode start
				for start in start.nextNodes()
					if @straightNode start
						break
			cluster = [start]
			queue = [start]
			while queue.length
				node = queue.pop()
				if @straightNode node
					next = (n for n in node.nextNodes() when n not in cluster)
					cluster.push next...
					queue.push next...
			cluster
			new Cluster cluster

	postMessage 'ready'
