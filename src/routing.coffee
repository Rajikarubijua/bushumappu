define ['utils'], ({ P }) ->
	###

		Here we stick to the terminology used in Jonathan M. Scotts thesis.
		http://www.jstott.me.uk/thesis/thesis-final.pdf (main algorithm on page 90)
		This involved graph, node, edge, metro line, ...

	###

	metroMap = ({ stations, endstations, links }, config) ->
		nodes = [ stations..., endstations... ]
		edges = links
		
		{ gridSpacing } = config
		
		snapNodesToGrid gridSpacing, nodes
		
		{ stations, endstations, links }
	
	snapNodesToGrid = (spacing, nodes) ->
		for node in nodes
			node.x = spacing * Math.floor node.x/spacing
			node.y = spacing * Math.floor node.y/spacing
			
	{ metroMap }
