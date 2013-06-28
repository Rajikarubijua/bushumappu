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
	transitionTime:				750*2
	initialScale:				0.06
	edgesBeforeSnap:			false
	timeToOptimize:				3000
	optimizeMaxLoops:			3
	optimizeMaxSteps:			1
figue.KMEANS_MAX_ITERATIONS = 1

# the global object where we can put stuff into it
window.my = {
	kanjis: {} 				# "kanji": { "kanji", "radicals", "strokes_n", "freq", "onyomi", "kunyomi", "meaning"}
	radicals: {} 			# "radical" . {"radical", "kanjis"}
	jouyou_radicals: {} 	# "radical" value "kanjikanjikanji"
	jouyou: []				# list of jouyou kanji
	jouyou_grade: {}		# +grade: "kanjis"
	config }

define ['utils', 'load_data', 'prepare_data', 'initial_embedding',
	'interactivity', 'routing', 'test_routing', 'test_bench', 'tests'], (
	{ P, somePrettyPrint, styleZoom, async, prettyDebug, copyAttrs },
	loadData, prepare, { Embedder }, { View }, { MetroMapLayout },
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
			attrs = width : 0.95*w(), height: 0.66*h()
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
			 
		embedder = new Embedder { config }
		embedder.setup()
		generateEdges = ->
			console.info 'generate edges...'
			embedder.generateEdges()
			console.info 'generate edges done'
		generateEdges() if config.edgesBeforeSnap
		graph = embedder.graph
		view = new View { svg: svg.g, graph, config }
		layout = new MetroMapLayout { config, graph }
		view.update()
		async.seqTimeout config.transitionTime,
			config.gridSpacing > 0 and ((cb) ->
				console.info 'snap nodes...'
				layout.snapNodes()
				console.info 'snap node done'
				generateEdges() if not config.edgesBeforeSnap
				view.update()
				cb()
			),((cb) ->
				optimize_loop cb
			)
		optimize_loop = (cb) ->
			if config.optimizeMaxLoops != -1 and (
				++optimize_loop.loops >= config.optimizeMaxLoops)
				return cb()
			console.info 'optimize...'
			{ stats } = layout.optimize()
			console.info 'optimize done', prettyDebug stats
			view.update()
			setTimeout (-> optimize_loop cb), config.transitionTime
		optimize_loop.loops = 0
			
	showDebugOverlay = (el) ->
		el.append('pre').attr(id:'my').text somePrettyPrint my
	
	all_tests = copyAttrs {}, testRouting.tests, testBench.tests
	tests.run all_tests, []
	console.info 'end of tests'
	loadData main
