define ['utils', 'criteria'], (utils, criteria) ->
	{ P } = utils
	{ otherNode, otherEdge } = criteria

	class Node
		next_id = 0
		constructor: ({ @x, @y, @lines, @edges, @data, @style, @id, @cool, @fixed }={}) ->
			@x     ?= 0
			@y     ?= 0
			@lines ?= []
			@edges ?= []
			@data  ?= {}
			@style ?= {}
			@crit  ?= null
			@id    ?= next_id++
			@cool  ?= 1
			@fixed ?= false
		
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
				otherNode this, edge for edge in @edges
			)
			
		critValue: ->
			@_critValue ?= @cool * d3.sum @critValues()
			
		critValues: -> @_critValues = [
			10 * criteria.lineStraightness this
			1 * criteria.edgeLength this
			#1 * criteria.nearNodes this
		]
		
		invalidateValues: ->
			@_critValue = @_critValues = undefined
			
		move: (@x, @y) ->
			@invalidateValues()
			node.invalidateValues() for node in @deps()
			
		moveBy: (x, y) -> @move @x+x, @y+y
	
	class Cluster
		constructor: (@nodes) ->
			@copies = ([n.x,n.y] for n in @nodes)
		critValue: ->
			@_critValue ?= d3.sum (n.critValue() for n in @nodes)
		moveBy: (x, y) ->
			@_critValue = undefined
			n.moveBy x, y for n in @nodes
		resetPosition: ->
			@_critValue = undefined
			for n, i in @nodes
				[x,y] = @copies[i]
				n.move x,y
	
	class Edge
		constructor: ({ @source, @target, @line }={}) ->
			throw @radical if @radical
			@source ?= null
			@target ?= null
			@sourcecoord ?= []
			@targetcoord ?= []
			@tube ?= null
			@line   ?= null
			@style ?= {}
			@calc ?= false
		
		getVector: ->
			[ @target.x - @source.x, @target.y - @source.y ]

		getAngle: (edge) ->
			[ x1, y1 ] = @getVector()
			[ x2, y2 ] = edge.getVector()
			scalar = x1 * x2 + y1 * y2 
			l1 = @length()
			l2 = edge.length()
			angle = Math.acos scalar / (l1 * l2)
			
		getEdgeAngle: ->
			[ x1, y1 ] = [@source.x, @source.y]
			[ x2, y2 ] = [@target.x, @target.y]
			x = x2 - x1
			y = y2 - y1
			angle = Math.atan2(y,x)
			
		lengthSqr: ->
			[ x, y ] = @getVector()
			(Math.pow x, 2) + (Math.pow y, 2)
			
		length: -> Math.sqrt @lengthSqr()


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
				if node instanceof Node then node else new Node node
			@lines = for orig_line_nodes in lines
				line = new Line orig_line_nodes.obj
				line.nodes = for node in orig_line_nodes
					node = @nodes[nodes.indexOf node]
					node.lines.push line if line not in node.lines
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
				nodes[node.id] = x: node.x, y: node.y, data: node.data, id: node.id, fixed: node.fixed
			lines = for line in @lines
				for node in line.nodes
					nodes[node.id]

	my.graph = { Node, Edge, Line, Graph, Cluster }
