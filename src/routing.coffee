define ['utils', 'grid'], (
	{ P, PD, forall, nearest01, nearestXY, rasterCircle, length, compareNumber,
	sortSomewhat },
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
		constructor: ({ @config, @graph }) ->
			{ @timeToOptimize, @gridSpacing } = @config
			@grid = new Grid
			for node in @graph.nodes or []
				@grid.set node, node
		
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
					grid.remove b
					grid.set [x,y], b
					list[i..i] = []
					nodes = [ nodes..., list... ]
				if nodes.length >= old_length
					throw "no progress"
				old_length = nodes.length
			
		nearestFreeGrid: ({ x, y }, grid) ->
			g = @gridSpacing
			generator = new GridCoordGenerator {
				x, y
				spacing: g
				filter: (coord) -> not grid.has coord
			}
			coord = [ (g*Math.round (x/g)), (g*Math.round (y/g)) ]
			coords = generator.next()
			coords.push coord if not grid.has coord
			{ b } = nearest01 [ x, y ], coords
			return b
			
		optimize: (timeAvailable) ->
			timeAvailable ?= @timeToOptimize
			{ nodes, edges, lines } = @graph
			nodes = nodes[..]
			time = timeAvailable+Date.now()
			moved = {}
			steps = 0
			bench = []
			while time > +Date.now() and steps < @config.optimizeMaxSteps
				++steps
				@sortByCriteria nodes, @lineStraightness
				bench.push d3.sum (n.crit.value for n in nodes)
				for node in nodes
					if not node.crit
						node.crit = @lineStraightness node
					if node.crit.value > 0
						if @moveNode node, @lineStraightness
							moved[node.data.kanji] = true
			@sortByCriteria nodes, @lineStraightness
			bench.push d3.sum (n.crit.value for n in nodes)
			stats =
				moved: length moved
				steps: steps
				bench: bench[-1..][0] / bench[0]
			{ stats }
			
		moveNode: (node, criteria) ->
			update = (crit) -> n.crit = criteria n for n in crit.deps
			sum = (crit) -> crit.value + d3.sum (n.crit.value for n in crit.deps)
			
			generator = new GridCoordGenerator
				x: node.x
				y: node.y
				spacing: @gridSpacing
				filter: (coord) => not @grid.has coord
			coords = generator.next()
			coords.push generator.next()...
				
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
				
		sortByCriteria: (nodes, criteria) ->
			nodes.sort (a, b) ->
				for node in [ a, b ]
					node.crit = criteria node if not node.crit?
				compareNumber b.crit.value, a.crit.value

		lineStraightness: (node) =>
			segments = {}
			segments[line.id] = [] for line in node.lines
			for edge in node.edges
				other_node = @otherNode node, edge
				other = @otherEdge other_node, edge
				segment = segments[edge.line.id]
				segment.push edge
				segment.push other if other
			deps = []
			for line,edges of segments
				for edge in edges
					for n in [edge.source, edge.target]
						if n != node and n not in deps
							deps.push n
			angles = for line, edges of segments
				edges = sortSomewhat edges, (a, b) ->
					return -1 if a.target == b.source
					return  1 if a.source == b.target
				a = edges[0]
				for b in edges[1..]
					angle = a.getAngle b
					angle = Math.pow angle, 2
					if angle < 0.00001 then 0 else angle
			straightness = d3.sum d3.merge angles
			value: straightness
			deps: deps
			
		otherNode: (node, edge) ->
			if edge.source == node then edge.target else edge.source
			
		otherEdge: (node, edge) ->
			for other in node.edges
				continue if other == edge
				if other.line.id == edge.line.id
					return other
			null
			
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
