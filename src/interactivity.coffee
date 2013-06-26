define ['utils'], ({ P, compareNumber }) ->

	class View
		constructor: ({ @svg, @graph, @config }) ->
			@r = 12
			@g_edges = @svg.append 'g'
			@g_nodes = @svg.append 'g'
			@g_endnodes = @svg.append 'g'
	
		update: ->
			{ svg, r, config, g_edges, g_nodes, g_endnodes } = this
			{ nodes, lines, edges, endnodes } = @graph

			nodes = (node for node in nodes when node not in endnodes)

			# join
			edge = g_edges.selectAll(".edge")
				.data(edges)
			node = g_nodes.selectAll('.node')
				.data(nodes)
			endnode = g_endnodes.selectAll('.endnode')
				.data(endnodes)
			
			# enter
			edge.enter()
				.append("path")
				.classed("edge", true)
				# for transitions; nodes start at 0,0. so should edges
				.attr d: (d) -> svgline [ {x:0,y:0}, {x:0,y:0} ]
			node_g = node.enter()
				.append('g')
				.classed("node", true)
				.on('mouseover', (d) -> nodeMouseOver d)
				.on('mouseout', (d) -> nodeMouseOut d)
				.on('mousemove', (d) -> nodeMouseMove d)
				.on('click', (d) -> nodeDoubleClick d)
			node_g.append('rect').attr x:-r, y:-r, width:2*r, height:2*r
			node_g.append('text').text (d) -> d.label

			endnode_g = endnode.enter()
				.append('g')
				.classed("endnode", true)
				.on('click.selectLine', (d) -> endnodeSelectLine d)
			endnode_g.append("circle").attr {r}
			endnode_g.append("text").text (d) -> d.label
		
			# update
			edge.each((d) ->
				d3.select(@).classed "line_"+d.line.data.radical, true)
				.transition().duration(config.transitionTime)
				.attr d: (d) -> svgline [ d.source, d.target ]
			node.transition().duration(config.transitionTime)
				.attr transform: (d) -> "translate(#{d.x} #{d.y})"
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

	endnodeSelectLine = (d) ->
		selector = ".line_"+d.data.radical
		d3.selectAll(selector).classed 'highlighted', (d) ->
			d.highlighted = !d3.select(@).classed 'highlighted'
		d3.selectAll(".edge").sort (a, b) ->
				compareNumber a.highlighted or 0, b.highlighted or 0
				
	tooltip = d3.select('div')
		.attr('class', 'tooltip')
		.style('opacity', 0)
	console.log(tooltip)
	
	nodeMouseOver = (d) ->
		tooltip.transition().duration(500)
			.style('opacity', 1)
			.style('left', (d3.event.pageX) + 'px')
			.style('top', (d3.event.pageY + 10) + 'px')
    
	nodeMouseOut = (d) ->
		tooltip.transition().duration(500)
			.style('opacity', 0)
			.style('left', (d3.event.pageX) + 'px')
			.style('top', (d3.event.pageY + 10) + 'px')
  
	nodeMouseMove = (d) ->
		d.data.onyomi ?= ' - ' 
		d.data.kunyomi ?= ' - '
		d.data.grade ?= ' - '
		tooltip.html(d.label + '<br/>' + 
			d.data.meaning + '<br/>' + 
			'strokes: ' + d.data.stroke_n + '<br/>' + 
			'ON: ' + d.data.onyomi + '<br/>' + 
			'KUN: '+ d.data.kunyomi + '<br/>' + 
			'school year: ' + d.data.grade)
			.style('opacity', 1)
			.style("left", (d3.event.pageX) + "px")
			.style("top", (d3.event.pageY + 10) + "px")
	
	nodeDoubleClick = (d) ->
		#selector = d.data.kanji
		#console.info(selector)
		#d3.selectAll(selector).classed 'highlighted', (d) ->
		#	d.highlighted = !d3.select(@).classed 'highlighted'

		descriptions = [
			[''],
			['english'],
			['radicals'],
			['onyomi'],
			['kunyomi'],
		]
	
		matrix = [
			[d.label],
			[d.data.meaning],
			[d.data.radicals],
			[d.data.onyumi],
			[d.data.kunyomi],
		]
		
		#do not display same kanji twice
		i = 1
		nothingtodo = false
		for k in d3.selectAll('tbody tr').selectAll('td')
			item = d3.selectAll('tbody tr').selectAll('td')[0][i]
			if item == undefined
				break
			if(item.textContent == d.label)
				nothingtodo = true;
				break
			i++
			
		#remve second column if it is still empty, ie first kanji selected
		emptycolremoved = false
		if(d3.selectAll('tbody tr').selectAll('td')[0][1].textContent == " click Kanjis to see details ")
			d3.selectAll('tbody tr').selectAll('td').remove()
			d3.selectAll('tbody tr').append('td')
					.data(descriptions)
				.text((d) -> d)
			d3.selectAll('tbody tr').append('td')
					.data(matrix)
				.text((d) -> d)
			emptycolremoved = true
		#add extra column if a new kanji will be displayed
		if(!emptycolremoved and !nothingtodo)
			d3.selectAll('tbody tr').append('td')
					.data(matrix)
				.text((d) -> d)
		
	{ View }
