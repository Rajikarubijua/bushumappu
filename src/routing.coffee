define ['utils'], ({ P, forall, nearest01, nearestXY, rasterCircle }) ->
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

	metroMap = ({ stations, endstations, links }, config) ->
		console.time 'metroMap'
		nodes = for station in [ stations..., endstations... ]
			new Node { station }
		edges = for link in links
			new Edge { link }
		graph = { nodes, edges }
		layout = new MetroMapLayout { config, graph }
		layout.snapNodes() if config.gridSpacing > 0
		layout.optimize()
		for node in nodes
			node.station.x = node.x
			node.station.y = node.y
		console.timeEnd 'metroMap'
		{ stations, endstations, links }
	
	class Node
		constructor: ({ @station }) ->
			@x = @station.x
			@y = @station.y
		
		coord: -> @x+"x"+@y
	
	class Edge
		constructor: ({ @link }) ->

		getVector: () ->
			[ x1,y1 ] = [ @link.source.x, @link.source.y ]
			[ x2,y2 ] = [ @link.target.x, @link.target.y ]
			vec 	  = [ x2 - x1, y2 - y1 ]

		getAngle: (edge) ->
			[ x1, y1 ] = @getVector()
			[ x2, y2 ] = edge.getVector()
			scalar = x1 * x2 + y1 * y2 
			l1 = Math.sqrt( Math.pow( x1, 2 ) + Math.pow( y1, 2) )
			l2 = Math.sqrt( Math.pow( x2, 2 ) + Math.pow( y2, 2) )
			angle = Math.acos( scalar / (l1 * l2))

		isSame: (edge) ->
			sameSource = @link.source.x == edge.link.source.x and @link.source.y == edge.link.source.y
			sameTarget = @link.target.x == edge.link.target.x and @link.target.y == edge.link.target.y
			sameTarget && sameSource
	
	class Grid
		constructor:    -> @map = d3.map()
		get: (coord)    -> @map.get (@getCoord coord).coord
		has: (coord)    -> @map.has (@getCoord coord).coord
		remove: (coord) -> @map.remove (@getCoord coord).coord
		coords:         -> @map.keys()
		nodes:          -> @map.values()
		entries:        -> @map.entries()
		forEach: (func) -> @map.forEach func
		
		set: (coord, node) ->
			{ coord, x, y } = @getCoord coord
			node.x = x
			node.y = y
			@map.set coord, node
		
		getCoord: (coord) -> # just convenience
			if typeof coord is 'string'
				[ x, y ] = (+d for d in coord.split 'x')
			else if Array.isArray coord
				[ x, y ] = coord
				coord = x+'x'+y
			else if 'x' of coord and 'y' of coord
				{ x, y } = coord
				coord = x+'x'+y
			{ coord, x, y }
		
	class MetroMapLayout
		constructor: ({ config, @graph }) ->
			{ @timeToOptimize, @gridSpacing } = config
			@grid = new Grid
		
		snapNodes: ->
			console.time "snapNodes"
			grid = new Grid
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
			
		nearestFreeGrid: ({ x, y, spiral }, grid) ->
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
			{ nodes } = @graph
			# somewhat like Algorithm 3.2 Metro Map Layout
			loops = 0
			time = @timeToOptimize+Date.now()
			[ mT0, mN ] = @calculateNodesCriteria nodes
			mT = mT0
			loop
				for node in nodes
					mN0 = node.criteria
					if mN < mN0
						@moveNode node
						[ mT, mN ] = @calculateNodesCriteria nodes
				# XXX no clustering now
				# no labels
				++loops
				break if time < +Date.now()
				break if mT >= mT0
				mT0 = mT
			P loops+" metro optimization loops"
			
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
					continue if e1.isSame(e2)					
					sum += Math.abs( (2*Math.PI / degree) - e1.getAngle(e2) )

			sum
		
		getEdgesOfNode: (node) ->
			edgesOfNode = []
			for edge in @graph.edges
				kanji 	  = node.station.kanji.kanji
				src_kanji = edge.link.source.kanji.kanji
				tar_kanji = edge.link.target.kanji.kanji
				if src_kanji == kanji or tar_kanji == kanji
					edgesOfNode.push edge
			edgesOfNode

		findLowestNodeCriteria: (nodes) ->
			0
		
		moveNode: (node) ->
	
	{ metroMap, MetroMapLayout, Node, Edge }
