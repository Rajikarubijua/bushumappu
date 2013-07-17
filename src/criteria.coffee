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
	
	{ wrongEdgesUnderneath }
