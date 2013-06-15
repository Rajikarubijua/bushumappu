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

		testAngularResolutionCriterion: ->
			config = testConfig

			test = (name, edges, criteria) ->
				console.info "     "+name
				layout = new routing.MetroMapLayout { config, graph: { edges } }
				T.assert name, edges, config, criteria

			link  = {target: {x: 5, y: 1}, source: {x: 1, y: 1}}
			edge1 = new routing.Edge { link }

			link  = {target: {x: 1, y: 1}, source: {x: 3, y: 3}}
			edge2 = new routing.Edge { link }

			link  = {target: {x: -2, y: 1}, source: {x: 1, y: 1}}
			edge3 = new routing.Edge { link }

			edges1  = [ edge1 , edge3]
			edges2  = [ edge1 , edge2]

			# edge getVector()
			test "edge.getVector() test1", [edge1], { coordIsRight1 }
			test "edge.getVector() test2", [edge2], { coordIsRight2 }

			#edge getAngle()
			test "edge.getAngle() test", edges2, { angleIsRight }


			# nodeCriteria
			test "test perfect single edge", [edge1], { criteriaIsNull }
			test "test perfect multiple edge", edges1, { criteriaIsNull }
			test "test multiple edge", edges2, { criteriaIsRight }

			
			
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
		vec = edges[0].getVector()
		if vec[0] == 4 & vec[1] == 0
			return true
		P vec
		false

	coordIsRight2 = (edges) ->
		vec = edges[0].getVector()
		if vec[0] == -2 & vec[1] == -2
			return true
		P vec
		false

	angleIsRight = (edges) ->
		angle = edges[0].getAngle(edges[1])
		output = Math.acos((-8)/(4*Math.sqrt(8)))
		if angle == output
			return true
		P angle
		false

	criteriaIsNull = (edges, config) ->
		layout = new routing.MetroMapLayout { config, graph: { edges } }
		sum = layout.getAngularResolutionCriterion(edges)
		if sum == 0
			return true
		P sum
		false
			
	criteriaIsRight = (edges, config) ->
		layout = new routing.MetroMapLayout { config, graph: { edges } }
		sum = layout.getAngularResolutionCriterion(edges)
		optim = ((2*Math.PI) / edges.length) -  Math.acos((-8)/(4*Math.sqrt(8)))
		if sum == optim*2
			return true
		P optim
		P sum
		false

	testConfig =
		timeToOptimize:		1000
		gridSpacing:		3
			
	runTests = -> T.run tests
			
	{ runTests }
