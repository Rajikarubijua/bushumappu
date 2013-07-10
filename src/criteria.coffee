define ['utils'], (utils) ->
	{ P } = utils
	
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
			other_node = otherNode node, edge
			other = otherEdge other_node, edge
			segment = segments[edge.line.id]
			segment.push edge
			segment.push other if other
		d3.values segments
	
	random = (node) ->
		deps: []
		value: Math.random()
	
	edgeLength = (node) ->
		#length = d3.max node.edges, (d) -> d.lengthSqr()
		wanted = Math.pow config.edgeLength, 2
		c = d3.sum node.edges, (d) ->
			Math.pow (wanted - d.lengthSqr()), 2
		if c < 0.00001 then 0 else c
			
	nearNodes = (node) ->
		wanted = (Math.pow config.edgeLength, 2) / 2
		d3.sum (for other in node.deps()
			d = utils.distanceSqrXY other, node
			Math.pow (d / wanted), 2)


	otherNode = (node, edge) ->
		if edge.source == node then edge.target else edge.source
		
	otherEdge = (node, edge) ->
		for other in node.edges
			continue if other == edge
			if other.line.id == edge.line.id
				return other
		null
	
	{ lineStraightness, random, edgeLength, otherNode, otherEdge, nearNodes }
