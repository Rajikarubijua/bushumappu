define ['utils'], ({ P }) ->
		
	setupRadicalJouyous= ->
		jouyou_kanjis = []
		for radical, kanjis of my.jouyou_radicals
			kanjis = (my.kanjis[k] for k in kanjis)
			my.radicals[radical].jouyou = kanjis
			for k in kanjis
				if k not in jouyou_kanjis
					jouyou_kanjis.push k
		jouyou_kanjis
		
	setupKanjiGrades = ->
		for grade, kanjis of my.jouyou_grade
			for kanji in kanjis
				my.kanjis[kanji].grade = +grade
				
	setupKanjiVectors = (kanjis, radicals) ->
		vectors = []
		for kanji in kanjis
			vectors.push kanji.vector = []
			for radical, radical_i in radicals
				kanji.vector[radical_i] = +(radical.radical in kanji.radicals)

	getRadicalVector = (char, radicals) ->
		vector = []
		if char.radical
			vector = (0 for [0...radicals.length])
			vector[radicals.indexOf char] = 1
		else if char.kanji
			for radical, radical_i in radicals
				vector[radical_i] = +(radical.radical in char.radicals)
		vector

	setupClusterAssignment = (nodes, initial_vectors, clusters_n) ->
		vectors = (n.vector for n in nodes)
		if undefined in vectors
			throw "node need .vector"
		clusters_n ?= initial_vectors?.length
		clusters_n ?= Math.floor Math.sqrt nodes.length/2
		{ centroids, assignments } =
			figue.kmeans clusters_n, vectors, initial_vectors
		clusters = ({ centroid, nodes: [] } for centroid in centroids)
		for assignment, assignment_i in assignments
			cluster = clusters[assignment]
			node = nodes[assignment_i]
			node.cluster = cluster
			cluster.nodes.push node
		clusters

	{ setupRadicalJouyous, setupKanjiGrades,
	  setupKanjiVectors, setupClusterAssignment, getRadicalVector }
