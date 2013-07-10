define [], ->
	class Optimizer
		constructor: ({ @graph }) ->
			@worker = new Worker "js/optimize.js?"+Date.now()
			@worker.onmessage = (ev) => @[ev.data.type] ev.data
		postMessage: (msg) -> @worker.postMessage msg
		start: 	->
			@postMessage type: 'graph', graph: @graph.toPlainLines()
		log:	({ log }) -> console.log log
		node:	({ node }) ->
			other = @graph.nodesById[node.id]
			other.move node.x, node.y
			other.style.debug_fill = node.debug_fill
			if not @raf
				@raf = true
				requestAnimationFrame =>
					@raf = false
					@afterNode? other
	{ Optimizer }
