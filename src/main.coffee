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
	kanjis: {} 				# "kanji": { "kanji", "radicals", "stroke_n", "freq", "onyomi", "kunyomi", "meaning"}
	radicals: {} 			# "radical" . {"radical", "kanjis"}
	jouyou_radicals: {} 	# "radical" value "kanjikanjikanji"
	jouyou: []				# list of jouyou kanji
	jouyou_grade: {}		# +grade: "kanjis"
	config }

define ['utils', 'load_data', 'prepare_data', 'initial_embedding',
	'interactivity', 'routing', 'test_routing'], (
	{ P, somePrettyPrint, styleZoom, async, prettyDebug },
	loadData, prepare, { Embedder }, { View }, { MetroMapLayout },
	testRouting) ->

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
			.on 'zoom', styleZoom svg.g, zoom
		draggingStart = -> svg.classed 'dragging', true
		draggingEnd   = -> svg.classed 'dragging', false
		svg.on 'mousedown.cursor' , draggingStart
		svg.on 'mouseup.cursor'   , draggingEnd
		svg.on 'touchstart.cursor', draggingStart
		svg.on 'touchend.cursor'  , draggingEnd
		 
		embedder = new Embedder { config }
		embedder.setup()
		generateEdges = ->
			console.info 'generate edges...'
			embedder.generateEdges()
			console.info 'generate edges done'
		generateEdges() if config.edgesBeforeSnap
		graph = embedder.graph

		fillSeaFil = ->
			strokeMin 	= 1
			strokeMax 	= getStrokeCountMax(graph)
			frqMin		= getFreqMax(graph)
			frqMax		= 1
			gradeMin	= 1
			gradeMax	= Object.keys(my.jouyou_grade).length
			#jlptMin	= 1
			#jlptMax	= 5
			form = d3.select '#seafil form'
			form.select('#count_min').attr('value', strokeMin)
			form.select('#count_max').attr('value', strokeMax)
			form.select('#frq_min').attr('value',   frqMin)
			form.select('#frq_max').attr('value', 	frqMax)
			form.select('#grade_min').attr('value', gradeMin)
			form.select('#grade_max').attr('value', gradeMax)
			#form.select('#jlpt_min').attr('value', 	jlptMin)
			#form.select('#jlpt_max').attr('value', 	jlptMax)

		fillSeaFil()
		body.select('#btn_filter').on 'click' , filterKanji
		body.select('#btn_search').on 'click' , searchKanji

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
			console.info 'optimize...'
			{ stats } = layout.optimize()
			console.info 'optimize done', prettyDebug stats
			view.update()
			if (config.optimizeMaxLoops == -1) or (
				++optimize_loop.loops < config.optimizeMaxLoops)
				setTimeout (-> optimize_loop cb), config.transitionTime
			else
				cb()
		optimize_loop.loops = 0
			
	showDebugOverlay = (el) ->
		el.append('pre').attr(id:'my').text somePrettyPrint my

	getStrokeCountMax = (graph) ->
		max = 1
		for kanji in graph.kanjis
			if kanji.stroke_n > max
				max = kanji.stroke_n
		max

	getFreqMax = (graph) ->
		max = 1
		for kanji in graph.kanjis
			if kanji.freq > max
				max = kanji.freq
		max	

	filterKanji = ->
		P 'hello filter'

	searchKanji = ->
		P 'hello search'
	
	testRouting.runTests []
	console.info 'end of tests'
	loadData main
