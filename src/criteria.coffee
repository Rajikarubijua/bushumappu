define ['utils'], (utils) ->
	
	lineStraightness = (node) -> new LineStraightness node	
	class LineStraightness
		constructor: (@node) ->
			@segments = @createSegments()
			@deps     = @createDeps()
			@value    = @createValue()
	
		createSegments: ->
			segments = {}
			segments[line.id] = [] for line in @node.lines
			for edge in @node.edges
				other_node = otherNode @node, edge
				other = otherEdge other_node, edge
				segment = segments[edge.line.id]
				segment.push edge
				segment.push other if other
			segments
	
		createDeps: ->
			deps = []
			for line,edges of @segments
				for edge in edges
					for n in [edge.source, edge.target]
						if n != @node and n not in deps
							deps.push n
			deps
			
		createValue: ->
			angles = for line, edges of @segments
				edges = utils.sortSomewhat edges, (a, b) ->
					return -1 if a.target == b.source
					return  1 if a.source == b.target
				a = edges[0]
				for b in edges[1..]
					angle = a.getAngle b
					angle = Math.pow angle, 2
					if angle < 0.00001 then 0 else angle
			value = d3.sum d3.merge angles
	
	
	
	
	
	otherNode = (node, edge) ->
		if edge.source == node then edge.target else edge.source
		
	otherEdge = (node, edge) ->
		for other in node.edges
			continue if other == edge
			if other.line.id == edge.line.id
				return other
		null
	
	{ lineStraightness }
