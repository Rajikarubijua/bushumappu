define [], ->
	class Optimizer
		constructor: (cb) ->
			@worker = new Worker "js/optimize.js?"+Date.now()
			@worker.onmessage = (ev) =>
				return cb() if ev.data == 'ready'
				console.log 'receive', ev.data.type if ev.data.type != 'log'
				@[ev.data.type] ev.data
			@callbacks = id: 0
		postMessage: (msg) ->
			console.log 'postMessage', msg.type
			@worker.postMessage msg
		graph: 	(graph) ->
			@_graph = graph
			@postMessage type: 'graph', graph: @_graph.toPlainLines()
		optimizeNodes: ->
			@postMessage type: 'optimizeLoop'
		snapNodes: (cb) ->
			id = @callbacks.id++
			@callbacks[id] = cb
			@postMessage { type: 'snapNodes', cb: id }
		applyRules: (cb) ->
			id = @callbacks.id++
			@callbacks[id] = cb
			@postMessage { type: 'applyRules', cb: id }
		log:	({ log }) -> console.log log
		node:	({ node }) ->
			other = @_graph.nodesById[node.id]
			other.move node.x, node.y
			console.log other.style.debug_fill = node.debug_fill
			if not @raf
				@raf = true
				requestAnimationFrame =>
					@raf = false
					@afterNode? other
		nodes:	({ nodes, cb }) ->
			console.log 'nodes', nodes.length
			@node { node } for node in nodes
			@callbacks[cb]?()
			delete @callbacks[cb]
	{ Optimizer }
