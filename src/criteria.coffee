define 'criteria', ['utils'], (utils) ->
	{ P } = utils
	
	wrongEdgesUnderneath = (node, edges) -> 
		wrong = []
		for edge in edgesUnderneath node, edges
			if edge not in node.edges
				wrong.push edge
		wrong
		
	edgeCrossings = (edges_a, edges_b) ->
		crossings = 0
		for a in edges_a
			for b in edges_b
				if a.isCrossing b
					crossings++
		crossings
		
	edgesUnderneath = (node, edges) ->
		underneath = []
		for edge in edges
			dists = for pair in utils.consecutivePairs edge.coords()
				utils.distToSegment01 [node.x, node.y], pair...
			if config.gridSpacing*0.9 > d3.min dists
				underneath.push edge
		underneath
		
	lineStraightness = (node) -> 
		angles = for edges in segmentsOfNode node
			edges = utils.sortSomewhat edges, (a, b) ->
				return -1 if a.target == b.source
				return  1 if a.source == b.target
			a = edges[0]
			for b in edges[1..]
				angle = a.getAngle b
				angle = Math.pow angle, 2
				if angle < 0.00001 then 0 else angle
		value = d3.sum d3.merge angles
	
	segmentsOfNode = (node) ->
		segments = {}
		segments[line.id] = [] for line in node.lines
		for edge in node.edges
			other_node = node.otherNode edge
			other = edge.otherEdge other_node.edges
			segment = segments[edge.line.id]
			segment.push edge
			segment.push other if other
		d3.values segments

	lengthOfEdges = (edges) ->
		d3.sum (e.lengthSqr() for e in edges)
		
	tooNearCentralNode = (node) ->
		r = config.kanjiOffset * config.gridSpacing
		r > utils.distanceXY node, { x:0, y:0 }
	
	{ wrongEdgesUnderneath, lineStraightness, lengthOfEdges, edgeCrossings,
	  tooNearCentralNode }
