define ['utils'], ({ }) ->
		
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

	setupClusterAssignment = (kanjis, radicals, initial_vectors, clusters_n) ->
		vectors = (k.vector for k in kanjis)
		if undefined in vectors
			throw "kanjis need .vector"
		clusters_n ?= initial_vectors?.length
		clusters_n ?= Math.floor Math.sqrt kanjis.length/2
		{ centroids, assignments } =
			figue.kmeans clusters_n, vectors, initial_vectors
		clusters = ({ centroid, kanjis: [] } for centroid in centroids)
		for assignment, assignment_i in assignments
			cluster = clusters[assignment]
			kanji   = kanjis[assignment_i]
			kanji.cluster = cluster
			cluster.kanjis.push kanji		
		clusters

	{ setupRadicalJouyous, setupKanjiGrades,
	  setupKanjiVectors, setupClusterAssignment }
