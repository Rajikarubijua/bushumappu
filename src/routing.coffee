define ['utils', 'grid', 'graph'], (
	{ P, forall, nearest01, nearestXY, rasterCircle },
	{ Grid }, { Node, Edge }) ->
	###

		Here we stick to the terminology used in Jonathan M. Scotts thesis.
		http://www.jstott.me.uk/thesis/thesis-final.pdf (main algorithm on page 90)
		This involved graph, node, edge, metro line, ...

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
			mT0 = @calculateNodeCriteria nodes
			loop
				for node in nodes
					mN0 = @calculateNodeCriteria nodes
					mN  = @findLowestNodeCriteria nodes
					if mN < mN0
						@moveNode node
				mT = @calculateNodeCriteria nodes
				# XXX no clustering now
				# no labels
				++loops
				break if time < +Date.now()
				break if mT >= mT0
				mT0 = mT
			P loops+" metro optimization loops"
			
		calculateNodeCriteria: (nodes) ->
			# angularResolutionCriterion = @getAngularResolutionCriterion nodes
			# How to calculate final criterion over multiple criteria? p 89?
			0
		
		getAngularResolutionCriterion: (nodes) ->
			sum = 0
			for node in nodes
				edgesOfNode = @getEdgesOfNode node
				degree = edgesOfNode.length
				l_vec = @getVector edgesOfNode[0]
				for edge in edgesOfNode
					continue if edge == undefined 
					c_vec = @getVector edge
					continue if c_vec == l_vec

					scalar = c_vec[0] * l_vec[0] + c_vec[1] * l_vec[1] 
					c_length = Math.sqrt( Math.pow( c_vec[0], 2 ) + Math.pow( c_vec[1], 2) )
					l_length = Math.sqrt( Math.pow( l_vec[0], 2 ) + Math.pow( l_vec[1], 2) )
					angle = scalar / c_length * l_length
					sum += Math.abs( (2*Math.PI / degree) - angle ) 

					l_vec = @getVector edge
			sum

		getVector: (edge) ->
			p1 = [ edge.link.source.x, edge.link.source.y ]
			p2 = [ edge.link.target.x, edge.link.target.y ]
			vec= [ p1[0] - p2[0], 	p1[1] - p2[1] ]
		
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
	
	{ metroMap, MetroMapLayout }
