define ['routing', 'test_graph'], (routing, testGraph) ->

	tests =
		benchOptimize: ->
			{ graph10, graph100 } = testGraph

			layout = new routing.MetroMapLayout graph: graph10
			times = for [1..20]
				time = +Date.now()
				layout.optimize()
				time = +Date.now() - time
			mean = d3.mean times
			console.info "optimize", mean, ""+times
			
			layout = new routing.MetroMapLayout graph: graph100
			times = for [1..20]
				time = +Date.now()
				layout.optimize()
				time = +Date.now() - time
			mean = d3.mean times
			console.info "optimize", mean, ""+times
			
			layout = new routing.MetroMapLayout graph: graph100
			times = for [1..20]
				time = +Date.now()
				layout.optimize()
				time = +Date.now() - time
			mean = d3.mean times
			console.info "optimize", mean, ""+times
	
	{ tests }
