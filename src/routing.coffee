define ['utils', 'grid', 'criteria'], (utils, { Grid, GridCoordGenerator },
	criteria) ->
	{ P, PD, forall, nearest01, nearestXY, rasterCircle, length, compareNumber,
	  sortSomewhat } = utils
	optimizeCriterias = criteria
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
			
		optimize: ({ timeAvailable, criterias }={}) ->
			timeAvailable ?= @timeToOptimize
			criterias ?= optimizeCriterias
			{ optimizeMaxSteps } = @config
			{ nodes, edges, lines } = @graph
			
			nodes = nodes[..]
			criteria = (node) ->
				crits = for name, crit of criterias
					crit node
				value = 0
				deps = []
				for crit in crits
					value += crit.value
					utils.arrayUnique crit.deps, deps
				{ value, deps }
			
			stats =
				moved: {}
				steps: 0
				bench: []
			time = timeAvailable+Date.now()
			while time > +Date.now() and stats.steps < optimizeMaxSteps
				++stats.steps
				@sortByCriteria nodes, criteria
				stats.bench.push d3.sum (n.crit.value for n in nodes)
				for node in nodes
					if not node.crit
						node.crit = criteria node
					if node.crit.value > 0
						if @moveNode node, criteria
							stats.moved[node.data.kanji] = true
			@sortByCriteria nodes, criteria
			stats.bench.push d3.sum (n.crit.value for n in nodes)
			stats.moved = length stats.moved
			stats.better = stats.bench[-1..][0] / stats.bench[0]
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
	
	{ metroMap, MetroMapLayout, optimizeCriterias }
