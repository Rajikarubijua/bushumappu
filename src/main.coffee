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

		fillSeaFil = (graph)->
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

			# testing
			form.select('#kanjistring').attr('value', '日,木,森')
			form.select('#onyomistring').attr('value', 'ニチ')
			form.select('#kunyomistring').attr('value', 'ひ,き')
			form.select('#meaningstring').attr('value', 'day')

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

		filterKanji = ->
			strokeMin 	= getInputInt '#count_min'
			strokeMax 	= getInputInt '#count_max'
			frqMin		= getInputInt '#frq_min'
			frqMax		= getInputInt '#frq_max'
			gradeMin	= getInputInt '#grade_min'
			gradeMax	= getInputInt '#grade_max'
			#jlptMin	= getInputInt '#jlpt_min'
			#jlptMax	= getInputInt '#jlpt_max'
			strKanji 	= getInputArr '#kanjistring'
			strOn 		= getInputArr '#onyomistring'
			strKun 		= getInputArr '#kunyomistring'
			strMean 	= getInputArr '#meaningstring'


			hideNode = (node, flag) ->
				flag ?= true
				node.style.filtered = flag
				for edge in node.edges
					edge.style.filtered = flag

			check = (kanjidata, inputdata) ->
				if inputdata.length == 1 and inputdata[0] == ''
					return true
				if kanjidata == undefined
					return false
				for item in inputdata
					if kanjidata.indexOf(item) != -1 and item != ''
						return true
				false

			for node in graph.nodes
				hideNode(node, false)
				k = node.data
				withinStroke 	= k.stroke_n >= strokeMin and k.stroke_n <= strokeMax
				withinFrq 		= k.freq <= frqMin and k.freq >= frqMax   #attention: sort upside down
				withinGrade 	= k.grade >= gradeMin and k.grade <= gradeMax
				withinJLPT		= true
				withinStrKanji 	= check k.kanji, strKanji
				withinStrOn 	= check k.onyomi, strOn
				withinStrKun	= check k.kunyomi, strKun
				withinStrMean	= check k.meaning, strMean

				if !withinStroke or !withinFrq or !withinGrade or !withinJLPT or !withinStrKanji or !withinStrOn or !withinStrKun or !withinStrMean
					hideNode(node, true)	
				else
					P 'show'
					P k.kanji

			view.update()
					

		searchKanji = ->
			P 'hello search'
			view.update()

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
