config =
	showLines: 					false
	fixedEndstation:			false
	fixedStation:				false
	filterRadicals:				(radicals) -> radicals
	filterLinkedRadicals:		(radicals) -> radicals
	sunflowerKanjis:			true
	kmeansInitialVectorsRandom:	false
	kmeansClustersN:			-1 # 0 rule of thumb, -1 vector.length
	forceGraph:					false
	circularLines:				true
figue.KMEANS_MAX_ITERATIONS = 1

# the global object where we can put stuff into it
window.my = {
	kanjis: {} 				# "kanji": { "kanji", "radicals", "strokes_n", "freq", "onyomi", "kunyomi", "meaning"}
	radicals: {} 			# "radical" . {"radical", "kanjis"}
	jouyou_radicals: {} 	# "radical" value "kanjikanjikanji"
	jouyou: []				# list of jouyou kanji
	jouyou_grade: {}		# +grade: "kanjis"
	config }

define ['utils', 'load_data', 'prepare_data', 'initial_embedding'], (
	{ P, somePrettyPrint, styleZoom },
	loadData, prepare, { setupInitialEmbedding }) ->

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
			.scale(0.03)
			.on 'zoom', styleZoom svg.g, zoom
		draggingStart = -> svg.classed 'dragging', true
		draggingEnd   = -> svg.classed 'dragging', false
		svg.on 'mousedown.cursor' , draggingStart
		svg.on 'mouseup.cursor'   , draggingEnd
		svg.on 'touchstart.cursor', draggingStart
		svg.on 'touchend.cursor'  , draggingEnd
			 
		{ stations, endstations, links } = setupInitialEmbedding config
		setupD3 svg.g, stations, endstations, links

	svgline = d3.svg.line()
		.x(({x}) -> x)
		.y(({y}) -> y)

	endstationSelectLine = (d) ->
		selector = ".radical_"+d.radical.radical
		d3.selectAll(selector).classed 'highlighted', (d) ->
			d.highlighted = !d3.select(@).classed 'highlighted'
		d3.selectAll(".link").sort (a, b) ->
				compareNumber a.highlighted or 0, b.highlighted or 0

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
			.on('click.selectLine', (d) -> endstationSelectLine d)
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
				.on 'tick', -> updatePositions()
			station.call force.drag
			
	loadData main
