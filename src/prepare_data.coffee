define ['utils'], ({ }) ->

	prepare_data = ->
		jouyou_kanjis = setup_radical_jouyous()			
		setup_kanji_grades()
		{ jouyou_kanjis }
		
	setup_radical_jouyous= ->
		jouyou_kanjis = []
		for radical, kanjis of my.jouyou_radicals
			kanjis = (my.kanjis[k] for k in kanjis)
			my.radicals[radical].jouyou = kanjis
			for k in kanjis
				if k not in jouyou_kanjis
					jouyou_kanjis.push k
		jouyou_kanjis
		
	setup_kanji_grades = ->
		for grade, kanjis of my.jouyou_grade
			for kanji in kanjis
				my.kanjis[kanji].grade = +grade
				
	setup_kanji_vectors = (kanjis, radicals) ->
		vectors = []
		for kanji in kanjis
			vectors.push kanji.vector = []
			for radical, radical_i in radicals
				kanji.vector[radical_i] = +(radical.radical in kanji.radicals)

	setup_cluster_assignment = (kanjis, radicals, initial_vectors) ->
		vectors = (k.vector for k in kanjis)
		if undefined in vectors
			throw "kanjis need .vector"	
		{ centroids, assignments } =
			figue.kmeans initial_vectors.length, vectors, initial_vectors
		clusters = ({ centroid, kanjis: [] } for centroid in centroids)
		for assignment, assignment_i in assignments
			cluster = clusters[assignment]
			kanji   = kanjis[assignment_i]
			kanji.cluster = cluster
			cluster.kanjis.push kanji		
		clusters

	{ prepare_data, setup_radical_jouyous, setup_kanji_grades,
	  setup_kanji_vectors, setup_cluster_assignment }
