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
	optimizeMaxLoops:			0
	optimizeMaxSteps:			0
	nodeSize:					12
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


		fillStandardInput = (id, flag) ->
			flag ?= false
			if id == 'btn_clear1' or flag
				fillInputData '#count_min',	1
				fillInputData '#count_max', getStrokeCountMax(graph)
			if id == 'btn_clear2' or flag
				fillInputData '#frq_min',	getFreqMax(graph)
				fillInputData '#frq_max',	1
			if id == 'btn_clear3' or flag
				fillInputData '#grade_min',	1
				fillInputData '#grade_max',	Object.keys(my.jouyou_grade).length




		fillSeaFil = (graph)->
			fillStandardInput('', true)

			# testing
			#fillInputData '#kanjistring',	'日,木,森'
			#fillInputData '#onyomistring',	'ニチ'
			#fillInputData '#kunyomistring', 'ひ,き'
			#fillInputData '#meaningstring', 'day'

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

		getInput = (id) ->
			path = "#seafil form #{id}"
			d3.select(path).property('value').trim()

		getInputData = () ->
			strokeMin 	: getInputInt '#count_min'
			strokeMax 	: getInputInt '#count_max'
			frqMin		: getInputInt '#frq_min'
			frqMax		: getInputInt '#frq_max'
			gradeMin	: getInputInt '#grade_min'
			gradeMax	: getInputInt '#grade_max'
			inKanji 	: getInput '#kanjistring'
			inOn 		: getInput '#onyomistring'
			inKun 		: getInput '#kunyomistring'
			inMean 		: getInput '#meaningstring'


		# check if in kanji valuedata has at least one item of input fielddata
		check = (arrValueData, arrFieldData) ->
			# ignore empty fields
			if arrFieldData == undefined or arrFieldData == ''
				return true
			# exclude unknown kanji
			if arrValueData == undefined
				return false
			
			arrValueData = arrValueData.split ','
			arrFieldData = arrFieldData.split ','

			for item in arrFieldData
				for value in arrValueData
					if value == item and item != ''
						return true
			false

		# TODO: BEAUTIFY ALL THE CODE
		isWithinCriteria = (k, input) ->
			{strokeMin, strokeMax, frqMin, frqMax, gradeMin, gradeMax, inKanji, inOn, inKun, inMean} = input
			withinStroke 	= k.stroke_n >= strokeMin and k.stroke_n <= strokeMax
			withinFrq 		= k.freq <= frqMin and k.freq >= frqMax   #attention: sort upside down
			withinGrade 	= k.grade >= gradeMin and k.grade <= gradeMax
			withinInKanji 	= check k.kanji,   inKanji
			withinInOn 		= check k.onyomi,  inOn
			withinInKun		= check k.kunyomi, inKun
			withinInMean	= check k.meaning, inMean

			# check if every criteria fits
			withinStroke and withinFrq and withinGrade and withinInKanji and withinInOn and withinInKun and withinInMean
			

		filterKanji = ->

			input = getInputData()
			for node in graph.nodes
				if isWithinCriteria(node.data, input)
					node.style.filtered = false
				else
					node.style.filtered = true

			for edge in graph.edges
				nearHidden = edge.source.style.filtered or edge.target.style.filtered 
				if nearHidden 
					edge.style.filtered = true

			view.update()					

		searchKanji = ->
			resultString = ''
			input = getInputData()
			for node in graph.nodes
				node.style.isSearchresult = false
				if isWithinCriteria(node.data, input)
					node.style.isSearchresult = true
					resultString = "#{resultString} #{node.data.kanji}"
			
			d3.select('table #kanjiresult')[0][0].innerHTML = "searchresult: #{resultString}"
			view.update()

		resetFilter = () ->
			id = d3.event.srcElement.id
			fillStandardInput(id)

		body.select('#btn_filter').on 'click' , filterKanji
		body.select('#btn_search').on 'click' , searchKanji
		body.selectAll('#btn_clear1').on 'click' ,  resetFilter
		body.selectAll('#btn_clear2').on 'click' ,  resetFilter
		body.selectAll('#btn_clear3').on 'click' ,  resetFilter
			
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
