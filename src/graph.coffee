define [], () ->

	class Node
		constructor: ({ @station }) ->
			@x = @station.x
			@y = @station.y
		
		coord: -> @x+"x"+@y
	
	class Edge
		constructor: ({ @link }) ->

	{ Node, Edge }
