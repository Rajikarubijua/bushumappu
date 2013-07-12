define ['utils', 'graph'], ({P, length}, {Graph, Edge, Node, Line}) ->

	cptplaceholder = 3

	class Tube
		tube_id = 0
		constructor: ({ @radicals, @width, @angle, @x, @y, @edges}={}) ->
			@radicals     ?= []
			@width     ?= 0
			@angle ?= 0
			@x ?= 0
			@y ?= 0
			@edges ?= []
			@minilabel ?= false
			@id = tube_id++
	createTubes = (my_edge) ->
		if my_edge.sourcecoord? and my_edge.targetcoord?
			return [my_edge.sourcecoord, my_edge.targetcoord]
		{ source, target } = my_edge
		tube = new Tube
		tube.x = source.x
		tube.y = source.y
		tube.angle = my_edge.getEdgeAngle()
		for edge in source.edges
			continue if not (
				edge.source in [ source, target ] and
				edge.target in [ source, target ])
			tube.edges.push edge
			tube.width += getStrokeWidth edge
			{ radical } = edge.line.data
			tube.radicals.push radical if radical not in tube.radicals
		# layout tube
		normal = tube.angle + 0.5*Math.PI
		cos_angle = Math.cos normal
		sin_angle = Math.sin normal
		edges_n = tube.edges.length
		for edge, edge_i in tube.edges
			{ source, target, line } = edge
			width = cptplaceholder + getStrokeWidth edge
			r = (edge_i - edges_n/2 + 0.5) * width
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
	
	{Tube, createTubes}
