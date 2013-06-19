define ['utils', 'routing', 'graph', 'tests'], ({ P, PD }, routing,
	{ Node, Edge, Line }, T) ->

	tests =
		testSnapNodes: ->
			config = testConfig
			g = config.gridSpacing

			test = (name, graph, criteria) ->
				console.info "     "+name
				graph = createGraph graph
				layout = new routing.MetroMapLayout { config, graph }
				layout.snapNodes()
				T.assert name, graph.nodes, config, criteria
			
			test "single node",
				[[{ x: -1, y: -1 }]],
				{ oneIsAtZero, allAreSnapped }		
			test "two, different grid",
				[[{ x: -1, y: -1 }, { x: -1+g, y: -1+g }]],
				{ oneIsAtZero, allAreSnapped }		
			test "two, same distance",
				[[{ x: -1, y: -1 }, { x: 1, y: 1 }]],
				{ oneIsAtZero, allAreSnapped }
			test "ten, same position",
				[({ x:0, y:0 } for [1..10])],
				{ oneIsAtZero, allAreSnapped }

		testAngularResolutionCriterion: ->
			config = testConfig

			test = (name, edges, criteria) ->
				console.info "     "+name
				layout = new routing.MetroMapLayout { config, graph: { edges } }
				T.assert name, edges, config, criteria

			edge1 = new Edge target: {x: 5, y: 1}, source: {x: 1, y: 1}
			edge2 = new Edge target: {x: 1, y: 1}, source: {x: 3, y: 3}
			edge3 = new Edge target: {x: -2, y: 1}, source: {x: 1, y: 1}

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

		testLineStraightness: ->
			config = testConfig
			config.gridSpacing = 1
			
			test = (name, graph, criteria) ->
				console.info "     "+name
				graphA = createGraph graph
				graphB = createGraph graph
				layout = new routing.MetroMapLayout { config, graph: graphB }
				graphCriteria = layout.lineStraightness
				{ stats } = layout.optimize 100
				critsBefore = for node in graphA.nodes
					(graphCriteria node).value
				critsAfter = for node in graphB.nodes
					(graphCriteria node).value
				value = { graphA, graphB, criteria: graphCriteria, stats,
					critsBefore, critsAfter }
				T.assert name, value, config, criteria
			
			a = { x: -1, y:  0 }
			b = { x:  0, y:  0 }
			c = { x:  1, y:  0 }
			test "single line, optimal",
				[[a,b,c]], { noMovement, optimal }
			
			b = { x:  0, y:  1 }
			test "single line, single error",
				[[a,b,c]], { movement, optimal }
			
			b = { x:  0, y:  0 }
			d = { x:  0, y: -1 }
			e = { x:  0, y:  1 }
			test "two lines, optimal",
				[[a, b, c], [d, b, e]], { noMovement, optimal }
			
			b = { x:  1, y:  1, id: 'b' }
			test "two lines, single error",
				[[a, b, c], [d, b, e]], { movement, optimal }
			
	createGraph = (lines) ->
		graph =
			nodes: []
			edges: []
			lines: []
		nodes = []
		for line_nodes in lines
			for node in line_nodes
				nodes.push node if node not in nodes
		graph.nodes = (new Node node for node in nodes)
		graph.lines = for orig_line_nodes in lines
			line = new Line
			line.nodes = for node in orig_line_nodes
				node = graph.nodes[nodes.indexOf node]
				node.lines.push line
				node
			line
		for line in graph.lines
			source = line.nodes[0]
			for target in line.nodes[1..]
				edge = new Edge { source, target, line }
				source.edges.push edge
				target.edges.push edge
				graph.edges.push edge
				line.edges.push edge
				source = target
		graph
			
	noMovement = ({ graphA, graphB }) ->
		for a, i in graphA.nodes
			b = graphB.nodes[i]
			if not (a.x == b.x and a.y == b.y)
				return false
		true
		
	movement = ({ graphA, graphB }) ->
		moved = []
		for a, i in graphA.nodes
			b = graphB.nodes[i]
			if not (a.x == b.x and a.y == b.y)
				moved.push [[a.x,a.y],[b.x,b.y]]
		if moved.length then moved else false
		
	optimal = ({ graphA, graphB, criteria }) ->
		for node in graphB.nodes
			if 0 < (criteria node).value
				return false
		true
			
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
			
	runTests = (which)-> T.run tests, which
			
	{ runTests }
