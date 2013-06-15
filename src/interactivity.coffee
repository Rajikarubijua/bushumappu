define ['utils'], ({ P, compareNumber }) ->

	setupD3 = (svg, { nodes, lines, edges, endnodes }, config) ->
		r = 12

		nodes = (node for node in nodes when node not in endnodes)

		edge = svg.selectAll(".edge")
			.data(edges)
			.enter()
			.append("path")
			.classed("edge", true)
			.each((d) ->
				d3.select(@).classed "line_"+d.line.data.radical, true)
			
		endnode = svg.selectAll('.endnode')
			.data(endnodes)
			.enter()
			.append('g')
			.classed("endnode", true)
			.on('click.selectLine', (d) -> endnodeSelectLine d)
		endnode.append("circle").attr {r}
		endnode.append("text").text (d) -> d.label
		
		node = svg.selectAll('.node')
			.data(nodes)
			.enter()
			.append('g')
			.classed("node", true)
			.on('mouseover', (d) -> nodeMouseOver d)
			.on('mouseout', (d) -> nodeMouseOut d)
			.on('mousemove', (d) -> nodeMouseMove d, node)
		node.append('rect').attr x:-r, y:-r, width:2*r, height:2*r
		node.append('text').text (d) -> d.label

		
		updatePositions = ->
			edge.attr d: (d) -> svgline [ d.source, d.target ]
			endnode.attr transform: (d) -> "translate(#{d.x} #{d.y})"
			node.attr transform: (d) -> "translate(#{d.x} #{d.y})"
		updatePositions()
		
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
		selector = ".radical_"+d.radical.radical
		d3.selectAll(selector).classed 'highlighted', (d) ->
			d.highlighted = !d3.select(@).classed 'highlighted'
		d3.selectAll(".edge").sort (a, b) ->
				compareNumber a.highlighted or 0, b.highlighted or 0
				
	tooltip = d3.select('body').append('div')
		.attr('class', 'tooltip')
		.style('opacity', 0)

	nodeMouseOver = (d) ->
		tooltip.transition().duration(500)
			.style('opacity', 1)
			.style('left', (d3.event.pageX) + 'px')
			.style('top', (d3.event.pageY - 28) + 'px')
    
	nodeMouseOut = (d) ->
		tooltip.transition().duration(500)
			.style('opacity', 0)
			.style('left', (d3.event.pageX) + 'px')
			.style('top', (d3.event.pageY - 28) + 'px')
  
	nodeMouseMove = (d, node) ->
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
			.style("top", (d3.event.pageY - 28) + "px")

	{ setupD3 }
