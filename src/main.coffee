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
	gridSpacing:				48*6 # 0 deactivates snapNodes
	debugOverlay:				false
	transitionTime:				750*2
	initialScale:				0.06
	edgesBeforeSnap:			true
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
	'interactivity', 'routing', 'test_routing'], (
	{ P, somePrettyPrint, styleZoom, async },
	loadData, prepare, { Embedder }, { View }, { MetroMapLayout },
	testRouting) ->

	main = () ->
		body = my.body = d3.select 'body'

		if config.debugOverlay
			showDebugOverlay body
				
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
		if config.edgesBeforeSnap
			embedder.generateEdges()
		graph = embedder.graph
		view = new View { svg: svg.g, graph, config }
		layout = new MetroMapLayout { config, graph }
		view.update()		
		async.seqTimeout config.transitionTime,
			config.gridSpacing > 0 and (->
				layout.snapNodes()
				if not config.edgesBeforeSnap
					embedder.generateEdges()
				view.update()),
			(->
				layout.optimize()
				view.update())
			
	showDebugOverlay = (el) ->
		el.append('pre').attr(id:'my').text somePrettyPrint my
			
	testRouting.runTests()
	loadData main
