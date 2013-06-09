define ["utils", "prepare_data"], ({
	P, length, arrayUnique, equidistantSelection, max, sunflower, getMinMax,
	nearestXY },
	prepare) ->

	setupInitialEmbedding = (config) ->
		r = 12
		d = 2*r

		prepare.setupRadicalJouyous()
		prepare.setupKanjiGrades()

		radicals = (my.radicals[radical] for radical of my.jouyou_radicals)
		radicals = config.filterRadicals radicals
		radicals.sort (x) -> x.radical
		radicals_n = length radicals
		
		kanjis = getKanjis radicals
		
		stations = for x in [ kanjis..., radicals... ]
			x.station =
				label:		x.kanji or x.radical
				cluster:	null
				vector:		prepare.getRadicalVector x, radicals
				x:			0
				y:			0
				kanji:		x.kanji? and x
				radical:	x.radical? and x
				fixed:		+config.fixedStation
		
		vectors = (k.station.vector for k in kanjis)
		clusters_n = getClusterN vectors, config
		if not config.kmeansInitialVectorsRandom
			initial_vectors = equidistantSelection clusters_n, vectors
		console.time 'prepare.setupClusterAssignment'
		clusters = prepare.setupClusterAssignment(
			(k.station for k in kanjis), initial_vectors, clusters_n)
		console.timeEnd 'prepare.setupClusterAssignment'
		
		setupClustersForRadicals radicals, clusters
		setupPositions clusters, d, config
		
		links = getLinks (config.filterLinkedRadicals radicals), config
		endstations = (radical.station for radical in radicals)
		stations = (kanji.station for kanji in kanjis)
		{ stations, endstations, links }
		
	getLinks = (radicals, { circularLines }) ->
		console.time 'getLinks'
		links = []
		for radical in radicals
			stations = (kanji.station for kanji in radical.jouyou)
			a = radical.station
			l = stations.length
			while stations.length > 0
				{ b, i } = nearestXY a, stations
				stations[i..i] = []
				links.push { source: a, target: b, radical }
				a = b
				if stations.length == l
					throw "no progres"
				l = stations.length
			if circularLines
				links.push { source: a, target: radical.station, radical }
		console.timeEnd 'getLinks'
		links

	setupPositions = (clusters, d, config) ->
		for cluster in clusters
			for station, i in cluster.stations
				{ x, y } = getStationPosition(
					station, i, d, cluster.stations.length, config)
				station.x = x
				station.y = y
		setupClusterPosition clusters, d
		for cluster in clusters
			for station in cluster.stations
				station.x += cluster.x
				station.y += cluster.y

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
		kanjis = (station.kanji for station in cluster.stations when \
			station.kanji and radical.radical in station.kanji.radicals)

	setupClustersForRadicals = (radicals, clusters) ->
		for radical in radicals
			cluster = max clusters, (cluster) ->
				length getKanjisForRadicalInCluster radical, cluster
			radical.station.cluster = cluster
			cluster.stations.push radical.station

	setupClusterPosition = (clusters, d) ->
		for cluster in clusters
			minmax = getMinMax cluster.stations, { "x", "y" }
			dx = minmax.max_x.x - minmax.min_x.x
			dy = minmax.max_y.y - minmax.min_y.y
			cluster.r = 0.5*Math.max dx, dy
		minmax = getMinMax clusters, { "r" }
		r = minmax.max_r.r
		for cluster, i in clusters
			{ x, y } = sunflower { index: i+1, factor: r }
			cluster.x = x
			cluster.y = y

	getStationPosition = (station, index, d, n, { sunflowerKanjis }) ->
		x = y = 0
		cluster_index = station.cluster.stations.indexOf station
		if sunflowerKanjis
			{ x, y } = sunflower { index: cluster_index+1, factor: 2.7*d }
		else
			columns = Math.floor Math.sqrt n
			x = 2*d *           (index % columns)
			y = 2*d * Math.floor index / columns
		{ x, y }

	{ setupInitialEmbedding }
