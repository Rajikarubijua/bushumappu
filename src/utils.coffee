define ->
	# copies every attribute of a object 'b' to object 'a'
	copyAttrs = (a, b) -> a[k] = v for k, v of b

	# shorthand for console.log, also returns the last argument
	# usage:
	#	1 + foo bar          # what is bar?
	# 	1 + foo P 'bar', bar
	P = (args...) -> console.log args...; return args[-1..][0]

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
					
		map: (mapped, cb) ->
			mapped_n = (Object.keys mapped).length
			results = {}
			end = (label) -> (args...) ->
				results[label] = args
				cb results if (Object.keys results).length == mapped_n
			for label, func of mapped
				func end label

	strUnique = (str, base) ->
		base ?= ""
		for c in str
			if c not in ret
				base += c
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
			return x.split('').sort args...
		if typeof x is 'object'
			return (Object.keys x).sort args...
		throw "invalid argument ps type #{typeof x}"
 
	{ copyAttrs, P, W, async, strUnique, expect, somePrettyPrint, length, sort }
