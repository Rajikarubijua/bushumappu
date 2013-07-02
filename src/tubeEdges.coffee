define ['utils', 'graph'], ({P, length}, {Graph, Edge, Node, Line}) ->

	cptplaceholder = 5

	class Tube
		constructor: ({ @radicals, @width, @angle, @x, @y, @edges}={}) ->
			@radicals     ?= []
			@width     ?= 0
			@angle ?= 0
			@x ?= 0
			@y ?= 0
			@edges ?= []

	createTubes = (edge) ->
		return [edge.sourcecoord, edge.targetcoord] if edge.calc
		edge.sourcecoord = [edge.source.x, edge.source.y]
		edge.targetcoord = [edge.target.x, edge.target.y]
		node = edge.source
		edges = []
		for edge in node.edges
			if edge.source is node and edge.calc is false
				edges.push edge
		targets = []
		for edge in edges
			if edge.target not in targets
				targets.push edge.target
		for target in targets
			tube = new Tube {}
			tube.x = node.x
			tube.y = node.y
			tube.width = 0
			for edge in node.edges
				if target == edge.target
					tube.edges.push edge
					tube.radicals.push edge.line.data.radical
			i = 0
			for edge in tube.edges
				selector = ".line_"+ edge.line.data.radical
				if i is 0
					tube.width += (parseInt d3.selectAll(selector).style("stroke-width")) / 2
					tube.width += cptplaceholder
					tube.angle = edge.getEdgeAngle() + Math.PI/2
					tube.width = 0 if tube.edges.length is 1
				else
					if i is (tube.edges.length - 1)
						tube.width += (parseInt d3.selectAll(selector).style("stroke-width")) / 2
					else
						tube.width += parseInt d3.selectAll(selector).style("stroke-width")
						tube.width += cptplaceholder
				i++
			layoutTube tube
		return [edge.sourcecoord, edge.targetcoord]
					
	
	layoutTube = (tube) ->
		cosAngle = Math.cos(tube.angle)
		sinAngle = Math.sin(tube.angle)
		drawx = (tube.width / 2) * cosAngle
		drawy = (tube.width / 2) * sinAngle
		tube.edges.sort()
		nextx = 0
		nexty = 0
		i = 0
		for edge in tube.edges
			[vecx, vecy] = edge.getVector()
			edge.sourcecoord = [edge.source.x + drawx - nextx, edge.source.y + drawy - nexty]
			edge.targetcoord = [edge.target.x + drawx - nextx, edge.target.y + drawy - nexty]
			edge.calc = true if tube.edges.length > 1
			selector = ".line_"+ edge.line.data.radical
			placeholder = (parseInt d3.selectAll(selector).style("stroke-width")) + cptplaceholder
			nextx += (placeholder) * cosAngle
			nexty += (placeholder) * sinAngle
			i++
			

	{createTubes, layoutTube}