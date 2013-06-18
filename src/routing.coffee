define ['utils', 'grid', 'graph'], (
	{ P, forall, nearest01, nearestXY, rasterCircle },
	{ Grid }, { Node, Edge }) ->
	###

		Here we stick to the terminology used in Jonathan M. Scotts thesis.
		http://www.jstott.me.uk/thesis/thesis-final.pdf (main algorithm on page 90)
		This involved graph, node, edge, metro line, ...

		* data stucture
			graph = { nodes, edges }
			node  = { station }
			edge  = { link }
			station = { label, cluster,	vector, x, y, kanji, radical, fixed, links }
			link = { source, target, radical, kanjis}
			source = { station }
			target = { station }

	###

	metroMap = (graph, config) ->
		console.time 'metroMap'
		layout = new MetroMapLayout { config, graph }
		layout.snapNodes() if config.gridSpacing > 0
		layout.optimize()
		console.timeEnd 'metroMap'
		graph
		
	class MetroMapLayout
		constructor: ({ config, @graph }) ->
			{ @timeToOptimize, @gridSpacing } = config
			@grid = new Grid
		
		snapNodes: ->
			console.time "snapNodes"
			grid = @grid
			nodes = @graph.nodes[..]
			old_length = nodes.length
			while nodes.length > 0
				toMove = {}
				for node in nodes
					[ x, y ] = @nearestFreeGrid node, grid
					(toMove[x+"x"+y] ?= []).push node
				nodes = []
				for coord, list of toMove
					[ x, y ] = (+d for d in coord.split 'x')
					{ b, i } = nearestXY { x, y }, list
					grid.set [x,y], b
					list[i..i] = []
					nodes = [ nodes..., list... ]
				if nodes.length >= old_length
					throw "no progress"
				old_length = nodes.length
			console.timeEnd "snapNodes"
			
		nearestFreeGrid: ({ x, y }, grid) ->
			g = @gridSpacing
			gx = g*Math.round (x/g)
			gy = g*Math.round (y/g)
			r = 0
			coords = []
			while coords.length == 0
				coords = rasterCircle 0, 0, r++
				coords = ([ gx+g*ox, gy+g*oy ] for [ox,oy] in coords)
				coords = (coord for coord in coords when not grid.has coord)
			{ b } = nearest01 [ x, y ], coords
			return b
			
		optimize: ->
			
		moveNode: (node, criteria) ->
			[ x, y ] = nearestFreeGrid node, @grid
			node.x = x
			node.y = y
			for dep in node.crit.dependencies
				dep.crit = undefined
				
		updateCriteria: (nodes, criteria) ->
			min = null
			for node in nodes
				if not node.crit?
					node.crit = criteria node
				if not min or min.crit.value < node.crit.value
					min = node
			min

		lineStraightness: (node) ->
			segments = {}
			for line in node.lines
				segments[line.id] = []
			dependencies = for edge in node.edges
				if edge.target == node then edge.source else edge.target
			for edge in node.edges
				order = if edge.target == node then 0 else 1
				segments[edge.line.id][order] = edge
			straightness = for line, edges of segments
				[ a, b ] = edges
				angle = a.getAngle b
				Math.pow angle, 2
			value: d3.sum straightness
			deps: dependencies
			
		calculateNodesCriteria: (nodes) ->
			# How to calculate final criterion over multiple criteria? p 89?
			for node in nodes
				edgesOfNode = @getEdgesOfNode node
				# angularResolutionCriterion = @getAngularResolutionCriterion edgesOfNode

			[0,0]
		
		getAngularResolutionCriterion: (edges) ->
			sum = 0
			degree = edges.length
			# TODO: nur nebeneinanderliegende Kanten
			# nur die kleinsten Winkel ... Anzahl = Kanten
			for e1 in edges
				for e2 in edges
					continue if e1 == e2
					sum += Math.abs( (2*Math.PI / degree) - e1.getAngle(e2) )

			sum
		
		getEdgesOfNode: (node) ->
			edgesOfNode = []
			for edge in @graph.edges
				kanji 	  = node.data.kanji
				src_kanji = edge.source.data.kanji
				tar_kanji = edge.target.data.kanji
				if src_kanji == kanji or tar_kanji == kanji
					edgesOfNode.push edge
			edgesOfNode

		findLowestNodeCriteria: (nodes) ->
			0
	
	{ metroMap, MetroMapLayout, Node, Edge }
