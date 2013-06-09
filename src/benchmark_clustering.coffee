clusters_n = 237

define ["prepare_data"], (prepare) ->
	console.log "start"
	figue.KMEANS_MAX_ITERATIONS = 1
	
	clustering = (initial_vectors, stations) ->
		console.time "clustering"
		window.clusters = prepare.setupClusterAssignment(
			stations, initial_vectors, clusters_n)
		console.timeEnd "clustering"
		console.log clusters.length

	raf = (initial_vectors, stations) -> setTimeout (->
		clustering initial_vectors, stations
		raf initial_vectors, stations), 200

	d3.json "data/benchmark_initialvectors.json", (initial_vectors) ->
		console.log "loaded 50%"
		d3.json "data/benchmark_stations.json", (stations) ->
			console.log "loaded 100%"
			raf initial_vectors, stations
