define [], () ->

	class Node
		constructor: ({ @station }) ->
			@x = @station.x
			@y = @station.y
		
		coord: -> @x+"x"+@y
	
	class Edge
		constructor: ({ @link }) ->
		
		getVector: () ->
			[ x1,y1 ] = [ @link.source.x, @link.source.y ]
			[ x2,y2 ] = [ @link.target.x, @link.target.y ]
			vec 	  = [ x2 - x1, y2 - y1 ]

		getAngle: (edge) ->
			[ x1, y1 ] = @getVector()
			[ x2, y2 ] = edge.getVector()
			scalar = x1 * x2 + y1 * y2 
			l1 = Math.sqrt( Math.pow( x1, 2 ) + Math.pow( y1, 2) )
			l2 = Math.sqrt( Math.pow( x2, 2 ) + Math.pow( y2, 2) )
			angle = Math.acos( scalar / (l1 * l2))

		isSame: (edge) ->
			sameSource = @link.source.x == edge.link.source.x and @link.source.y == edge.link.source.y
			sameTarget = @link.target.x == edge.link.target.x and @link.target.y == edge.link.target.y
			sameTarget && sameSource

	{ Node, Edge }
