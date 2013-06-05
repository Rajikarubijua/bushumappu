config =
	showLines: 			false
	fixedEndstation:	true
	fixedStation:		true
	filterRadicals:		(radicals) -> radicals
	sunflowerKanjis:	false
	kmeansInitialVectorsRandom: false
	clustering:			false

# the global object where we can put stuff into it
window.my = {
	kanjis: {} 				# "kanji": { "kanji", "radicals", "strokes_n", "freq", "onyomi", "kunyomi", "meaning"}
	radicals: {} 			# "radical" . {"radical", "kanjis"}
	jouyou_radicals: {} 	# "radical" value "kanjikanjikanji"
	jouyou: []				# list of jouyou kanji
	jouyou_grade: {}		# +grade: "kanjis"
	config }

define ['utils', 'load_data'], ({ P, PN, W, copyAttrs, async, strUnique,
	somePrettyPrint, length, sort, styleZoom, sunflower, vecX, vecY, vec,
	compareNumber }, load_data) ->

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



	drawStuff = (svg) ->
		w = svg.attr 'width'
		h = svg.attr 'height'
		r = 12
		d = 2*r

		jouyou_kanjis = []
		for radical, kanjis of my.jouyou_radicals
			kanjis = (my.kanjis[k] for k in kanjis)
			my.radicals[radical].jouyou = kanjis
			for k in kanjis
				if k not in jouyou_kanjis
					jouyou_kanjis.push k
			
		for grade, kanjis of my.jouyou_grade
			for kanji in kanjis
				my.kanjis[kanji].grade = +grade
				
		
		radicals = (my.radicals[radical] for radical of my.jouyou_radicals)
		radicals.sort (x) -> x.radical
		radicals_n = length radicals
		
		kanjis = jouyou_kanjis
		kanjis.sort (x) -> x.kanji
		
		if config.clustering
		
			for kanji in kanjis
				kanji.vector = []
				for radical, radical_i in radicals
					kanji.vector[radical_i] = +(radical.radical in kanji.radicals)
		
			if config.kmeansInitialVectorsRandom
				initial_vectors = undefined 
			else
				vectors = (k.vector for k in kanjis)
				step = Math.floor vectors.length/radicals_n
				initial_vectors = (vectors[i*step] for i in [0...radicals_n])
		
			vectors = (k.vector for k in kanjis)
			{ centroids, assignments } =
				figue.kmeans radicals_n, vectors, initial_vectors
			clusters = ({ centroid, kanjis: [] } for centroid in centroids)
			for assignment, assignment_i in assignments
				cluster = clusters[assignment]
				kanji   = kanjis[assignment_i]
				kanji.cluster = cluster
				cluster.kanjis.push kanji
		
			for cluster, cluster_i in clusters
				cluster.x = cluster_i * d*3
				cluster.y = 0
		
		for _, k of my.kanjis
			k.station = { label: k.kanji, ybin: k.grade }
			
		for kanji, kanji_i in kanjis
			x = y = undefined
			if config.sunflowerKanjis
				{ x, y } = sunflower { index: kanji_i+1, factor: 2.7*d }
			else if config.clustering
				x = kanji.cluster.x
				y = kanji.cluster.y + 3*d* kanji.cluster.kanjis.indexOf kanji
			kanji.station.x = x
			kanji.station.y = y
		
		radicals = config.filterRadicals radicals
		
		all_links = []
		all_nodes = []
		all_lines = []
		for radical, i in radicals
			{ nodes, links, line } = makeLine radical, i, radicals, d
			all_links = all_links.concat links
			all_nodes = all_nodes.concat nodes
			all_lines.push line
		
		force = d3.layout.force()
			.nodes(all_nodes)
			.links(all_links)
			.size([w, h])
			.linkStrength(0.1)
			.linkDistance(8*d)
			.charge(-10)
			.gravity(0.001)
			.theta(10)
			.start()

		line = svg.selectAll('.line')
			.data(lines = all_lines)
			.enter()
			.append 'g'
			
		svgline = d3.svg.line()
			.x(({x}) -> x)
			.y(({y}) -> y)
			
		links = line.selectAll(".links")
			.data((d) -> if config.showLines then [d] else [])
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
	
	makeLine = (radical, i, radicals, d) ->
		radicals_n  = length radicals
		endstation  = { label: radical.radical, fixed: +config.fixedEndstation }
		stations    = (k.station for k in radical.jouyou)
		line_radius = 3000
		line_angle  = (i/radicals_n) * 2*Math.PI + Math.PI/2
	
		ybins = {}
		for station in stations
			station.fixed = +config.fixedStation
			ybins[station.ybin] ?= []
			ybins[station.ybin].push station
		
		[ x, y ] = vec line_radius, line_angle
		for bin, bin_i in sort(ybins, compareNumber)
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
	
	load_data main
