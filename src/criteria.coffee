define ['utils'], (utils) ->
	{ P } = utils
	
	wrongEdgesUnderneath = (node, edges) ->
		near_edges = edgesUnderneath node, edges
		for edge in near_edges
			if edge not in node.edges
				return Infinity
		0
		
	edgesUnderneath = (node, edges) ->
		underneath = []
		for edge in edges
			d = utils.distToSegmentXY node, edge.source, edge.target
			if d < config.gridSpacing
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

	
	{ wrongEdgesUnderneath, lineStraightness }
