define ['utils'], ({  }) ->

	setupD3 = (svg, stations, endstations, links, config) ->
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
			
	svgline = d3.svg.line()
		.x(({x}) -> x)
		.y(({y}) -> y)

	endstationSelectLine = (d) ->
		selector = ".radical_"+d.radical.radical
		d3.selectAll(selector).classed 'highlighted', (d) ->
			d.highlighted = !d3.select(@).classed 'highlighted'
		d3.selectAll(".link").sort (a, b) ->
				compareNumber a.highlighted or 0, b.highlighted or 0

	{ setupD3 }
