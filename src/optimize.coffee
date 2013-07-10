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
	addEventListener 'message', (ev) -> handler[ev.data.type] ev.data
	a = once: true
	
	handler =
		my_graph:	null
		grid:		null
		
		graph: ({ graph }) ->
			@my_graph = graph = new Graph graph
			@grid = new Grid
			@enforceNodes graph
			#for node in graph.nodes or []
			#	@grid.set node, node
			@nodes = graph.nodes[..]
			@nodes.sort (a,b) -> d3.descending a.critValue(), b.critValue()
			@printQuality()
			mainloop = =>
				setTimeout (=>
					@optimize()
					mainloop()
				), 10
			mainloop()

		optimize: ->
			#bisect = d3.bisector (d) -> d.critValue()
			#@printQuality()
			#@enforceNodes @my_graph
			#@optimizeNodes @nodes, 10
			#@optimizeOverlengthEdgeClusters()
			#@optimizeStraightLineClusters()
			
		enforceNodes: (graph) ->
			@snapNodes graph
			for node in graph.nodes
				@postNode node
			
		snapNodes: (graph) ->
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
			
			
			
		optimizeOverlengthEdgeClusters: ->
			edges = @overlengthEdges()
			used_nodes = {}
			clusters = for edge in edges
				cluster = @overlengthEdgeCluster edge, used_nodes
				continue if not cluster
				cluster
			P clusters.length
			clusters.sort (a,b) -> d3.descending a.critValue(), b.critValue()
			for cluster in clusters
				@moveCluster cluster

		optimizeStraightLineClusters: ->
			used = {}
			clusters = for node in @nodes
				continue if node.edges.length > 2 or node.id of used
				cluster = @straightLineCluster node
				continue if not cluster 
				for node in cluster.nodes
					if node.id of used
						cluster = null
					used[node.id] = true
				continue if not cluster
				c = "255,255,255".split ','
				c[Math.random()*3%3] = ""+Math.floor(Math.random() * 255)
				for node in cluster.nodes
					node.style.debug_fill = "rgb("+(c.join ',')+")"
				cluster
			clusters.sort (a,b) -> d3.descending a.critValue(), b.critValue()
			for cluster in clusters
				@moveCluster cluster
						
		moveCluster: (cluster) ->
			min = coord: [0,0], value: cluster.critValue()
			for coord in @coordsForClusterMovement()
				cluster.moveBy coord...
				if cluster.critValue() < min.value
					min.coord = coord
					min.value = cluster.critValue()
				cluster.resetPosition()
			cluster.moveBy min.coord...
			for node in cluster.nodes
				@postNode node
		
		optimizeNodes: (nodes, n=1) ->
			for node in nodes
				node = @moveNode node
				if node
					@postNode node
					break if not --n
			nodes.sort (a,b) -> d3.descending a.critValue(), b.critValue()
			#i = bisect.left @nodes, node
			#@nodes[i..i] = [ node, @nodes[i] ]
			
		round: (x) -> Math.floor(x / config.gridSpacing)*config.gridSpacing
			
		overlengthEdges: ->
			edge for edge in @my_graph.edges when ( 
				edge.length() > config.edgeLength)
					
		overlengthEdgeCluster: (edge, used_nodes) ->
			bfs = utils.breadthFirstSearch (n) ->
				nodes = for e in n.edges
					continue if e.length() > config.edgeLength
					node = criteria.otherNode n, e
					continue if node.fixed
					continue if node.id of used_nodes
					node
			if not edge.source.fixed
				[visited1, found_dont] = bfs edge.source, edge.target
				return null if found_dont
			if not edge.target.fixed
				[visited2, found_dont] = bfs edge.target, edge.source
			if not visited1 and not visited2
				return null
			visited1 ?= length: Infinity
			visited2 ?= length: Infinity
			nodes = utils.min [visited1, visited2], 'length'
			used_nodes[node.id] = true for node in nodes
			new Cluster nodes
			
		straightLineCluster: (start) ->
			bfs = utils.breadthFirstSearch (node) ->			
				nodes = for edge in node.edges
					other_node = criteria.otherNode node, edge
					other_edge = criteria.otherEdge other_node, edge
					continue if not other_edge
					continue if (edge.getAngle other_edge) != 0
					other_node
				nodes
			[visited] = bfs start
			if visited.length > 1 then new Cluster visited else null
			
		quality: ->
			quality = 0
			for node in @nodes
				quality += node.critValue()
			quality
			
		coordsAroundNode: (node) ->
			generator = new GridCoordGenerator
				x: node.x
				y: node.y
				spacing: config.gridSpacing
				filter: (coord) => not @grid.has coord
			coords = []
			for [1..50]
				coords = [ coords..., generator.next()... ]
			coords
			
		coordsForClusterMovement: do ->
			generator = new GridCoordGenerator
				spacing: config.gridSpacing
			coords = d3.merge (generator.next() for [1..10])
			-> coords
			
		moveNode: (node) ->
			copy   = x: node.x, y: node.y
			coords = @coordsAroundNode node
			before = node.critValue() #@quality()
			min    = value: before, coord: [ node.x, node.y ]
			for coord in coords
				node.move coord...
				value = node.critValue() #@quality()
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
				#node.cool *= 0.5
				node
			else
				node.move copy.x, copy.y
				null
				
		postNode: (node) ->
			msg = x: node.x, y: node.y, id: node.id, debug_fill: node.style.debug_fill
			postMessage { type: 'node', node: msg }

		printQuality: ->
			f = (d) -> d.critValue()
			count = Math.floor d3.sum @nodes, (d) -> +((f d) > 0)
			sum = Math.floor d3.sum @nodes, f
			max = Math.floor d3.max @nodes, f
			min = Math.floor d3.min @nodes, f
			P 'quality', count, sum, max, min

	sorted = (arr) ->
		for i in [0...arr.length-1]
			a = arr[i]
			b = arr[i+1]
			throw "not sorted" if a < b

	postMessage type: 'start'
