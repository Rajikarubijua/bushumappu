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
			
	class GridCoordGenerator
		constructor: ({ spacing: @g, @filter, @r, @x, @y }={}) ->
			@r ?= 1
			@x ?= 0
			@y ?= 0
			@g ?= 1
			@filter ?= -> true
		
		next: ->
			{ g, filter, x, y } = this
			gx = g*Math.round (x/g)
			gy = g*Math.round (y/g)
			coords = []
			while coords.length == 0
				coords = @coords @r++
				coords = ([gx+g*c[0],gy+g*c[1]] for c in coords)
				coords = (coord for coord in coords when filter coord)
			coords
			
		coords: (r) ->
			coords = []
			for x in [0..r]
				y = r-Math.abs x
				coords.push [ +x, +y ]
				coords.push [ -x, -y ]
				coords.push [ -x, +y ] if x != 0 and y != 0
				coords.push [ +x, -y ] if x != 0 and y != 0
			coords
			
	{ Grid, GridCoordGenerator }
