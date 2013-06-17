define [], () ->

	class Grid
		constructor:    -> @map = d3.map()
		get: (coord)    -> @map.get (@getCoord coord).coord
		has: (coord)    -> @map.has (@getCoord coord).coord
		remove: (coord) -> @map.remove (@getCoord coord).coord
		coords:         -> @map.keys()
		nodes:          -> @map.values()
		entries:        -> @map.entries()
		forEach: (func) -> @map.forEach func
		
		set: (coord, node) ->
			{ coord, x, y } = @getCoord coord
			node.x = x
			node.y = y
			@map.set coord, node
		
		getCoord: (coord) -> # just convenience
			if typeof coord is 'string'
				[ x, y ] = (+d for d in coord.split 'x')
			else if Array.isArray coord
				[ x, y ] = coord
				coord = x+'x'+y
			else if 'x' of coord and 'y' of coord
				{ x, y } = coord
				coord = x+'x'+y
			{ coord, x, y }
			
	{ Grid }
