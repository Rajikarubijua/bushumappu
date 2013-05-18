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

	# call 'cb' when all functions in 'funcs' called their callback
	# 'funcs' calls functions with the callback as last argument
	# 'funcs' sets the attribute 'key' of 'object' with the callback
	# when it finds [object, "key"] in 'funcs'
	async =
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

	{ copyAttrs, P, W, async }
