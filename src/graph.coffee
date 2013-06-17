define [], () ->

	class Node
		constructor: ({ @x, @y, @lines, @edges, @data, @style }={}) ->
			@x     ?= 0
			@y     ?= 0
			@lines ?= []
			@edges ?= []
			@data  ?= {}
			@style ?= {}
		
		coord: -> @x+"x"+@y
	
	class Edge
		constructor: ({ @source, @target, @line, @radical }={}) ->
			throw @radical if @radical
			@source ?= null
			@target ?= null
			@line   ?= null
		
		getVector: ->
			[ @target.x - @source.x, @target.y - @source.y ]

		getAngle: (edge) ->
			[ x1, y1 ] = @getVector()
			[ x2, y2 ] = edge.getVector()
			scalar = x1 * x2 + y1 * y2 
			l1 = Math.sqrt( Math.pow( x1, 2 ) + Math.pow( y1, 2) )
			l2 = Math.sqrt( Math.pow( x2, 2 ) + Math.pow( y2, 2) )
			angle = Math.acos( scalar / (l1 * l2))

	class Line
		constructor: ({ @nodes, @edges, @data }={}) ->
			@nodes ?= []
			@edges ?= []
			@data  ?= {}

	my.graph = { Node, Edge, Line }
