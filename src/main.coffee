require ['utils'], ({ P, PN, W, copyAttrs, async, strUnique, somePrettyPrint,
	length, sort, styleZoom, sunflower, vecX, vecY, vec }) ->

	# the global object where we can put stuff into it
	window.my = 
		kanjis: {} 				# "kanji": { "kanji", "radicals"}
		radicals: {} 			# "radical" . {"radical", "kanjis"}
		jouyou_radicals: {} 	# "radical" value "kanjikanjikanji"
		jouyou: []				# list of jouyou kanji
		jouyou_grade: {}		# +grade: "kanjis"

	load = (cb) ->
		# load ALL the data concurrently
		async.map {
			krad: (cb) -> d3.text "data/krad", cb
			radk: (cb) -> d3.text "data/radk", cb
			# XXX radk doesn't contain radicals "邑龠" which are in krad
			jouyou: (cb) -> d3.text "data/jouyou", cb
			}, cb
			
	parse = (data) ->
		parseKrad 	data.krad[1]
		parseRadk 	data.radk[1]
		parseJouyou data.jouyou[1]

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
			.scale(0.12)
			.on 'zoom', styleZoom svg.g, zoom
		draggingStart = -> svg.classed 'dragging', true
		draggingEnd   = -> svg.classed 'dragging', false
		svg.on 'mousedown.cursor' , draggingStart
		svg.on 'mouseup.cursor'   , draggingEnd
		svg.on 'touchstart.cursor', draggingStart
		svg.on 'touchend.cursor'  , draggingEnd
			 
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

	parseJouyou = (content) ->
		lines = content.split '\n'
		allkanji = ""

		for line, i in lines
			# parse line
			continue if line[0] == '#' || !line
			# fill data
			grade  = +line.match /^\d+/
			kanjis = (line.match /:(.*)$/)[1]
			my.jouyou_grade[grade] = kanjis
			allkanji += kanjis

		for char in allkanji
			my.jouyou.push char
			for radical in my.kanjis[char].radicals
				my.jouyou_radicals[radical] ?= ""
				my.jouyou_radicals[radical] += char



	drawStuff = (svg) ->
		w = svg.attr 'width'
		h = svg.attr 'height'
		r = 12
		d = 2*r

		for radical, kanjis of my.jouyou_radicals
			kanjis = (my.kanjis[k] for k in kanjis)
			my.radicals[radical].jouyou = kanjis
			
		for grade, kanjis of my.jouyou_grade
			for kanji in kanjis
				my.kanjis[kanji].grade = +grade
				
		
		radicals = (my.radicals[radical] for radical of my.jouyou_radicals)
		radicals.sort (x) -> x.radical
		radicals_n = length radicals
		
		for _, k of my.kanjis
			k.station = { label: k.kanji, ybin: k.grade }
			
		for kanji, kanji_i in my.jouyou
			kanji = my.kanjis[kanji]
			{ x, y } = sunflower { index: kanji_i, factor: 2.7*d }
			kanji.station.x = x
			kanji.station.y = y
		
		all_links = []
		all_nodes = []
		all_lines = []
		for radical, i in radicals ####
			{ nodes, links, line } = makeLine radical, i, radicals, d
			all_links = all_links.concat links
			all_nodes = all_nodes.concat nodes
			all_lines.push line
		
		force = d3.layout.force()
			.nodes(all_nodes)
			.links(all_links)
			.size([w, h])
			.charge(-90)
			.gravity(0.05)
			.start()

		line = svg.selectAll('.line')
			.data(lines = all_lines)
			.enter()
			.append 'g'
			
		svgline = d3.svg.line()
			.x(({x}) -> x)
			.y(({y}) -> y)
			
		links = line.selectAll(".links")
			.data((d) -> [ ]) # XXX put in 'd' if you like
			.enter().append 'g'
			
		link = links.selectAll(".link")
			.data((d) -> d.links)
			.enter()
			.append "path"
			
		endstation = line.selectAll('.endstation')
			.data((d) -> [ d.endstation ])
			.enter()
			.append 'g'
		
		station = line.selectAll('.station')
			.data((d) -> d.stations)
			.enter()
			.append('g')
			.call(force.drag)

		station.append('rect').attr x:-r, y:-r, width:2*r, height:2*r
		station.append('text').text (d) -> d.label
			
		endstation.append("circle").attr {r}
		endstation.append("text").text (d) -> d.label
		
		force.on 'tick', (e) ->
			link.attr d: (d) -> svgline [ d.source, d.target ]
			endstation.attr transform: (d) -> "translate(#{d.x} #{d.y})"
			station.attr transform: (d) -> "translate(#{d.x} #{d.y})"
			
		force.start()
	
	makeLine = (radical, i, radicals, d) ->
		radicals_n  = length radicals
		endstation  = { label: radical.radical, fixed: 1 }
		stations    = (k.station for k in radical.jouyou)
		line_radius = 3000
		line_angle  = (i/radicals_n) * 2*Math.PI + Math.PI/2
	
		ybins = {}
		for station in stations
			station.fixed = 1
			ybins[station.ybin] ?= []
			ybins[station.ybin].push station
		
		[ x, y ] = vec line_radius, line_angle
		for bin, bin_i in sort(ybins, (a,b) -> -(a<b) or a>b or 0)
			ybin_stations = ybins[bin]
			bin = +bin
			n = ybin_stations.length
			for station, station_i in ybin_stations
		# placement of a station
				if not station.x?
					radius = (line_radius -
						(2*d * (1 + Math.floor station_i/9)) - # row in a bin
						(bin_i * (Math.floor n/9) * 2*d))      # bin rows
					angle  = line_angle +
						2*d * (station_i%9 - 4)*0.0003 # column in a bin
					station.x = vecX radius, angle
					station.y = vecY radius, angle
	
		# placement of a endstation
		endstation.x = x
		endstation.y = y
	
		line = { endstation, stations }
		nodes = [ line.endstation, line.stations... ]
	
		#for node, index in nodes
			#node.fixed = 1
			# possible attributes for node:
			# https://github.com/mbostock/d3/wiki/Force-Layout#wiki-nodes
	
		links = []
		node = nodes[0]
		for next in nodes[1..]
			links.push { source: node, target: next }
			node = next
		line.links = links
		{ nodes, links, line }
	
	getNiceRadical = (radicals) ->
		for r in radicals
			for k in r.jouyou
				if k.grade == 1
					return r
		return radicals[0]
	
	load (data) ->
		parse data
		main()
