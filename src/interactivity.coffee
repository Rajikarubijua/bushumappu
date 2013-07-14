define [
	'utils',
	'tubeEdges',
	'filtersearch',
	'history',
	'central_station',
	'graph',
	'detail_table',
	'station_label',
	'optimizer_client'], (
		utils,
		{Tube, createTubes},
		{FilterSearch},
		{History},
		{CentralStationEmbedder},
		{ Node },
		{DetailTable},
		{ StationLabel },
		{ Optimizer }
) ->
	{P, compareNumber, styleZoom} = utils
	
	colors = [
		"#E53517", #red
		"#008BD0", #blue
		"#97BE0D", #green 
		"#641F80", #violet
		"#F07C0D", #orange 
		"#2FA199", #turquoise
		"#FFCC00", #yellow
		"#E2007A", #pink
		"#290E03"  #brown
	]

	class View
		constructor: ({ svg, @config, @kanjis, @radicals }) ->
			@svg = svg.g
			@parent = svg
			@g_edges = @svg.append('g').attr('id': 'edge_')
			@g_nodes = @svg.append('g').attr('id': 'node_')
			@g_endnodes = @svg.append('g').attr('id': 'ednnode_')
			@g_stationLabels = @svg.append('g').attr('id': 'stationLabel_')
			@zoom = d3.behavior.zoom()
			@history = new History {}
			@detailTable = new DetailTable {}
			@history.setup this
			@embedder = new CentralStationEmbedder { @config }
			@seaFill = new FilterSearch {}

			#setup zoom
			w = new Signal
			h = new Signal
			window.onresize = ->
				w window.innerWidth
				h window.innerHeight
			window.onresize()
			new Observer ->
				attrs = width : 0.95*w(), height: 0.98*h()
				svg.attr attrs
				svg.style attrs
					
			svg.call (@zoom)
				.translate([w()/2, h()/2])
				.scale(@config.initialScale)
				.on('zoom', styleZoom svg.g, @zoom)
			# Deactivates zoom on dblclick. According to d3 source code
			# d3.behavior.zoom registers dblclick.zoom. So we can deactivate it.
			# And we need it to do defered, cause d3 would fail unexpectetly.
			# This hasn't been reported yet.
			svg.on('dblclick.zoom', null)

		autoFocus: (kanji) =>
			focus = {}
			for node in @graph.nodes
				node.style.isFocused = false
				if node.data.kanji == kanji
					node.style.isFocused = true
					focus = node

			if focus == {} or kanji == undefined
				P 'nothing to focus here'
				return

			viewport = d3.select('#graph')[0][0]
			transX =  (viewport.attributes[1].value / 2) - focus.x * @zoom.scale()
			transY =  (viewport.attributes[2].value / 2) - focus.y * @zoom.scale()
			transform = "-webkit-transform: translate(#{transX}px, #{transY}px) scale(#{@zoom.scale()})"

			# apply nice transition
			d3.select('#graph g').transition().attr('style', transform)
			
			# manipulate zoom object for consistency
			@parent.call (@zoom)
				.translate([transX, transY])
				.on('zoom', styleZoom @svg, @zoom, true)
			@parent.on('dblclick.zoom', null)

			@update()

		changeToCentral: (kanji) ->
			return if kanji == @history.getCurrentCentral()

			# delete all stationLabels
			d3.selectAll('.station-label').remove()
			
			P "changeToCentral #{kanji.kanji}"
			@history.addCentral kanji.kanji	
			graph = @embedder.graph kanji, @radicals, @kanjis
			
			@optimizer?.worker.terminate()
			@optimizer = new Optimizer =>
				@optimizer.onNodes = => @update graph
				@optimizer.graph graph
				@optimizer.snapNodes()
				@optimizer.applyRules()

			@seaFill.setup this, false
			
		changeToCentralFromNode: (node) ->	
			@changeToCentral node.data

		changeToCentralFromStr: (strKanji) ->
			strKanji = strKanji.trim()
			central = my.kanjis[strKanji]
			if not central?
				throw "central undefined"
			@changeToCentral central

		doInitial: () ->
			@seaFill.setup this, true

		doSlideshow: () ->
			#d3.select('#overlay').style 'display', 'none'	
			d3.select('#overlay').remove()
			me = this
			do slideshow = ->
				slideshow.steps ?= 0
				return if slideshow.steps++ >= me.config.slideshowSteps
				i = Math.floor Math.random()*me.kanjis.length
				kanji = me.kanjis[i]
				if slideshow.steps == 1
					kanji = my.kanjis[config.debugKanji]
				me.changeToCentral kanji
				setTimeout slideshow, me.config.transitionTime + 2000
	
	
	
	
	
		addStationLabel: (node) =>
			label = new StationLabel { node, @g_stationLabels }
			label.showStationLabel(node)
	
		enterNodes: (enter) ->
			{ addStationLabel, addKanjiDetail } = this
			g_node = enter.append('g').classed('node', true)
			g_station_kanji = g_node.append('g').classed('station-kanji', true)
				.on('mouseenter.delayed-hover', (node) ->  
					setFuncTimer(this, 800, -> addStationLabel node)
				)
				.on('mouseleave.delayed-hover', (node) ->
					clearFuncTimer(this)
				)
				.on('click.addKanjiDetail', (node) ->
					delayDblClick(550, -> addKanjiDetail node)
				)
				.on('dblclick.changeToCentralFromNode', (node) =>
					@changeToCentralFromNode node
				)
			x = y = -config.nodeSize
			width = height = 2*config.nodeSize
			g_station_kanji.append('rect')
				.attr { x, y, width, height }
			g_station_kanji.append('text')
			
		exitNodes: (exit) ->
			exit.remove()
	
		updateNodes: (graph) ->
			nodes = (n for n in graph.nodes when \
				n.kind in ['hi_node','lo_node'])
			
			update = @g_nodes.selectAll('g.node')
				.data(nodes, (node) -> node.key())
			@enterNodes update.enter()
			@exitNodes update.exit()
			
			update
				.attr('id', (node) -> "kanji_"+node.data.kanji)
				.classed("filtered",     (node) -> node.style.filtered)
				.classed("searchresult", (node) -> node.style.isSearchresult)
				.classed("focused",      (node) -> node.style.isFocused)
				.style(fill: (node) -> node.style.debug_fill or null)
				.select('text')
					.text (node) -> node.label()
			update.transition().duration(config.transitionTime)
				.attr(transform: (node) -> utils.cssTranslateXY node)

		addKanjiDetail: (node) =>
				@detailTable.addKanji node.data
				@toggleMenu(true)
				d3.selectAll('#details td.content')
					.on 'click.hightlightSelected', (node) =>
						@autoFocus node
				
		removeKanjiDetail: (node) =>
			@detailTable.removeKanji node.data
			d3.event.stopPropagation()
			d3.selectAll('#details td.content')
				.on 'click.hightlightSelected', (node) =>
					@autoFocus node
		
		toggleMenu: (shouldStayOpen) =>
				shouldStayOpen ?= false
				bar = d3.select('#bottomBar')
				toggleBtn = d3.select('#toggle-bottom-bar')
				arrow = toggleBtn.select('.arrowIcon')
				if bar.node().clientHeight > 11 and !shouldStayOpen
					bar.style('max-height', '10px')
					arrow.classed('up', true)
					arrow.classed('down', false)
				else
					bar.style('max-height', '200px')
					arrow.classed('down', true)
					arrow.classed('up', false)
		
		
		
		
		
		
		update: (graph) ->
			@graph = graph if graph
			@updateNodes @graph
			
			{ svg, config, g_edges, g_nodes, g_endnodes, g_stationLabels } = this
			{ nodes, lines, edges } = @graph

			endnodes = (node for node in nodes when node.data.radical)
			central_node = (node for node in nodes when node.kind == 'central_node')
			if central_node.length > 1
				throw 'cant handle more than one central node'
			central_node = central_node[0]
			@updateCentralNode central_node
			nodes = (node for node in nodes when node not in endnodes and node != central_node)
			table = d3.select('table#details tbody')
			table_data = [[],[],[],[],[]]
			
			# remove minilabels
			minilabels = d3.selectAll(".mini-label")
			minilabels.remove()

			# join
			edge = g_edges.selectAll(".edge")
				.data(edges)
			endnode = g_endnodes.selectAll('.endnode')
				.data(endnodes, (node) -> node.key())
			
			# enter
			d3.select('#toggle-bottom-bar').on('mouseenter.bottomBarToggle', @toggleMenu)

			edge.enter()
				#.append("g")
				.append("path")
				.classed("edge", true)
				# for transitions; nodes start at 0,0. so should edges
				.attr d: (d) -> "M0,0"
			
			endnode_g = endnode.enter()
				.append('g')
				.classed("endnode", true)
				.on('click.selectLine', (d) -> endnodeSelectLine d)
			endnode_g.append("circle").attr {r : config.nodeSize}
			endnode_g.append("text").text (d) -> d.label()
		
			# update
			radicals = []
			edge.each (d) ->
				{ radical } = d.line.data
				cls = "line_" + radical
				d3.select(@).classed(cls, true)
				radicals.push radical if radical not in radicals
			for rad in radicals
				selector = ".line_" + rad
				d3.selectAll(selector)
					.style stroke: colors[radicals.indexOf(rad)]
			edge.each (d) ->
				if d.style.debug_stroke
					d3.select(@).style stroke: d.style.debug_stroke
			i = 0
			edge.transition().duration(config.transitionTime)
				.attr d: (d) -> svgline01 d.coords()
			that = this
			edge.each (d) -> 
				if d.tube.id % 5 == 0
					that.createMiniLabel d, this, radicals
			edge.classed("filtered", (d) -> d.style.filtered)

			endnode.transition().duration(config.transitionTime)
				.attr transform: (d) -> "translate(#{d.x} #{d.y})"

			# exit
			edge.exit().remove()
			endnode.exit().remove()
			
		createMiniLabel: (edge, dom, radicals) ->
			parent = d3.select(dom.parentNode)
			{ line, tube } = edge 
			rad = line.data.radical 
			color = colors[radicals.indexOf(rad)]
			i = tube.edges.indexOf(edge) - tube.edges.length/2
			length = edge.length() / 2
			x_mid = tube.x + length * Math.cos tube.angle
			y_mid = tube.y + length * Math.sin tube.angle
			x = x_mid + 8 * i * Math.cos tube.angle
			y = y_mid + 8 * i * Math.sin tube.angle
			x += (tube.width+5) * Math.cos tube.angle + 0.5*Math.PI
			y += (tube.width+5) * Math.sin tube.angle + 0.5*Math.PI
			grad = tube.angle / 2/Math.PI * 360
			grad = if (Math.round grad/45) % 2 == 0 then 0 else -45
			parent.append("text").classed("mini-label", true)
				.text(rad)
				.style(
					"font-size": "8px"
					"font-anchor": "middle"
					"alignment-baseline": "central")
				.attr
					fill: "#{color}"
					transform: "translate(#{x} #{y}) rotate(#{grad}, #{x}, #{y})"
		
		updateCentralNode: (node) ->
			d3.select('#central-node').remove()
			update_central_node = @svg.selectAll('#central-node').data([node])
			enter_central_node = update_central_node.enter()
			exit_central_node  = update_central_node.exit()
			central_label = node.label()
			central_meaning = node.data.meaning or "–"
			central_freq = node.data.freq or "–"
			central_strokes = node.data.stroke_n or "–"
			central_grade = node.data.grade or "–"
			central_on = node.data.onyomi or "–"
			central_kun = node.data.kunyomi or "–"
			central_history = @history.render() or "–"
			central_g = enter_central_node.append('g').attr('id': 'central-node')
			central_g.append('foreignObject')
					.attr(x: -120, y: -200)
					.attr(width: 246, height: 400)
				.append('xhtml:body')
					.style('background', 'white')
					.style('border', 'solid black 1px')
					.html("
					 <div class='centralStation'>
						<div class='firstBlock'>
							<div id='kKanji'>" + central_label + "</div>
							<table>
								<tr>
									<td>Strokecount</td>
									<td id='kCount'>" + central_strokes + "</td>
								</tr>
								<tr>
									<td>Frequency</td>
									<td id='kFreqency'>" + central_freq + "</td>
								</tr>
								<tr>
									<td>Schoolgrade</td>
									<td id='kGrade'>" + central_grade + "</td>
								</tr>
							</table>
						</div> 
						<div class='secondBlock'>
							<div id='kMeaning'>" + central_meaning + "</div>
							<div id='kOn'>" + central_on + "</div>
							<div id='kKun'>" + central_kun + "</div>
						</div>
						<div id='history'>
						" + central_history + "
						</div>
					</div>
					 ")
					
			exit_central_node.remove()

			me = this
			onClick = () ->
				kanji = this.innerHTML
				me.changeToCentralFromStr kanji

			d3.selectAll(".#{@history.nclass}").on 'click.history', onClick
				
	
	svgline = d3.svg.line()
		.x(({x}) -> x)
		.y(({y}) -> y)
		
	svgline01 = d3.svg.line()
		.x( (d) -> d[0])
		.y( (d) -> d[1])


	# this function sets a timer for the stationlabel to be displayed
	# this means that after a certain time after the mouse entered the node
	# the label will be displayed, not right away
	setFuncTimer = ( obj, ms, func) ->
		obj.funcTimer = setTimeout(((d) -> func d), ms)
		
	
	clearFuncTimer = (obj) ->	
		clearTimeout(obj.funcTimer)
		obj.funcTimer = null
	
	# this function delays a double click event and takes the delay in ms as 
	# well as the function to be called after the timeout as a parameter
	delayDblClick = (ms, func) ->
		if @clickTimer 
			clearTimeout(@clickTimer)
			@clickTimer = null
		else 
			@clickTimer = setTimeout(((d)-> 
				@clickTimer = null
				func d), ms)

	endnodeSelectLine = (d) ->
		selector = ".line_"+d.data.radical
		d3.selectAll(selector).classed 'highlighted', (d) ->
			d.highlighted = !d3.select(@).classed 'highlighted'
		d3.selectAll(".edge").sort (a, b) ->
				compareNumber a.highlighted or 0, b.highlighted or 0


	{ View}
