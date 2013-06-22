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

		testOptimizeLineStraightness: ->
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
				graphB
			
			a = { x: -1, y:  0, id: 'a' }
			b = { x:  0, y:  0, id: 'b' }
			c = { x:  1, y:  0, id: 'c' }
			test "single line, optimal",
				[[a,b,c]], { noMovement, optimal, noOverlap }
			
			b = { x:  0, y:  1, id: 'b' }
			debug -> test "single line, single error",
				[[a,b,c]], { movement, optimal, noOverlap }
			
			b = { x:  0, y:  0, id: 'b' }
			d = { x:  0, y: -1, id: 'd' }
			e = { x:  0, y:  1, id: 'e' }
			test "two lines, optimal",
				[[a, b, c], [d, b, e]], { noMovement, optimal, noOverlap }
			
			b = { x:  1, y:  1, id: 'b' }
			test "two lines, single error",
				[[a, b, c], [d, b, e]], { movement, optimal, noOverlap }
				
			a = x: -1, y: -1, id: 'a'
			b = x:  1, y: -1, id: 'b'
			c = x:  1, y:  1, id: 'c'
			d = x: -1, y:  1, id: 'd'
			config.optimizeMaxSteps = 3
			test "one line, U turn",
				[[a,b,c,d]], { movement, optimal, noOverlap }
			config.optimizeMaxSteps = 1
			
		testLineStraightness: ->
			config = testConfig
			
			test = (name, graph, result) ->
				graph = createGraph graph
				layout = new routing.MetroMapLayout { config, graph }
				values = for node in graph.nodes
					(layout.lineStraightness node).value
				T.assert name, null, null, correct: ->
					correct = for v, i in values
						r = result[i]
						if r == 0
							v == 0
						else if r == true
							v > 0
						else
							true
					[ not (false in correct), values ]
				values
			
			a = x: -1, y:  0, id: 'a'
			b = x:  0, y:  0, id: 'b'
			c = x:  1, y:  0, id: 'c'
			d = x:  2, y:  0, id: 'd'
			result = [0,0,0,0]
			test '', [[a,b,c,d]], result
			
			a = x: -1, y:  0, id: 'a'
			b = x:  0, y:  1, id: 'b'
			c = x:  1, y:  0, id: 'c'
			d = x:  2, y:  0, id: 'd'
			result = [true,true,true,true]
			test '', [[a,b,c,d]], result
			
			a = x: -1, y:  0, id: 'a'
			b = x:  0, y:  1, id: 'b'
			c = x:  1, y:  1, id: 'c'
			d = x:  2, y:  0, id: 'd'
			result = [true,true,true,true]
			test '', [[a,b,c,d]], result
			
			a = x: -1, y:  0, id: 'a'
			b = x: -1, y:  1, id: 'b'
			c = x:  1, y:  1, id: 'c'
			d = x:  1, y:  0, id: 'd'
			result = [true,true,true,true]
			test '', [[a,b,c,d]], result
			
			a = x: -1, y: -1, id: 'a'
			b = x:  0, y:  0, id: 'b'
			c = x:  1, y:  1, id: 'c'
			d = x:  2, y:  2, id: 'd'
			result = [0,0,0,0]
			test '', [[a,b,c,d]], result

	debug = (func) ->
		my.debug = true
		func()
		my.debug = false

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
			
	noOverlap = ({ graphB }) ->
		for a in graphB.nodes
			for b in graphB.nodes
				continue if a == b
				if a.x == b.x and a.y == b.y
					return false
		true
			
	noMovement = (args...) ->
		result = movement args...
		if Array.isArray result
			result[0] = !result[0]
		else
			result = !result
		result
		
	movement = ({ graphA, graphB }) ->
		moved = []
		for a, i in graphA.nodes
			b = graphB.nodes[i]
			if not (a.x == b.x and a.y == b.y)
				(o = {})[a.id] = [[a.x,a.y],[b.x,b.y]]
				moved.push o
		if moved.length then [true, moved] else false
		
	optimal = ({ graphB, criteria }) ->
		values = for node in graphB.nodes
			[node.id, (criteria node).value]
		for v in values
			return [ false, values ] if v[1] != 0
		[ true, values ]
			
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
		optimizeMaxSteps:	1
			
	{ tests }
