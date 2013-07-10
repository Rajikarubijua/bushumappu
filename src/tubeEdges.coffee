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

	createTubes = (my_edge) ->
		###
		{ source, target } = sourceedge
		calc = [source.x, source.y, target.x, target.y].join ','
		if sourceedge.calc == calc
			return [sourceedge.sourcecoord, sourceedge.targetcoord]
		sourceedge.sourcecoord = [sourceedge.source.x, sourceedge.source.y]
		sourceedge.targetcoord = [sourceedge.target.x, sourceedge.target.y]
		node = sourceedge.source
		edges = []
		for edge in node.edges
			continue if !(edge.source is node)
			if edge.calc != calc
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
		###
		{ source, target } = my_edge
		tube = new Tube
		tube.x = source.x
		tube.y = source.y
		tube.angle = my_edge.getEdgeAngle() + Math.PI/2
		for edge in source.edges
			continue if not (
				edge.source in [ source, target ] and
				edge.target in [ source, target ])
			tube.edges.push edge
			tube.width += getStrokeWidth edge
			{ radical } = edge.line.data
			tube.radicals.push radical if radical not in tube.radicals
		# layout tube
		cos_angle = Math.cos tube.angle
		sin_angle = Math.sin tube.angle
		edges_n = tube.edges.length
		for edge, edge_i in tube.edges
			{ source, target, line } = edge
			r = (edge_i - edges_n/2 + 0.5) * (1 + getStrokeWidth edge)
			x1 = source.x + r * cos_angle
			y1 = source.y + r * sin_angle
			x2 = target.x + r * cos_angle
			y2 = target.y + r * sin_angle
			edge.sourcecoord = [ x1, y1 ]
			edge.targetcoord = [ x2, y2 ]
			edge.tube = tube
		return [my_edge.sourcecoord, my_edge.targetcoord]
			
	getStrokeWidth = (edge) ->
		selector = ".line_"+ edge.line.data.radical
		stroke_width = parseInt d3.selectAll(selector).style("stroke-width")		
	
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
			{ source, target, line } = edge
			edge.calc = [source.x, source.y, target.x, target.y].join ','
			#[vecx, vecy] = edge.getVector()
			edge.sourcecoord = [source.x + drawx - nextx, source.y + drawy - nexty]
			edge.targetcoord = [target.x + drawx - nextx, target.y + drawy - nexty]
			selector = ".line_"+ line.data.radical
			edge.tube = tube

			placeholder = (parseInt d3.selectAll(selector).style("stroke-width")) + cptplaceholder
			nextx += (placeholder) * cosAngle
			nexty += (placeholder) * sinAngle
			i++
			
	{Tube, createTubes, layoutTube}
