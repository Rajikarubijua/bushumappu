define [], () ->

	class Node
		next_id = 0
		constructor: ({ @x, @y, @lines, @edges, @data, @style, @id }={}) ->
			@x     ?= 0
			@y     ?= 0
			@lines ?= []
			@edges ?= []
			@data  ?= {}
			@style ?= {}
			@id    ?= next_id++
		
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
		next_id = 0
		constructor: ({ @nodes, @edges, @data, @id }={}) ->
			@nodes ?= []
			@edges ?= []
			@data  ?= {}
			@id    ?= next_id++

	my.graph = { Node, Edge, Line }
