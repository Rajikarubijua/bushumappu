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

		testNodeCriteria: ->
			config = testConfig

			test = (name, edges, criteria) ->
				console.info "     "+name
				layout = new routing.MetroMapLayout { config, graph: { edges } }
				T.assert name, edges, config, criteria

			link1  = {target: {x: 5, y: 1}, source: {x: 1, y: 1}}
			link2  = {target: {x: 1, y: 1}, source: {x: 3, y: 3}}
			edges  = [{  link1 }, {  link2 }]

			# edge getVector()
			test "edge.getVector() test", [{ link1 }], { coordIsRight1 }
			test "edge.getVector() test", [{ link2 }], { coordIsRight2 }

			# nodeCriteria
			# test "edge.getVector() test", [{  link1 }], config, criteria

			
			
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

	coordIsRight1 = (edges) ->
		link = edges[0].link1
		edge = new routing.Edge { link }
		vec = edge.getVector()
		if vec[0] == 4 & vec[1] == 0
			return true
		false

	coordIsRight2 = (edges) ->
		link = edges[0].link2
		edge = new routing.Edge { link }
		vec = edge.getVector()
		if vec[0] == 2 & vec[1] == 2
			return true
		false		
			
	testConfig =
		timeToOptimize:		1000
		gridSpacing:		3
			
	runTests = -> T.run tests
			
	{ runTests }
