define ['utils', 'graph'], ({P, length}, {Graph, Edge, Node, Line}) ->

	cptplaceholder = 3

	class Tube
		constructor: ({ @radicals, @width, @angle, @x, @y, @edges}={}) ->
			@radicals     ?= []
			@width     ?= 0
			@angle ?= 0
			@x ?= 0
			@y ?= 0
			@edges ?= []
			@minilabel ?= false

	createTubes = (sourceedge) ->
		return [sourceedge.sourcecoord, sourceedge.targetcoord] if sourceedge.calc
		sourceedge.sourcecoord = [sourceedge.source.x, sourceedge.source.y]
		sourceedge.targetcoord = [sourceedge.target.x, sourceedge.target.y]
		node = sourceedge.source
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
			for ed in tube.edges
				selector = ".line_"+ edge.line.data.radical
				strokewidth = parseInt d3.selectAll(selector).style("stroke-width")
				if i is 0
					tube.width += strokewidth / 2 + cptplaceholder
					tube.angle = ed.getEdgeAngle() + Math.PI/2
					tube.width = 0 if tube.edges.length is 1
				else
					if i is (tube.edges.length - 1)
						tube.width += strokewidth / 2
					else
						tube.width += strokewidth + cptplaceholder
				i++
			layoutTube tube
		return [sourceedge.sourcecoord, sourceedge.targetcoord]
					
	
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
			#[vecx, vecy] = edge.getVector()
			edge.tube = tube
			edge.sourcecoord = [edge.source.x + drawx - nextx, edge.source.y + drawy - nexty]
			edge.targetcoord = [edge.target.x + drawx - nextx, edge.target.y + drawy - nexty]
			selector = ".line_"+ edge.line.data.radical
			placeholder = (parseInt d3.selectAll(selector).style("stroke-width")) + cptplaceholder
			nextx += (placeholder) * cosAngle
			nexty += (placeholder) * sinAngle
			edge.calc = true
			i++
			
	{Tube, createTubes, layoutTube}