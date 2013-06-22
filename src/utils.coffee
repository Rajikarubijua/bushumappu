define ->
	# copies every attribute of a object 'b' to object 'a'
	copyAttrs = (a, b) -> a[k] = v for k, v of b; a

	# shorthand for console.log, also returns the last argument
	# usage:
	#	1 + foo bar          # what is bar?
	# 	1 + foo P 'bar', bar
	P = (args...) -> console.log args...; return args[-1..][0]
	PN= (args...) -> console.log args[...-1]...; return args[-1..][0]
	PD= (args...) ->
		str = prettyDebug args
		console.debug str if my.debug
		args[-1..][0]

	prettyDebug = (x, known=[], depth=0) ->
		if x in known
			'###'
		else if typeof x in ['undefined', 'boolean']
			''+x
		else if typeof x is 'string'
			if depth <= 1 then x else '"'+x+'"'
		else if typeof x is 'number'
			x = ""+(0.01*Math.round x*100)
		else if typeof x is 'function'
			(""+x).split('{')[0]
		else if Array.isArray x
			known.push x
			s = if depth == 0 then ' ' else ','
			x = (for y in x
				prettyDebug y, known, depth+1
			).join s
			if depth == 0 then x else '['+x+']'
		else
			known.push x
			x = (for k, v of x
				v = prettyDebug v, known, depth+1
				k+':'+v
			).join ','
			'{'+x+'}'

	# appends 'fill' to 'str' such that 'str.length == width'
	W = (width, str, fill) ->
		str = ""+str
		fill ?= " "
		width = Math.max str.length, width
		str + (fill for [1..width-str.length]).join ''

	async =
		# call 'cb' when all functions in 'funcs' called their callback
		# 'funcs' calls functions with the callback as last argument
		# 'funcs' sets the attribute 'key' of 'object' with the callback
		# when it finds [object, "key"] in 'funcs'
		parallel: (funcs, cb) ->
			results = []
			i = funcs.length
			end = (args...) ->
				results.push args
				cb results if --i == 0
			for func in funcs
				if typeof func is "function"
					func end
				else
					[ o, k ] = func
					o[k] = end
					
		# 'mapped' is a object which maps labels to functions
		# each function is called with the callback as last argument
		# the arguments for that callback are gathered together with the label
		# a object which maps labels to their gathered callback arguments is
		# passed to 'cb'
		map: (mapped, cb) ->
			mapped_n = (Object.keys mapped).length
			results = {}
			end = (label) -> (args...) ->
				results[label] = args
				cb results if (Object.keys results).length == mapped_n
			for label, func of mapped
				func end label
				
		seqTimeout: (timeout, funcs...) ->
			funcs = (func for func in funcs when func)
			i = 0
			iter = -> setTimeout (->
				funcs[i++] (-> iter() if i < funcs.length)
				), timeout
			iter()

	strUnique = (str, base) ->
		base ?= ""
		for c in str
			if c not in base
				base += c
		return base
		
	arrayUnique = (array, base) ->
		base ?= []
		for e in array
			if e not in base
				base.push e
		return base
		
	expect = (regex, line, i) ->
		m = line.match regex
		throw "expected #{regex} at #{i}" if m == null
		return m
		
	somePrettyPrint = (o) ->
		# everything in 'o' gets pretty printed for development joy
		w = firstColumnWidth = 30
		lines = for k in (Object.keys o).sort()
			v = o[k]
			if Array.isArray v
				k = W w, "["+k+"]"
				v = v.length
			else if typeof v is 'object'
				k = W w, "{"+k+"}"
				v = (Object.keys v).length
			else
				k = W w, " "+k+" "
				v = JSON.stringify v
			k+" "+v
		lines.join "\n"

	length = (x) ->
		return x.length if x.length?
		return (Object.keys x).length
		
	sort = (x, args...) ->
		if 'sort' of x
			return x.sort args...
		if typeof x is 'string'
			return x.split('').sort(args...).join ''
		if typeof x is 'object'
			return (Object.keys x).sort args...
		throw "invalid argument ps type #{typeof x}"
		
	compareNumber = (a,b) -> -(a<b) or a>b or 0
		
	# converts a d3.behavior.zoom into a CSS transform
	# https://github.com/mbostock/d3/wiki/Zoom-Behavior#wiki-zoom
	styleZoom = (el, zoom, dontCall) ->
		func = ->
			t = zoom.translate()
			el.style "-webkit-transform": "
				translate(#{t[0]}px, #{t[1]}px)
				scale(#{zoom.scale()})"
		func() if not dontCall
		func

	# useful to generate sunflower patterns
	# http://en.wikipedia.org/wiki/Sunflower#Mathematical_model_of_floret_arrangement
	sunflower = ({ index, factor, x, y }) ->
		throw "missing index" if not index?
		throw "missing factor" if not factor?
		x ?= 0
		y ?= 0
		a = index * 55/144 * 2*Math.PI
		r = factor * Math.sqrt index
		x += r * Math.cos a
		y += r * Math.sin a
		{ x, y }

	vecX = (r, angle) -> r * Math.cos angle
	vecY = (r, angle) -> r * Math.sin angle
	vec  = (r, angle) -> [ (vecX r, angle), (vecY r, angle) ]
	
	parseMaybeNumber = (str) ->
		if "#{+str}" == str then +str else str

	equidistantSelection = (n, array, { offset }={}) ->
		offset ?= 0
		step = Math.floor array.length/n
		(array[(offset + i*step) % array.length] for i in [0...n])
		
	groupBy = (array, func) ->
		groups = {}
		for element in array
			(groups[func element] ?= []).push element
		groups
		
	getMinMax = (array, map) ->
		map = copyAttrs {}, map
		for key, func of map
			if typeof func == 'string'
				map[key] = do (func) -> (x) -> x[func]
		result = {}
		for element in array
			for key, func of map
				value = func element
				min = result["min_"+key]
				max = result["max_"+key]
				if not min? or value < func min
					result["min_"+key] = element
				if not max? or value > func max
					result["max_"+key] = element
		result
		
	max = (array, func) ->
		if typeof func == 'string'
			func = do (func) -> (x) -> x[func]
		max_value = max_e = undefined
		for e in array
			value = func e
			if not max_value? or value > max_value
				max_value = value
				max_e = e
		max_e

	distanceSqrXY = (a, b) ->
		Math.pow( b.x - a.x, 2 ) + Math.pow( b.y - a.y, 2 )

	distanceSqr01 = (a, b) ->
		Math.pow( b[0] - a[0], 2 ) + Math.pow( b[1] - a[1], 2 )

	nearest = (a, array, distanceFunc) ->
		min_d = 1/0
		min_i = null
		for b, i in array
			d = distanceFunc a, b
			if d < min_d
				min_d = d
				min_i = i
		{ b: array[min_i], i: min_i }
		
	nearestXY = (a, array) -> nearest a, array, distanceSqrXY
	nearest01 = (a, array) -> nearest a, array, distanceSqr01

	forall = (func) -> (xs) ->
		func x for x in xs
		
	rasterCircle = (x0, y0, r) ->
		# http://en.wikipedia.org/wiki/Midpoint_circle_algorithm
		f = 1 - r
		ddF_x = 1
		ddF_y = -2 * r
		x = 0
		y = r
		pxs = [ [x0, y0+r], [x0, y0-r], [x0+r, y0], [x0-r, y0] ]
		while x < y
			if f >= 0
				--y
				ddF_y += 2
				f += ddF_y
			++x
			ddF_x += 2
			f += ddF_x
		pxs = pxs.concat [
			[x0+x, y0+y], [x0-x, y0+y], [x0+x, y0-y], [x0-x, y0-y],
			[x0+y, y0+x], [x0-y, y0+x], [x0+y, y0-x], [x0-y, y0-x] ]

	sortSomewhat = (xs, cmp) ->
		xs = xs[..]
		min = x: xs[0], i: 0
		for x, i in xs
			if (cmp x, min.x) == -1
				min = { x, i }
		a = min.x
		xs[min.i..min.i] = []
		sorted = [a]
		l = xs.length
		while xs.length
			for [0...xs.length]
				b = xs.shift()
				if (cmp a, b) == -1
					sorted.push b
					a = b
				else
					xs.push b
			if xs.length >= l
				P sorted, xs
				throw "not somewhat sortable"
		sorted
			

	{ copyAttrs, P, PN, PD, W, async, strUnique, expect, somePrettyPrint, length,
	  sort, styleZoom, sunflower, vecX, vecY, vec, compareNumber, max,
  	  parseMaybeNumber, equidistantSelection, getMinMax, arrayUnique,
  	  distanceSqrXY, nearestXY, nearest01, distanceSqr01, nearest, forall,
  	  rasterCircle, prettyDebug, sortSomewhat }
