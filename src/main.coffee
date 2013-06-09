config =
	showLines: 					false
	fixedEndstation:			false
	fixedStation:				false
	filterRadicals:				(radicals) -> radicals
	filterLinkedRadicals:		(radicals) -> radicals
	sunflowerKanjis:			true
	kmeansInitialVectorsRandom:	false
	kmeansClustersN:			0 # 0 rule of thumb, -1 vector.length
	forceGraph:					false

# the global object where we can put stuff into it
window.my = {
	kanjis: {} 				# "kanji": { "kanji", "radicals", "strokes_n", "freq", "onyomi", "kunyomi", "meaning"}
	radicals: {} 			# "radical" . {"radical", "kanjis"}
	jouyou_radicals: {} 	# "radical" value "kanjikanjikanji"
	jouyou: []				# list of jouyou kanji
	jouyou_grade: {}		# +grade: "kanjis"
	config }

define ['utils', 'load_data', 'prepare_data'], (
	{ P, PN, W, copyAttrs, async, strUnique, somePrettyPrint, length, sort,
	styleZoom, sunflower, vecX, vecY, vec, compareNumber, equidistantSelection
	groupBy, getMinMax, arrayUnique, max, distanceSqrXY, nearestXY },
	loadData, prepare) ->

	main = () ->
		body = my.body = d3.select 'body'
		body.append('pre').attr(id:'my').text somePrettyPrint my
				
		svg   = my.svg = body.append 'svg'
		svg.g = svg.append 'g'
				
		w = new Signal
		h = new Signal
		window.onresize = ->
			w window.innerWidth
			h window.innerHeight
		window.onresize()
		new Observer ->
			attrs = { width : w(), height: h() }
			svg.attr attrs
			svg.style attrs
				
		svg.call (zoom = d3.behavior.zoom())
			.translate([w()/2, h()/2])
			.scale(0.12)
			.on 'zoom', styleZoom svg.g, zoom
		draggingStart = -> svg.classed 'dragging', true
		draggingEnd   = -> svg.classed 'dragging', false
		svg.on 'mousedown.cursor' , draggingStart
		svg.on 'mouseup.cursor'   , draggingEnd
		svg.on 'touchstart.cursor', draggingStart
		svg.on 'touchend.cursor'  , draggingEnd
			 
		{ stations, endstations, links } = setupInitialEmbedding()
		setupD3 svg.g, stations, endstations, links


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

	getStationPosition = (station, index, d, n) ->
		x = y = 0
		cluster_index = station.cluster.stations.indexOf station
		if config.sunflowerKanjis
			{ x, y } = sunflower { index: cluster_index+1, factor: 2.7*d }
		else
			columns = Math.floor Math.sqrt n
			x = 2*d *           (index % columns)
			y = 2*d * Math.floor index / columns
		{ x, y }

	svgline = d3.svg.line()
		.x(({x}) -> x)
		.y(({y}) -> y)

	getClusterN = (vectors) ->
		Math.min vectors.length,
		if config.kmeansClustersN > 0
			config.kmeansClustersN
		else switch config.kmeansClustersN
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

	setupPositions = (clusters, d) ->
		for cluster in clusters
			for station, i in cluster.stations
				{ x, y } = getStationPosition station, i, d, cluster.stations.length
				station.x = x
				station.y = y
		setupClusterPosition clusters, d
		for cluster in clusters
			for station in cluster.stations
				station.x += cluster.x
				station.y += cluster.y

	getLinks = (radicals) ->
		console.time 'getLinks'
		links = []
		for radical in config.filterLinkedRadicals radicals
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
		console.timeEnd 'getLinks'
		links

	setupInitialEmbedding = ->
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
		clusters_n = getClusterN vectors
		if not config.kmeansInitialVectorsRandom
			initial_vectors = equidistantSelection clusters_n, vectors
		console.time 'prepare.setupClusterAssignment'
		clusters = prepare.setupClusterAssignment(
			(k.station for k in kanjis), initial_vectors, clusters_n)
		console.timeEnd 'prepare.setupClusterAssignment'
		
		setupClustersForRadicals radicals, clusters
		setupPositions clusters, d
		
		links = getLinks radicals
		endstations = (radical.station for radical in radicals)
		stations = (kanji.station for kanji in kanjis)
		{ stations, endstations, links }

	endstationSelectLine = (d) ->
		selector = ".radical_"+d.radical.radical
		d3.selectAll(selector).classed 'highlighted', (d) ->
			!d3.select(@).classed 'highlighted'

	setupD3 = (svg, stations, endstations, links) ->
		r = 12
		link = svg.selectAll(".link")
			.data(links)
			.enter()
			.append("path")
			.classed("link", true)
			.each((d) ->
				d3.select(@).classed "radical_"+d.radical.radical, true)
			
		endstation = svg.selectAll('.endstation')
			.data(endstations)
			.enter()
			.append('g')
			.classed("endstation", true)
			.on('click.selectLine', endstationSelectLine)
		endstation.append("circle").attr {r}
		endstation.append("text").text (d) -> d.label
		
		station = svg.selectAll('.station')
			.data(stations)
			.enter()
			.append('g')
			.classed("station", true)
		station.append('rect').attr x:-r, y:-r, width:2*r, height:2*r
		station.append('text').text (d) -> d.label
		
		updatePositions = ->
			link.attr d: (d) -> svgline [ d.source, d.target ]
			endstation.attr transform: (d) -> "translate(#{d.x} #{d.y})"
			station.attr transform: (d) -> "translate(#{d.x} #{d.y})"
		updatePositions()
		
		if config.forceGraph
			force = d3.layout.force()
				.nodes([stations..., endstations...])
				.links(links)
				.linkStrength(1)
				.linkDistance(8*r)
				.charge(-3000)
				.gravity(0.001)
				.start()
				.on 'tick', updatePositions
			station.call force.drag
			
	loadData main
