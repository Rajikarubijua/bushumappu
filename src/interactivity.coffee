define ['utils', 'tubeEdges', 'filtersearch', 'history', 'central_station'], 
({ P, compareNumber, styleZoom }, {Tube, createTubes}, {FilterSearch}, {History}, {CentralStationEmbedder}) ->

	class View
		constructor: ({ svg, @config, @kanjis, @radicals }) ->
			@svg = svg.g
			@parent = svg
			@g_edges = @svg.append 'g'
			@g_nodes = @svg.append 'g'
			@g_endnodes = @svg.append 'g'
			@zoom = d3.behavior.zoom()
			@history = new History {}
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
	
		colors = ["#E53517", "#008BD0", "#97BE0D", "#641F80", "#F07C0D", "#2FA199", "#FFCC00", "#E2007A", "#290E03"]

		autoFocus: (kanji) ->
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

			@update graph
			@seaFill.setup this, false
			
		changeToCentralFromNode: (node) ->	
			@changeToCentral node.data

		changeToCentralFromStr: (strKanji) ->
			strKanji = strKanji.trim()
			central = {}
			for k in @kanjis
				if k.kanji == strKanji
					central = k

			if central.kanji == undefined or strKanji == ''
				P "cannot set central (#{strKanji}) that is not in kanjis"
				P @kanjis
				return
	
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
				me.changeToCentral kanji
				setTimeout slideshow, me.config.transitionTime + 2000
	
		update: (graph) ->
			@graph = graph if graph
			{ svg, config, g_edges, g_nodes, g_endnodes } = this
			{ nodes, lines, edges } = @graph
			r = config.nodeSize
			
			that = this

			for node in nodes
				node.label ?= node.data.kanji or node.data.radical or "?"
			endnodes = (node for node in nodes when node.data.radical)
			nodes = (node for node in nodes when node not in endnodes)
			table = d3.select('table#details tbody')
			tablehead = d3.select('thead').selectAll('tr')
			table_data = [[],[],[],[],[]]
			
			#remove minilabels
			minilabels = d3.selectAll(".mini-label")
			minilabels.remove()

			# join
			edge = g_edges.selectAll(".edge")
				.data(edges)
			node = g_nodes.selectAll('.node')
				.data(nodes)
			endnode = g_endnodes.selectAll('.endnode')
				.data(endnodes)
			table_tr = table.selectAll('tr')
				.data(table_data)
			colLabels = d3.select('table#details tbody').select('tr').selectAll('td')
			
			# enter
			closeStationLabel = (d) ->
				this.parentNode.stationLabel = undefined
				d3.select(this).remove()
			
			showStationLabel = (node, edges) ->
				return if this.parentNode.stationLabel
				stationLabel = d3.select(this.parentNode).append('g').classed("station-label", true)
					.on('click.closeLabel', closeStationLabel)
				edgeAngles = []
				index = 0
				for e in edges[0][0]
					a = edges[0][0][index].getEdgeAngle()
					r_a = Math.round(a / (0.25*Math.PI))
					edgeAngles.push(r_a)
					index++
				if 0 in edgeAngles and -1 in edgeAngles
					stationLabelAngle = 0
				else if 0 in edgeAngles or 4 in edgeAngles
					stationLabelAngle = -45
				else if -2 in edgeAngles or 0 in edgeAngles
					stationLabelAngle = 0
				else
					stationLabelAngle = 0
				label_rect = stationLabel.append('rect')
					.attr(x:24, y:-config.nodeSize-3)
					.attr(transform: "rotate(#{stationLabelAngle})")
				label_text = stationLabel.append('text')
					.text((d) -> d.data.meaning or '?')
					.attr(x:28, y:-config.nodeSize/2+4)
					.attr(transform: "rotate(#{stationLabelAngle})")
				rectLength = label_text.node().getBBox().width + 8
				label_rect.attr(width: rectLength, height: 2.5*config.nodeSize) # inflating the rectangle
				this.parentNode.stationLabel = stationLabel
				
			
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
				if that.clickTimer 
					clearTimeout(that.clickTimer)
					that.clickTimer = null
				else 
					that.clickTimer = setTimeout(((d)-> 
						that.clickTimer = null
						func d), ms)
			
			thisView = this
			selectKanjiDetail = (d) ->
				i = 1
				nothingtodo = false
				for k in colLabels[0]
					item = colLabels[0][i]
					if item == undefined
						break
					if item.textContent == d.label
						nothingtodo = true;
						break
					i++

				radicals = []
				radicals = (r.radical for r in d.data.radicals)
				
				if(!nothingtodo)
					table_data[0].push d.label
					table_data[1].push d.data.meaning
					table_data[2].push radicals
					table_data[3].push d.data.onyomi
					table_data[4].push d.data.kunyomi
				
				# enter
				table_td = table_tr.selectAll('td.content')
					.data((d) -> d)
					
				if(!nothingtodo)
					table_tr.enter()
						.append('tr')
						.classed('content', true) # xxx
					
					table_td.enter()
						.append('td')
						.classed("content", true)
				
				tablecontentcols = table.select('tr').selectAll('td')[0].length
				tableheadcols = tablehead.selectAll('th')[0].length
				if tableheadcols < tablecontentcols
					tablehead.append('th')
				
				# update	
				table_td.text((d) -> d)
				colLabels = d3.select('table#details tbody').select('tr').selectAll('td')
					.on('mouseenter.hoverLabel', (d) -> 
						that = this
						setFuncTimer(that, 1000, -> displayDeleteTableCol.call(that, d)))
					.on('mouseleave.resetHoverLabel', (d) ->
						clearFuncTimer(this)
						d3.select(d3.event.srcElement.childNodes[1]).remove())
 					.on('click.hightlightSelected', (d) -> thisView.autoFocus d)
			
				
			removeKanjiDetail = (d) ->
				d3.event.stopPropagation()
				index = 0
				for label in table_data[0]
					item = table_data[0][index]
					if item == d
						break
					else
						index++
				
				i = 0
				for row in table_data
					table_data[i].splice(index,1)
					if table.selectAll('tr').selectAll('td')[i][index+1]
						table.selectAll('tr').selectAll('td')[i][index+1].remove()
					i++
				if tablehead.selectAll('th')[0][index+1]
					tablehead.selectAll('th')[0][index+1].remove()
				table_td = table_tr.selectAll('td.content')
					.text((d) -> d)
				
					
			displayDeleteTableCol = (d) ->
				# do not display this for the very first column 
				# that contains description text
				return if d == undefined
				# we only need 1 button
				return if d3.select(this).selectAll('g')[0].length != 0
				
				removeBtn = d3.select(this).append('g').classed('remove-col-btn', true)
				removeBtn.append('text').text('x')
				removeBtn.on('click.removeTableCol', (d) -> removeKanjiDetail(d))
				this.removeBtn = removeBtn
			
			removeDeleteTableCol = (d) ->
				return if not this.removeBtn
				this.removeBtn.remove()

			thisView = this

			edge.enter()
				#.append("g")
				.append("path")
				.classed("edge", true)
				# for transitions; nodes start at 0,0. so should edges
				.attr d: (d) -> svgline [ {x:0,y:0}, {x:0,y:0} ]
			node_g = node.enter()
				.append('g')
				.classed("node", true)
			stationKanji = node_g.append('g')
				.classed("station-kanji", true)
				.attr('id', (d) -> "kanji_"+d.data.kanji)
				.on('mouseenter.showLabel', (d) ->  
					edges = d3.select(this.parentNode.__data__.edges)
					that = this
					setFuncTimer(that, 800, -> showStationLabel.call(that, d, edges)))
				.on('mouseleave.resetHoverTimer', (d) ->
					clearFuncTimer(this))
				.on('click.displayDetailsOfNode', (d) ->
					that = this
					delayDblClick(550, -> selectKanjiDetail.call(that, d))
					)
				.on('dblclick.selectnewCentral', (d) -> thisView.changeToCentralFromNode d )
			stationKanji.append('rect').attr x:-config.nodeSize, y:-config.nodeSize, width:2*config.nodeSize, height:2*config.nodeSize
			stationKanji.append('text')
	

			endnode_g = endnode.enter()
				.append('g')
				.classed("endnode", true)
				.on('click.selectLine', (d) -> endnodeSelectLine d)
			endnode_g.append("circle").attr {r : config.nodeSize}
			endnode_g.append("text").text (d) -> d.label
		
			# update
			radicals = []
			edge.each (d) ->
				d3.select(@).attr("class", "edge line_" + d.line.data.radical)
				radicals.push d.line.data.radical if d.line.data.radical not in radicals
			for rad in radicals
				selector = ".line_" + rad
				d3.selectAll(selector).style("stroke", colors[radicals.indexOf(rad)])
			i = 0
			edge.transition().duration(config.transitionTime)
				.attr d: (d) -> 
					i++
					svgline01 createTubes d, i
			edge.each (d) ->
				if d.tube.id % 5 is 0
					thisparent = d3.select(@.parentNode)
					rad = d.line.data.radical 
					color = colors[radicals.indexOf(rad)]
					#P color + "  " +  rad
					posx = d.tube.posx + d.tube.edges.indexOf(d) * d.tube.placecos
					posy = d.tube.posy + d.tube.edges.indexOf(d) * d.tube.placesin
					thisparent.append("text").classed("mini-label", true)
						.text(rad)
						.attr(x: posx, y: posy)
						.attr(fill: "#{color}")
						.attr(style: "font-size: 8px")
						.attr(transform: "rotate(#{d.tube.anglegrad}, #{posx}, #{posy})")
			edge.classed("filtered", (d) -> d.style.filtered)
			node.classed("filtered", (d) -> d.style.filtered)
			node.classed("searchresult", (d) -> d.style.isSearchresult)
			node.classed("focused", (d) -> d.style.isFocused)
			node_t = node.transition().duration(config.transitionTime)
			node_t.attr(transform: (d) -> "translate(#{d.x} #{d.y})")
			#node_t.style(fill: (d) -> if d.style.hi then "red" else if d.style.lo then "green" else null) # debug @payload
			node_t.select('text').text (d) -> d.label

			endnode.transition().duration(config.transitionTime)
				.attr transform: (d) -> "translate(#{d.x} #{d.y})"
				
			toggleBtn = d3.select('#toggle-bottom-bar')
				.on('mouseenter.bottomBarToggle', (d) ->
					if d3.select('#bottomBar')[0][0].clientHeight > 11
						d3.select('#bottomBar').style('max-height', '10px')
					else
						d3.select('#bottomBar').style('max-height', '200px')
						
					)
			# exit
			edge.exit().remove()
			node.exit().remove()
			endnode.exit().remove()

			if config.forceGraph
				force = d3.layout.force()
					.nodes([nodes..., endnodes...])
					.edges(edges)
					.edgeStrength(1)
					.edgeDistance(8*r)
					.charge(-3000)
					.gravity(0.001)
					.start()
					.on 'tick', -> updatePositions()
				node.call force.drag
			
	svgline = d3.svg.line()
		.x(({x}) -> x)
		.y(({y}) -> y)
		
	svgline01 = d3.svg.line()
		.x( (d) -> d[0])
		.y( (d) -> d[1])
	

	endnodeSelectLine = (d) ->
		selector = ".line_"+d.data.radical
		d3.selectAll(selector).classed 'highlighted', (d) ->
			d.highlighted = !d3.select(@).classed 'highlighted'
		d3.selectAll(".edge").sort (a, b) ->
				compareNumber a.highlighted or 0, b.highlighted or 0


	{ View}
