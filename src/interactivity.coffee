define ['utils'], ({ P, compareNumber }) ->

	setupD3 = (svg, { stations, endstations, links }, config) ->
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
			.on('mouseover', (d) -> stationMouseOver d)
			.on('mouseout', (d) -> stationMouseOut d)
			.on('mousemove', (d) -> stationMouseMove d, station)
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
			
	svgline = d3.svg.line()
		.x(({x}) -> x)
		.y(({y}) -> y)

	endstationSelectLine = (d) ->
		selector = ".radical_"+d.radical.radical
		d3.selectAll(selector).classed 'highlighted', (d) ->
			d.highlighted = !d3.select(@).classed 'highlighted'
		d3.selectAll(".link").sort (a, b) ->
				compareNumber a.highlighted or 0, b.highlighted or 0
				
	tooltip = d3.select('body').append('div')
		.attr('class', 'tooltip')
		.style('opacity', 0)

	stationMouseOver = (d) ->
		tooltip.transition().duration(500)
			.style('opacity', 1)
			.style('left', (d3.event.pageX) + 'px')
			.style('top', (d3.event.pageY - 28) + 'px')
    
	stationMouseOut = (d) ->
		tooltip.transition().duration(500)
			.style('opacity', 0)
			.style('left', (d3.event.pageX) + 'px')
			.style('top', (d3.event.pageY - 28) + 'px')
  
	stationMouseMove = (d, station) ->
		tooltip.html(d.label + '<br/>' + d.kanji.grade + '<br/>' + d.kanji.meaning)
			.style('opacity', 1)
			.style("left", (d3.event.pageX) + "px")
			.style("top", (d3.event.pageY - 28) + "px")

	{ setupD3 }
