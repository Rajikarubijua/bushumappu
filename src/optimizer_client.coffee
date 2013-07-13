define [], ->
	class Optimizer
		constructor: (cb) ->
			@worker = new Worker "js/optimize.js?"+Date.now()
			@worker.onmessage = (ev) =>
				return cb?() if ev.data == 'ready'
				console.log 'receive', ev.data.type if ev.data.type != 'log'
				@[ev.data.type] ev.data
			@onNodes = null
			
		postMessage: (msg) ->
			console.log 'postMessage', msg.type
			@worker.postMessage msg
			
		graph: 	(graph) ->
			@_graph = graph
			@postMessage type: 'graph', graph: @_graph.toPlainLines()
			
		optimize: -> @postMessage type: 'optimize'
			
		snapNodes: -> @postMessage type: 'snapNodes'
			
		applyRules: -> @postMessage type: 'applyRules'
						
		log:	({ log }) -> console.log log
		
		node:	({ node }) ->
			other = @_graph.nodesById[node.id]
			other.move node.x, node.y
			other.style.debug_fill = node.debug_fill
			if not @raf
				@raf = true
				requestAnimationFrame =>
					@raf = false
					
		nodes:	({ nodes }) ->
			@node { node } for node in nodes
			@onNodes?()
			
	{ Optimizer }
