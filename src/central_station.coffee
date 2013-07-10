define ['utils', 'graph'], (utils, { Graph, Node }) ->
	{ P } = utils

	class CentralStationEmbedder
		###
		Lines get arranged star-like around the central node.
		Each line has a star point.
		
		Lines have three kinds of nodes: hi, lo and other.
		Lo nodes are nodes with degree one and are on the star point.
		Hi nodes are nodes with degree bigger one and are on the star point.
		Other nodes are nodes with degree bigger one and are on another star
		point.
		
		On which star point get nodes with degree bigger one?
		This is based on a balancing process. Each star point gets so many
		hi nodes such that it is balanced with each other star point as good as
		it gets.
		###
		constructor: (@config) ->
		graph: (central_kanji, all_radicals, all_kanjis) ->
			related_kanjis =
				utils.arrayUnique d3.merge (
					radical.jouyou for radical in central_kanji.radicals)
			i = related_kanjis.indexOf central_kanji
			related_kanjis[i..i] = []

			memo = new utils.Memo
			
			kanjiIsRelated = memo.onceObj (kanji) ->
				kanji in related_kanjis
				
			kanjiRelevantRadicals = memo.onceObj (kanji) ->
				kanji.relevantRadicals = (radical for radical in kanji.radicals when \
					radical in central_kanji.radicals)
					
			kanjiDegree = memo.onceObj (kanji) ->
				kanjiRelevantRadicals(kanji).length
				
			kanjiNode = memo.onceObj (kanji) ->
				new Node data: kanji
					
			bins = {}
			for kanji in related_kanjis
				node = kanjiNode kanji
				bin = kanjiRelevantRadicals node.data
				bin = (x.radical for x in bin)
				bin = bin.join ''
				bin = (bins[bin] ?= [])
				bin.push node
			
			node_r = my.config.edgeLength
			node_offset = 3
			bins_n = utils.length bins
			for bin, bin_i in utils.sort bins
				nodes = bins[bin]
				nodes_n = utils.length nodes
				for node, node_i in nodes
					r = (node_i+node_offset) * node_r
					meh = 1/Math.pow(2, Math.floor(bin_i / 4))
					angle = ((bin_i % 4) + meh) * 0.5*Math.PI
					#angle = bin_i / bins_n * 2*Math.PI
					x = r * Math.cos angle
					y = r * Math.sin angle
					node.x = x
					node.y = y
					
			central_node = kanjiNode central_kanji
			central_node.fixed = true
			lines = for radical in central_kanji.radicals
				for bin in utils.sort bins
					if radical.radical in bin
						line = []#[ central_node ]
						line.obj = data: radical
						line.push central_node
						line.push bins[bin]...
						(line.bins ?= []).push bin
						line
					else continue
			lines = d3.merge lines
			
			new Graph lines
		
	{ CentralStationEmbedder }
