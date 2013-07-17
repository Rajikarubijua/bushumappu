define ['graph'], ({ Graph }) ->
	createNode = -> x: Math.random(), y: Math.random()
	createGraph = (lines, nodesPerLine) ->
		lines = for line in [1..lines]
			createNode() for node in [1..nodesPerLine]
		graph = new Graph lines

	graph100: createGraph 10, 18
	graph10 : createGraph 3, 18
