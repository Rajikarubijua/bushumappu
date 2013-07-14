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
					continue if not toOptimize node
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
			queue = (n for n in nodes when toOptimize n)
			no_move_since = [0]
			changed_nodes = []
			before = @my_graph.ruleViolations()
			do postNodes = =>
				if changed_nodes.length
					@postNodes changed_nodes
					changed_nodes.pop() while changed_nodes.length
				if no_move_since < queue.length * 2
					setTimeout postNodes, config.transitionTime
			do optimizeNode = =>
				for [1..10]
					if not (no_move_since[0]++ < queue.length * 2)
						now = @my_graph.ruleViolations()
						P 'optimization done. ruleViolations from', before, 'to', now
						return
					node = queue.shift()
					moved = @moveNode node
					if moved
						no_move_since[0] = 0
						changed_nodes.push node
					queue.push node
				setTimeout optimizeNode, 100

		optimizeNodes: (nodes) ->
			P 'optimize', nodes.length, 'nodes'
			graph = @my_graph
			quality = (node) -> node.critValue graph
			moved = []
			for node in nodes
				continue if node.critValue(graph) == 0
				if @moveNode node, quality
					moved.push node
			P moved.length, 'movements'
			@postNodes moved

		optimizeStraightLineClusters: (cb) ->
			{ nodes } = @my_graph
			used = {}
			clusters = for node in nodes
				continue if not toOptimize node
				continue if node.id of used
				cluster = @straightLineCluster node
				continue if not cluster 
				for node in cluster.nodes
					if node.id of used
						cluster = null
					used[node.id] = true
				continue if not cluster
				cluster
			clusters.sort (a,b) =>
				d3.descending a.critValue(@my_graph), b.critValue(@my_graph)
			do foo = =>
				return cb?() if not clusters.length
				cluster = clusters.shift()
				if cluster.critValue(@my_graph) > 0
					moved = @moveCluster cluster
					if not moved
						@optimizeNodes cluster.nodes
				setTimeout foo, 10
				
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
				true
			else
				false
			
		moveNode: (node) ->
			copy   = x: node.x, y: node.y
			coords = @coordsAroundNode node, 18
			quality = => { rule: @my_graph.ruleViolations(), crit: @my_graph.critQuality() } 
			gt = (a, b) ->
				a.rule > b.rule or (a.rule == b.rule and a.crit > b.crit)
			perfect = (x) ->
				x.rule == x.crit == 0
			before = quality()
			min    = value: before, coord: [ node.x, node.y ]
			for coord in coords
				node.move coord...
				value = quality()
				if gt min.value, value
					min.value = value
					min.coord = coord
					break if perfect min.value
			[ x, y ] = min.coord
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
					continue if not toOptimize start
					if @straightNode start
						break
			cluster = [start]
			queue = [start]
			while queue.length
				node = queue.pop()
				if @straightNode node
					next = (n for n in node.nextNodes() when n not in cluster and toOptimize n)
					cluster.push next...
					queue.push next...
			cluster
			new Cluster cluster
			
	toOptimize = (node) -> node.kind == 'hi_node'

	postMessage 'ready'
