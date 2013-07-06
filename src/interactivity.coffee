define ['utils', 'tubeEdges'], ({ P, compareNumber }, {createTubes}) ->

	class View
		constructor: ({ @svg, @graph, @config }) ->
			@g_edges = @svg.append 'g'
			@g_nodes = @svg.append 'g'
			@g_endnodes = @svg.append 'g'
	
		colors = ["red", "blue", "green", "purple", "brown", "orange", "teal", "yellow", "pink"]

		autoFocus: (kanji) ->
			focus = {}
			for node in @graph.nodes
				if node.data.kanji == kanji
					focus = node

			if focus == {} or kanji == undefined
				P 'nothing to focus here'
				return
			viewport = d3.select('#graph')[0][0]
			transX = (viewport.attributes[1].value / 2) - focus.x
			transY = (viewport.attributes[2].value / 2) - focus.y
			transform = "-webkit-transform: translate(#{transX}px, #{transY}px) scale(1)"

			d3.select('#graph g').transition().attr('style', transform)
			
	
		update: (graph) ->
			@graph = graph if graph
			{ svg, config, g_edges, g_nodes, g_endnodes } = this
			{ nodes, lines, edges } = @graph
			r = config.nodeSize
			
			that = this

			radicals = []			
			for node in nodes
				node.label ?= node.data.kanji or node.data.radical or "?"
				radicals.push node.data.radical if node.data.radical not in radicals
			endnodes = (node for node in nodes when node.data.radical)
			nodes = (node for node in nodes when node not in endnodes)

			# join
			edge = g_edges.selectAll(".edge")
				.data(edges)
			node = g_nodes.selectAll('.node')
				.data(nodes)
			endnode = g_endnodes.selectAll('.endnode')
				.data(endnodes)
			
			# enter
			closeStationLabel = (d) ->
				# stops showStationLabel to be called right after finishing here
				d3.event.stopPropagation()
				this.parentNode.stationLabel = undefined
				d3.select(this).remove()
			
			showStationLabel = (d) ->
				return if this.stationLabel
				stationLabel = d3.select(this).append('g').classed("station-label", true)
					.on('click.closeLabel', closeStationLabel)
				rectLength = d.data.meaning.length + 2
				stationLabel.append('rect')	
					.attr(x:20, y:-r-3)
					.attr(width: 8*rectLength, height: 2.5*r)
				stationLabel.append('text')
					.text((d) -> d.data.meaning or '?')
					.attr(x:23, y:-r/2+4)
				this.stationLabel = stationLabel
				
			delayDblClick = (ms, func) ->
				if that.timer 
					clearTimeout(that.timer)
					that.timer = null
				else 
					that.timer = setTimeout(((d)-> 
						that.timer = null
						func d), ms)
			
			edge.enter()
				.append("path")
				.classed("edge", true)
				# for transitions; nodes start at 0,0. so should edges
				.attr d: (d) -> svgline [ {x:0,y:0}, {x:0,y:0} ]
			node_g = node.enter()
				.append('g')
				.classed("node", true)
				.on('click.showLabel', (d) ->
					that = this
					delayDblClick(550, -> showStationLabel.call(that, d))
				)
				.on('dblclick.selectNode', (d) -> nodeDoubleClick d)
			node_g.append('rect').attr x:-r, y:-r, width:2*r, height:2*r
			node_g.append('text')
			
			

			endnode_g = endnode.enter()
				.append('g')
				.classed("endnode", true)
				.on('click.selectLine', (d) -> endnodeSelectLine d)
			endnode_g.append("circle").attr {r}
			endnode_g.append("text").text (d) -> d.label
		
			# update
			edge.each (d) ->
				d3.select(@).classed "line_"+d.line.data.radical, true
			for rad in radicals
				selector = ".line_" + rad
				d3.selectAll(selector).style("stroke", colors[radicals.indexOf(rad)-1])
			edge.transition().duration(config.transitionTime)
				.attr d: (d) -> svgline01 createTubes d	
			edge.classed("filtered", (d) -> d.style.filtered)
			node.classed("filtered", (d) -> d.style.filtered)
			node.classed("searchresult", (d) -> d.style.isSearchresult)
			node_t = node.transition().duration(config.transitionTime)
			node_t.attr(transform: (d) -> "translate(#{d.x} #{d.y})")
			node_t.style(fill: (d) -> if d.style.hi then "red" else if d.style.lo then "green" else null) # debug @payload
			node_t.select('text').text (d) -> d.label

			endnode.transition().duration(config.transitionTime)
				.attr transform: (d) -> "translate(#{d.x} #{d.y})"
		
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
					
	table_data = [[],[],[],[],[]]
	nodeDoubleClick = (d) ->
		table = d3.select('table#details tbody')
		tablehead = d3.select('thead').selectAll('tr')
		
		i = 1
		nothingtodo = false
		for k in table.selectAll('tr').selectAll('td')
			item = table.selectAll('tr').selectAll('td')[0][i]
			if item == undefined
				break
			if(item.textContent == d.label)
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
		
		# join
		table_tr = table.selectAll('tr')
			.data(table_data)
		
		# enter
		table_td = table_tr.selectAll('td.content')
			.data((d) -> d)
			
		if(!nothingtodo)
			table_tr.enter()
				.append('tr')
			
			table_td.enter()
				.append('td')
				.classed("content", true)
		
		tablecontentcols = table.select('tr').selectAll('td')[0].length
		tableheadcols = tablehead.selectAll('th')[0].length
		
		if tableheadcols < tablecontentcols
			tablehead.append('th')
		
		# update	
		table_td.text((d) -> d)
		# exit
		
	{ View}
