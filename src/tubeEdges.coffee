define ['utils'], (utils) ->
	{ P } = utils

	cptplaceholder = 0

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
			coords = [[ x1, y1 ], [ x2, y2 ]]
			if utils.distance01(coords...) >= config.overlengthEdge
				dx = Math.abs x2 - x1
				dy = Math.abs y2 - y1
				if dx >= dy
					x05 = x2
					y05 = y1
				else
					x05 = x1
					y05 = y2
				coords = [[ x1, y1 ], [ x05, y05 ], [ x2, y2 ]]
			edge.setCoords coords
			edge.tube = tube
			
	getStrokeWidth = (edge) ->
		selector = ".line_"+ edge.line.data.radical
		stroke_width = parseInt d3.selectAll(selector).style("stroke-width")		
	
	{Tube, createTubes}
