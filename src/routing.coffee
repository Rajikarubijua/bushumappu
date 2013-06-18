define ['utils', 'grid'], (
	{ P, PD, forall, nearest01, nearestXY, rasterCircle, length, compareNumber },
	{ Grid }) ->
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
			
		nearestFreeGrid: ({ x, y }, grid) ->
			g = @gridSpacing
			coords = new GridCoordGenerator {
				x, y
				spacing: g
				filter: (coord) -> not grid.has coord
			}
			gx = g*Math.round (x/g)
			gy = g*Math.round (y/g)
			{ b } = nearest01 [ x, y ], [[ gx, gy ], coords.next()...]
			return b
			
		optimize: (timeAvailable) ->
			timeAvailable ?= @timeToOptimize
			{ nodes, edges, lines } = @graph
			nodes = nodes[..]
			time = timeAvailable+Date.now()
			moved = {}
			loops = 0
			while time > +Date.now()
				++loops
				@sortByCriteria nodes, @lineStraightness
				for node in nodes
					if node.crit?.value > 0 and @moveNode node, @lineStraightness
						moved[node.data.kanji] = true
			stats =
				moved: length moved
				loops: loops
			{ stats }
			
		moveNode: (node, criteria) -> 
			generator = new GridCoordGenerator
				x: node.x
				y: node.y
				spacing: @gridSpacing
				filter: (coord) => not @grid.has coord
			coords = []
			while generator.r < 9
				coords = [ coords..., generator.next()... ]
			min = { crit: node.crit, coord: [ node.x, node.y ] }
			copy =
				x: node.x
				y: node.y
			for coord in coords
				node.x = coord[0]
				node.y = coord[1]
				crit = criteria node
				if min.crit.value > crit.value
					min.crit = crit
					min.coord = coord
			[ x, y ] = min.coord
			if x != node.x or y != node.y
				for dep in node.crit.deps
					dep.crit = undefined
				@grid.remove node
				@grid.set [x,y], node
				node.crit = min.crit
				node
			else
				node.x = copy.x
				node.y = copy.y
				null
				
		sortByCriteria: (nodes, criteria) ->
			nodes.sort (a, b) ->
				for node in [ a, b ]
					node.crit = criteria node if not node.crit?
				compareNumber b.crit.value, a.crit.value

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
				if a and b
					angle = a.getAngle b
					Math.pow angle, 2
			straightness = d3.sum (x for x in straightness when x)
			value: straightness
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
	
	class GridCoordGenerator
		constructor: ({ spacing: @g, @filter, @r, @x, @y }={}) ->
			@r ?= 1
			@x ?= 0
			@y ?= 0
			@g ?= 1
			@filter ?= -> true
		
		next: ->
			{ g, filter, x, y } = this
			gx = g*Math.round (x/g)
			gy = g*Math.round (y/g)
			coords = []
			while coords.length == 0
				coords = @coords @r++
				coords = ([gx+g*c[0],gy+g*c[1]] for c in coords)
				coords = (coord for coord in coords when filter coord)
			coords
			
		coords: (r) ->
			coords = []
			for x in [0..r]
				y = r-Math.abs x
				coords.push [ +x, +y ]
				coords.push [ -x, -y ]
				coords.push [ -x, +y ] if x != 0 and y != 0
				coords.push [ +x, -y ] if x != 0 and y != 0
			coords
	
	{ metroMap, MetroMapLayout }
