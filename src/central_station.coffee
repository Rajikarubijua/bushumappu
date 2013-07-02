define ['utils', 'graph'], (utils, { Graph, Node }) ->
	{ P } = utils

	class CentralStationEmbedder
		constructor: (@config) ->
		graph: (central_kanji, all_radicals, all_kanjis) ->
			lines = {}
			for radical in central_kanji.radicals
				lines[radical.radical] = { radical, hi: 0, lo: [], other: null }
			
			related_kanjis =
				utils.arrayUnique d3.merge (
					radical.jouyou for radical in central_kanji.radicals)
			i = related_kanjis.indexOf central_kanji
			related_kanjis[i..i] = []

			memo = new utils.Memo
			
			kanjiIsRelated = memo.onceObj (kanji) ->
				kanji in related_kanjis
				
			kanjiRelevantRadicals = memo.onceObj (kanji) ->
				radical for radical in kanji.radicals when \
					radical in central_kanji.radicals
					
			kanjiDegree = memo.onceObj (kanji) ->
				kanjiRelevantRadicals(kanji).length
				
			kanjiNode = memo.onceObj (kanji) ->
				new Node data: kanji
			
			
			hi_nodes = []
			for kanji in related_kanjis
				node = kanjiNode kanji
				if kanjiDegree(kanji) == 1
					node.style.lo = true
					radical = kanjiRelevantRadicals(kanji)[0]
					lines[radical.radical].lo.push node
				else
					node.style.hi = true
					hi_nodes.push node
					
			for node in hi_nodes
				min = null
				for radical in kanjiRelevantRadicals node.data
					line = lines[radical.radical]
					if min is null or line.hi < min.hi
						min = line
				min.hi++
				
			for _, line of lines
				hi = line.hi
				line.hi = hi_nodes[...hi]
				line.other = hi_nodes[hi..]
				hi_nodes[...hi] = []
		
			node_r = 64
			kanji_offset = 5
			central_node = kanjiNode central_kanji
			n = central_kanji.radicals.length
			lines = for line, line_i in d3.values lines
				angle = line_i/n*Math.PI*2
				r = node_r #(line.hi.length+kanji_offset) * node_r
				x = r * Math.cos angle
				y = r * Math.sin angle
				radical_node = new Node { x, y, data: line.radical }
				for node, node_i in [ line.hi..., line.lo... ]
					r = (node_i+kanji_offset) * node_r
					node.x = r*Math.cos angle
					node.y = r*Math.sin angle
				nodes = [central_node, radical_node, line.hi..., line.other..., line.lo...]
				nodes.obj = data: line.radical
				nodes
			
			new Graph lines
		
		kanjiHasRadical: (kanji, radicals) ->
			n = 0
			for radical in kanji.radicals
				if radical in radicals
					n++
			n
		
		filterRelatedKanjis: (central_kanji, kanjis) ->
			related_kanjis = []
			for kanji in kanjis
				n_radicals = 0
				for radical in central_kanji.radicals
					if radical in kanji.radicals
						n_radicals++
				if n_radicals > 1
					related_kanjis.push kanji
			related_kanjis
		
	{ CentralStationEmbedder }
