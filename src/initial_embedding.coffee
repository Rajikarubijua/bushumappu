define ["utils", "prepare_data", 'graph'], ({
	P, length, arrayUnique, equidistantSelection, max, sunflower, getMinMax,
	nearestXY },
	prepare, { Node, Edge, Line }) ->

	class Embedder
		constructor: ({ @config }) ->
			@r = 12
			@graph = {}
			@radicals = []

		setup: ->
			{ r, config } = this
			d = 2*r

			prepare.setupRadicalJouyous()
			prepare.setupKanjiGrades()

			radicals = (my.radicals[radical] for radical of my.jouyou_radicals)
			radicals = config.filterRadicals radicals
			radicals.sort (x) -> x.radical
			radicals_n = length radicals
		
			kanjis = getKanjis radicals
		
			nodes = for data in [ kanjis..., radicals... ]
				node = new Node { data }
				node.vector = prepare.getRadicalVector data, radicals
				node.label  = data.kanji or data.radical
				node.cluster = null
				node.fixed = +config.fixednode
				data.node = node
				node
			nodes_kanjis = (k.node for k in kanjis)
			nodes_radicals = (r.node for r in radicals)
		
			vectors = (n.vector for n in nodes_kanjis)
			clusters_n = getClusterN vectors, config
			if not config.kmeansInitialVectorsRandom
				initial_vectors = equidistantSelection clusters_n, vectors
			console.time 'prepare.setupClusterAssignment'
			clusters = prepare.setupClusterAssignment(
				nodes_kanjis, initial_vectors, clusters_n)
			console.timeEnd 'prepare.setupClusterAssignment'
		
			setupClustersForRadicals radicals, clusters
			setupPositions clusters, d, config
		
			edges = []
			lines = []
			endnodes = nodes_radicals
			@radicals = radicals
			@graph = { nodes: nodes_kanjis, endnodes, edges, lines , kanjis}
		
		generateEdges: ->
			{ radicals, graph, config } = this
			radicals = config.filterLinkedRadicals radicals
			[ edges, lines ] = getEdges radicals, config
			graph.edges = edges
			graph.lines = lines
		
	getEdges = (radicals, { circularLines }) ->
		edges = []
		lines = []
		for radical in radicals
			lines.push line = new Line data: radical
			nodes = (kanji.node for kanji in radical.jouyou)
			a = radical.node
			l = nodes.length
			while nodes.length > 0
				{ b, i } = nearestXY a, nodes
				nodes[i..i] = []
				edge = new Edge { source: a, target: b, line }
				edges.push edge
				a.edges.push edge
				b.edges.push edge
				line.edges.push edge
				line.nodes.push a
				a.lines.push line
				a = b
				if nodes.length == l
					throw "no progres"
				l = nodes.length
			if circularLines
				b = radical.node
				edge = new Edge { source: a, target: b, line }
				edges.push edge
				a.edges.push edge
				b.edges.push edge
				line.edges.push edge
				line.nodes.push a
				a.lines.push line
			line.nodes.push b
			b.lines.push line
		[ edges, lines ]

	setupPositions = (clusters, d, config) ->
		for cluster in clusters
			for node, i in cluster.nodes
				{ x, y } = getNodePosition(
					node, i, d, cluster.nodes.length, config)
				node.x = x
				node.y = y
		setupClusterPosition clusters, d
		for cluster in clusters
			for node in cluster.nodes
				node.x += cluster.x
				node.y += cluster.y

	getClusterN = (vectors, { kmeansClustersN }) ->
		Math.min vectors.length,
		if kmeansClustersN > 0
			kmeansClustersN
		else switch kmeansClustersN
			when -1 then Math.floor vectors[0].length
			when 0  then Math.floor Math.sqrt vectors.length/2

	getKanjis = (radicals) ->
		kanjis = []
		for radical in radicals
			arrayUnique radical.jouyou, kanjis
		kanjis.sort (x) -> x.kanji

	getKanjisForRadicalInCluster = (radical, cluster) ->
		kanjis = (node.data for node in cluster.nodes when \
			node.data.kanji and radical.radical in node.data.radicals)

	setupClustersForRadicals = (radicals, clusters) ->
		for radical in radicals
			cluster = max clusters, (cluster) ->
				length getKanjisForRadicalInCluster radical, cluster
			radical.node.cluster = cluster
			cluster.nodes.push radical.node

	setupClusterPosition = (clusters, d) ->
		for cluster in clusters
			minmax = getMinMax cluster.nodes, { "x", "y" }
			dx = minmax.max_x.x - minmax.min_x.x
			dy = minmax.max_y.y - minmax.min_y.y
			cluster.r = 0.5*Math.max dx, dy
		minmax = getMinMax clusters, { "r" }
		r = minmax.max_r.r
		for cluster, i in clusters
			{ x, y } = sunflower { index: i+1, factor: r }
			cluster.x = x
			cluster.y = y

	getNodePosition = (node, index, d, n, { sunflowerKanjis }) ->
		x = y = 0
		cluster_index = node.cluster.nodes.indexOf node
		if sunflowerKanjis
			{ x, y } = sunflower { index: cluster_index+1, factor: 2.7*d }
		else
			columns = Math.floor Math.sqrt n
			x = 2*d *           (index % columns)
			y = 2*d * Math.floor index / columns
		{ x, y }

	{ Embedder }
