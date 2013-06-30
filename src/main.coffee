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

		fillInputData = (id, value) ->
			path = "#seafil form #{id}"
			d3.select(path).property 'value', value

		fillSeaFil = (graph)->
			fillInputData '#count_min',	1
			fillInputData '#count_max', getStrokeCountMax(graph)
			fillInputData '#frq_min',	getFreqMax(graph)
			fillInputData '#frq_max',	1
			fillInputData '#grade_min',	1
			fillInputData '#grade_max',	Object.keys(my.jouyou_grade).length

			# testing
			fillInputData '#kanjistring',	'日,木,森'
			fillInputData '#onyomistring',	'ニチ'
			fillInputData '#kunyomistring', 'ひ,き'
			fillInputData '#meaningstring', 'day'

		fillSeaFil(graph)

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


		getInputInt = (id) ->
			path = "#seafil form #{id}"
			+d3.select(path).property('value').trim()

		getInputArr = (id) ->
			path = "#seafil form #{id}"
			d3.select(path).property('value').trim().split(',')

		getInputData = () ->
			strokeMin 	= getInputInt '#count_min'
			strokeMax 	= getInputInt '#count_max'
			frqMin		= getInputInt '#frq_min'
			frqMax		= getInputInt '#frq_max'
			gradeMin	= getInputInt '#grade_min'
			gradeMax	= getInputInt '#grade_max'
			strKanji 	= getInputArr '#kanjistring'
			strOn 		= getInputArr '#onyomistring'
			strKun 		= getInputArr '#kunyomistring'
			strMean 	= getInputArr '#meaningstring'

			{strokeMin, strokeMax, frqMin, frqMax, gradeMin, gradeMax, strKanji, strOn, strKun, strMean}

		# check if in kanjidata has at least one item of inputdata
		check = (kanjidata, inputdata) ->
			if inputdata.length == 1 and inputdata[0] == ''
				return true
			if kanjidata == undefined
				return false
			for item in inputdata
				if kanjidata.indexOf(item) != -1 and item != ''
					return true
			false

		isWithinCriteria = (k) ->
			{strokeMin, strokeMax, frqMin, frqMax, gradeMin, gradeMax, strKanji, strOn, strKun, strMean} = getInputData()
			withinStroke 	= k.stroke_n >= strokeMin and k.stroke_n <= strokeMax
			withinFrq 		= k.freq <= frqMin and k.freq >= frqMax   #attention: sort upside down
			withinGrade 	= k.grade >= gradeMin and k.grade <= gradeMax
			withinStrKanji 	= check k.kanji, strKanji
			withinStrOn 	= check k.onyomi, strOn
			withinStrKun	= check k.kunyomi, strKun
			withinStrMean	= check k.meaning, strMean

			# check if every criteria fits
			withinStroke and withinFrq and withinGrade and withinStrKanji and withinStrOn and withinStrKun and withinStrMean
			

		filterKanji = ->

			toggleNode = (node, flag) ->
				flag ?= true
				node.style.filtered = flag
				for edge in node.edges
					edge.style.filtered = flag			

			for node in graph.nodes
				toggleNode(node, false)

				if isWithinCriteria(node.data)
					P 'not filtered'
					P node.data.kanji
				else
					toggleNode(node, true)		

			view.update()					

		searchKanji = ->
			resultString = ''
			for node in graph.nodes
				if isWithinCriteria(node.data)
					resultString = "#{resultString} #{node.data.kanji}"
			
			d3.select('table #kanjiresult')[0][0].innerHTML = 'searchresult: #{resultString}'

		body.select('#btn_filter').on 'click' , filterKanji
		body.select('#btn_search').on 'click' , searchKanji
			
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
	
	all_tests = copyAttrs {}, testRouting.tests, testBench.tests
	# tests.run all_tests, []
	console.info 'end of tests'
	loadData main
