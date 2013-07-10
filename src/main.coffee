figue.KMEANS_MAX_ITERATIONS = 1
# the global object where we can put stuff into it
window.my = {
	kanjis: {} 				# "kanji": { "kanji", "radicals", "stroke_n", "freq", "onyomi", "kunyomi", "meaning"}
	radicals: {} 			# "radical" . {"radical", "kanjis"}
	jouyou_radicals: {} 	# "radical" value "kanjikanjikanji"
	jouyou: []				# list of jouyou kanji
	jouyou_grade: {}		# +grade: "kanjis"
	config }

define ['utils', 'load_data', 
	'interactivity', 'routing', 'prepare_data',
	'test_routing', 'test_bench', 'tests'], (
	{ P, somePrettyPrint, styleZoom, async, prettyDebug, copyAttrs },
	loadData, { View }, { MetroMapLayout }, prepare,
	testRouting, testBench, tests
	) ->

	main = () ->
		body = my.body = d3.select 'body'

		if config.debugOverlay
			showDebugOverlay body
		
		svg   = my.svg = body.select 'svg#graph'
		svg.g = svg.append 'g'

		prepare.setupRadicalJouyous()
		prepare.setupKanjiGrades()
		prepare.setupKanjiRadicals(d3.values(my.kanjis), my.radicals)
		radicals = prepare.getRadicals()
		kanjis = prepare.getKanjis radicals
		view = new View { svg, config, kanjis, radicals }
		view.doSlideshow()
			
	showDebugOverlay = (el) ->
		el.append('pre').attr(id:'my').text somePrettyPrint my

	all_tests = copyAttrs {}, testRouting.tests, testBench.tests
	#tests.run all_tests, []
	console.info 'end of tests'
	loadData main
