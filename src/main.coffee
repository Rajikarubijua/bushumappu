config =
	showLines: 					false
	fixedEndstation:			false
	fixedStation:				false
	filterRadicals:				(radicals) -> radicals[...14]
	filterLinkedRadicals:		(radicals) -> radicals
	sunflowerKanjis:			true
	kmeansInitialVectorsRandom:	false
	kmeansClustersN:			-1 # 0 rule of thumb, -1 vector.length
	forceGraph:					false
	circularLines:				false
	gridSpacing:				48 # 0 deactivates snapNodes
	debugOverlay:				false
	transitionTime:				2000
	initialScale:				1
	edgesBeforeSnap:			false
	timeToOptimize:				0
	optimizeMaxLoops:			0
	optimizeMaxSteps:			0
	slideshowSteps:				1
figue.KMEANS_MAX_ITERATIONS = 1

# the global object where we can put stuff into it
window.my = {
	kanjis: {} 				# "kanji": { "kanji", "radicals", "strokes_n", "freq", "onyomi", "kunyomi", "meaning"}
	radicals: {} 			# "radical" . {"radical", "kanjis"}
	jouyou_radicals: {} 	# "radical" value "kanjikanjikanji"
	jouyou: []				# list of jouyou kanji
	jouyou_grade: {}		# +grade: "kanjis"
	config }

define ['utils', 'load_data', 'central_station',
	'interactivity', 'routing', 'prepare_data',
	'test_routing', 'test_bench', 'tests'], (
	{ P, somePrettyPrint, styleZoom, async, prettyDebug, copyAttrs },
	loadData, { CentralStationEmbedder }, { View }, { MetroMapLayout }, prepare,
	testRouting, testBench, tests) ->

	main = () ->
		body = my.body = d3.select 'body'

		if config.debugOverlay
			showDebugOverlay body
		
		svg   = my.svg = body.select 'svg#graph'
		svg.g = svg.append 'g'
		
		w = new Signal
		h = new Signal
		window.onresize = ->
			w window.innerWidth
			h window.innerHeight
		window.onresize()
		new Observer ->
			attrs = width : 0.95*w(), height: 0.95*h()
			svg.attr attrs
			svg.style attrs
				
		svg.call (zoom = d3.behavior.zoom())
			.translate([w()/2, h()/2])
			.scale(config.initialScale)
			.on('zoom', styleZoom svg.g, zoom)
		# Deactivates zoom on dblclick. According to d3 source code
		# d3.behavior.zoom registers dblclick.zoom. So we can deactivate it.
		# And we need it to do defered, cause d3 would fail unexpectetly.
		# This hasn't been reported yet.
		svg.on('dblclick.zoom', null)
			 
		prepare.setupRadicalJouyous()
		prepare.setupKanjiGrades()
		prepare.setupKanjiRadicals(d3.values(my.kanjis), my.radicals)
		radicals = prepare.getRadicals()
		kanjis = prepare.getKanjis radicals
		kanji_i = 0
		
		embedder = new CentralStationEmbedder { config }
		view = new View { svg: svg.g, config }
		
		do slideshow = ->
			slideshow.steps ?= 0
			return if slideshow.steps++ >= config.slideshowSteps
			kanji_i = Math.floor Math.random()*kanjis.length
			kanji = kanjis[kanji_i]
			console.info (
				"central station "+kanji.kanji+
				" with "+kanji.radicals.length+" radicals")
			graph = embedder.graph kanji, radicals, kanjis
			view.update graph
			setTimeout slideshow, config.transitionTime + 2000
			
	showDebugOverlay = (el) ->
		el.append('pre').attr(id:'my').text somePrettyPrint my
	
	all_tests = copyAttrs {}, testRouting.tests, testBench.tests
	#tests.run all_tests, []
	console.info 'end of tests'
	loadData main
