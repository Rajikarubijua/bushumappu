define ['utils', 'criteria', 'tubeEdges'], (utils, criteria, tube) ->
	{ P } = utils

	class Node
		next_id = 0
		constructor: ({ @x, @y, @lines, @edges, @data, @style, @id, @fixed }={}) ->
			@x     ?= 0
			@y     ?= 0
			@lines ?= []
			@edges ?= []
			@data  ?= {}
			@style ?= {}
			@id    ?= next_id++
		
		coord: -> @x+"x"+@y
		
		deps: (n=0) ->
			if not n and @_deps?
				return @_deps
			deps = @nextNodes()[..]
			if n == 1
				deps
			else
				for node in @nextNodes()
					for o in node.deps n+1
						deps.push o if o not in deps
				@_deps = deps
			
		nextNodes: ->
			@_nextNodes ?= utils.arrayUnique(
				@otherNode edge for edge in @edges
			)
			
		ruleViolations: (graph) ->
			@_ruleViolations ?= do =>
				throw "graph not a Graph" if graph not instanceof Graph
				d3.sum [
					1000*criteria.wrongEdgesUnderneath(this, graph.edges).length
					criteria.edgeCrossings @edges, graph.edges
				]
			
		critQuality: (graph) ->
			@_critQuality ?= do =>
				throw "graph not a Graph" if graph not instanceof Graph
				criteria.lineStraightness this
		
		_invalidateCache: ->
			@_critQuality = @_ruleViolations = undefined
			
		move: (@x, @y) ->
			throw "move to undefined" if not (@x? and @y?)
			@_invalidateCache()
			node._invalidateCache() for node in @deps()
			edge._invalidateCache() for edge in @edges
			
		moveBy: (x, y) -> @move @x+x, @y+y
		
		otherNode: (edge) ->
			if edge.source == this then edge.target else edge.source
			
		tubes: ->
			tubes = []
			for edge in @edges
				tubes.push edge.tube if edge.tube not in tubes
			tubes
	
	class Edge
		constructor: ({ @source, @target, @tube, @line, @style }={}) ->
			@source ?= null
			@target ?= null
			@tube   ?= null
			@line   ?= null
			@style  ?= {}
		
		getVector: ->
			[ @target.x - @source.x, @target.y - @source.y ]

		getAngle: (edge) ->
			[ x1, y1 ] = @getVector()
			[ x2, y2 ] = edge.getVector()
			scalar = x1 * x2 + y1 * y2 
			l1 = @length()
			l2 = edge.length()
			l = l1 * l2
			if Math.abs(scalar - l) < 0.0001
				l = scalar
			angle = Math.acos scalar / l
			
		getEdgeAngle: ->
			@_getEdgeAngle ?= do =>
				[ x1, y1 ] = [@source.x, @source.y]
				[ x2, y2 ] = [@target.x, @target.y]
				x = x2 - x1
				y = y2 - y1
				angle = Math.atan2(y,x)
			
		lengthSqr: ->
			@_lengthSqr ?= do =>
				[ x, y ] = @getVector()
				(Math.pow x, 2) + (Math.pow y, 2)
			
		length: ->
			@_length ?= Math.sqrt @lengthSqr()
		
		otherEdge: (edges) ->
			for other in edges
				continue if other == this
				if other.line.id == @line.id
					return other
			null
			
		isCrossing: ({ source, target }) ->
			{ x: x1, y: y1 } = @source
			{ x: x2, y: y2 } = @target
			{ x: x3, y: y3 } = source
			{ x: x4, y: y4 } = target
			a = (x4 - x3)*(y1 - y3) - (y4 - y3)*(x1 - x3)
			b = (x2 - x1)*(y1 - y3) - (y2 - y1)*(x1 - x3)
			c = (y4 - y3)*(x2 - x1) - (x4 - x3)*(y2 - y1)
			a /= c
			b /= c
			0 <= a <= 1 and 0 <= b <= 1
			
		setCoords: (coords) ->
			@_coords = coords
			
		coords: ->
			tube.createTubes this if not @_coords?
			@_coords
			
		_invalidateCache: ->
			@_coords = @_lengthSqr = @_length = @_getEdgeAngle = undefined

	class Line
		next_id = 0
		constructor: ({ @nodes, @edges, @data, @id }={}) ->
			@nodes ?= []
			@edges ?= []
			@data  ?= {}
			@id    ?= next_id++

	class Graph
		constructor: (lines) ->
			@nodes = []
			@edges = []
			@lines = []
			@nodesById = {}
			nodes = []
			for line_nodes in lines
				for node in line_nodes
					nodes.push node if node not in nodes
			@nodes = for node in nodes
				k = 0
				if node instanceof Node then node else new Node node
			@lines = for orig_line_nodes in lines
				line = new Line orig_line_nodes.obj
				line.nodes = for node in orig_line_nodes
					node = @nodes[nodes.indexOf node]
					node.lines.push line
					node
				line
			for line in @lines
				source = line.nodes[0]
				for target in line.nodes[1..]
					edge = new Edge { source, target, line }
					source.edges.push edge
					target.edges.push edge
					@edges.push edge
					line.edges.push edge
					source = target
			for node in @nodes
				@nodesById[node.id] = node
				if node.edges.length > 10
					P "node with many edges", node
					
		kanjis: ->
			node.data for node in @nodes when node.data.kanji
			
		toPlainLines: ->
			nodes = {}
			for node in @nodes
				nodes[node.id] =
					x: node.x,
					y: node.y,
					data: node.data,
					id: node.id,
					fixed: node.fixed
			lines = for line in @lines
				for node in line.nodes
					nodes[node.id]
					
		ruleViolations: ->
			d3.sum (node.ruleViolations this for node in @nodes)
			
		critQuality: ->
			d3.sum [
				d3.sum (node.critQuality this for node in @nodes)
				criteria.lengthOfEdges @edges
			]

	class Cluster
		constructor: (@nodes) ->
			@copies = ([n.x,n.y] for n in @nodes)
			
		ruleViolations: (graph) ->
			@_ruleViolations ?= do ->
				throw "graph not a Graph" if graph not instanceof Graph
				d3.sum (n.ruleViolations graph for n in @nodes)
			
		critQuality: (graph) ->
			@_critQuality ?= do ->
				throw "graph not a Graph" if graph not instanceof Graph
				d3.sum (n.critQuality graph for n in @nodes)
			
		moveBy: (x, y) ->
			@_ruleViolations = @_critQuality = undefined
			n.moveBy x, y for n in @nodes
			
		resetPosition: ->
			@_ruleViolations = @_critQuality = undefined
			for n, i in @nodes
				[x,y] = @copies[i]
				n.move x,y

	my.graph = { Node, Edge, Line, Graph, Cluster }
