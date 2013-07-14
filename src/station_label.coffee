define ['utils'], ({P, cssTranslateXY }) ->
	class StationLabel
		constructor: ({ @node, @g_stationLabels, @style }) ->
			@node
			@g_stationLabels
			@style ?= {}
		
		closeStationLabel : () ->
			me = this
			return if !me.node.style.stationLabel
			me.node.style.stationLabel.remove()
			me.node.style.stationLabel = undefined
		
		showStationLabel : (node) ->
			me = this
			return if node.style.stationLabel
			stationLabel = @g_stationLabels.append('g').classed("station-label", true)
				.attr(transform: cssTranslateXY node)
				.on('click.closeLabel', -> me.closeStationLabel() )
			@updateListener(stationLabel, @node)
		
		updateListener: (stationLabel) ->
			me = this
			stationLabelAngle = @calculateLabelAngle(@node)
			label_rect = stationLabel.append('rect')
					.attr(x:24, y:-config.nodeSize-3)
					.attr(transform: "rotate(#{stationLabelAngle})")
			label_text = stationLabel.append('text')
					.text((d) -> me.node.data.meaning or '?')
					.attr(x:28, y:-config.nodeSize/2+4)
					.attr(transform: "rotate(#{stationLabelAngle})")
			rectLength = label_text.node().getBBox().width + 8
			label_rect.attr(width: rectLength, height: 2.5*config.nodeSize) # inflating the rectangle
			
			me.node.style.stationLabel = stationLabel
			
			
		calculateLabelAngle: (node) ->
			edgeAngles = []
			for edge in node.edges
				a = edge.firstAngleFromNode node
				r_a = Math.round(a / (0.25*Math.PI))
				edgeAngles.push(r_a)
			stationLabelAngle = 0
			if 0 in edgeAngles
				stationLabelAngle = -45
			stationLabelAngle

	{ StationLabel }
