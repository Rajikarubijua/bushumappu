define ['utils'], ({ W, sort }) ->

	assert = (test_name, value, config, criterias) ->
		success = true
		results = {}
		for name, func of criterias
			result = func value, config
			results[name] = result
			success = false if not result
		msg = [test_name]
		for name in sort results
			msg.push (W 20, name)+" "+results[name]
		msg.push W 50, "", "–"
		for k, v of value
			try str = JSON.stringify v
			str ?= ""+v
			msg.push (W 20, k)+" "+str.split('\n')[0]
		console.assert success, msg.join '\n'
		console.info "ok" if success
			
	run = (tests, which) ->
		for name, test of tests
			continue if which?.length and name not in which
			console.info name
			console.time name
			error = []
			try test()
			finally console.timeEnd name
			
	{ assert, run }
