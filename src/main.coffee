require ['utils'], ({ P, W, copyAttrs, async, strUnique, somePrettyPrint,
	length, sort, styleZoom }) ->

	# the global object where we can put stuff into it
	window.my = 
		kanjis: {}
		radicals: {}

	load = (cb) ->
		# load ALL the data concurrently
		async.map {
			krad: (cb) -> d3.text "data/krad", cb
			radk: (cb) -> d3.text "data/radk", cb
			# XXX radk doesn't contain radicals "邑龠" which are in krad
			}, cb
			
	parse = (data) ->
		parseKrad data.krad[1]
		parseRadk data.radk[1]

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
			.on 'zoom', styleZoom svg.g, zoom
			 
		drawStuff svg.g

	parseKrad = (content) ->
		lines = content.split '\n'

		for line, i in lines
			# parse line
			continue if line[0] == '#' || !line
			kanji = line[0]
			if line[1..3] != ' : '
				throw "expected \" : \" at line #{i}, got \"#{line[1..3]}\""
			radicals = line[4..].trim().split ' '
			# fill datastructures
			o = my.kanjis[kanji] ?= { kanji }
			o.radicals = radicals
			for radical in radicals
				o = my.radicals[radical] ?= { radical }
				o.kanjis ?= ""
				o.kanjis += kanji

	parseRadk = (lines) ->
		radical = null
		strokes_n = null
		kanjis = ""
		$line = /\$ (.) (\d+) ?.*/
	
		for line, i in lines
			# parse line
			continue if line[0] == '#' || !line
			m = line.match $line
			if m == null
				kanjis += line.trim()
			else
				if radical
					radical.strokes_n = +strokes_n
					radical.kanjis = strUnique radical.kanjis, kanjis
				[ _, radical, strokes_n ] = m
				radical = my.radicals[radical]

	drawStuff = (svg) ->
		w = svg.attr 'width'
		h = svg.attr 'height'

		radicals_n = length my.radicals
		nodes = for radical, i in sort my.radicals
				c = radicals_n * 1/16
				af = 55/144 * 2*Math.PI
				r = c * Math.sqrt i
				a = i * af
				x = r * Math.cos a
				y = r * Math.sin a
				x += w/2
				y += h/2
				{ radical, x, y }
		links  = []

		force = d3.layout.force()
			.nodes(nodes)
			.links(links)
			.size([w, h])
			.start()

		radical = svg.selectAll('.'+cls='radical')
			.data(nodes)
			.enter()
			.append('g')
			.attr(class: cls)
		radical
			.append("circle").attr(r: 12)
		radical
			.append("text").text((d) -> d.radical)
			.style "alignment-baseline": 'central', "text-anchor": "middle"
		
		force.on 'tick', (e) ->
			radical.attr('transform', (d) -> "translate(#{d.x} #{d.y})")
	
	load (data) ->
		parse data
		main()
