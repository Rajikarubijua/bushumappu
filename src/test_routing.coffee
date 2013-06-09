define ['utils', 'routing', 'tests'], ({ P }, routing, T) ->

	tests =
		testSnapNodes: ->
			config = testConfig
			g = config.gridSpacing

			test = (name, nodes, criteria) ->
				console.info "     "+name
				layout = new routing.MetroMapLayout { config, graph: { nodes } }
				layout.snapNodes()
				T.assert name, nodes, config, criteria
			
			test "single node",
				[{ x: -1, y: -1 }],
				{ oneIsAtZero, allAreSnapped }		
			test "two, different grid",
				[{ x: -1, y: -1 }, { x: -1+g, y: -1+g }],
				{ oneIsAtZero, allAreSnapped }		
			test "two, same distance",
				[{ x: -1, y: -1 }, { x: 1, y: 1 }],
				{ oneIsAtZero, allAreSnapped }
			test "ten, same position",
				({ x:0, y:0 } for [1..10]),
				{ oneIsAtZero, allAreSnapped }
			
			
	oneIsAtZero = (nodes) ->
		for node in nodes
			if node.x == 0 and node.y == 0
				return true
		false
		
	allAreSnapped = (nodes, { gridSpacing }) ->
		for node in nodes
			if node.x % gridSpacing != 0 or node.y % gridSpacing != 0
				return false
		true
			
	testConfig =
		timeToOptimize:		1000
		gridSpacing:		3
			
	runTests = -> T.run tests
			
	{ runTests }
