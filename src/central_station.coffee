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
			lines = {}
			for radical in central_kanji.radicals
				lines[radical.radical] = { radical, hi: [], lo: [], other: [] }
			
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
			
			# deciding if node is lo or some hi node
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
			
			lines = d3.values lines		

			# hi nodes, first come, first served
			for node in hi_nodes
				for line in lines
					if line.radical in kanjiRelevantRadicals node.data
						line.hi.push node
						break

			# balance hi nodes
			for a in lines
				for b in lines
					continue if a == b
					node_i = -1
					while ++node_i < a.hi.length
						break if b.hi.length >= a.hi.length
						node = a.hi[node_i]
						continue if b.radical not in node.data.radicals
						b.hi.push node
						a.hi[node_i..node_i] = []
						--node_i

			# other nodes
			for a in lines
				for b in lines
					continue if a == b
					for node in b.hi
						if a.radical in node.data.radicals
							a.other.push node
		
			# place nodes
			node_r = my.config.gridSpacing
			kanji_offset = 15
			central_node = kanjiNode central_kanji
			central_node.central_node = true
			central_node.fixed = true
			n = central_kanji.radicals.length
			lines = for line, line_i in lines
				angle = someAngle line_i
				r = line.hi.length + line.lo.length + kanji_offset
				r *= radius node_r, angle
				x = r * Math.cos angle
				y = r * Math.sin angle
				radical_node = new Node { x, y, data: line.radical }
				radical_node.fixed = true
				for node, node_i in [ line.hi..., line.lo... ]
					r = node_i + kanji_offset
					r *= radius node_r, angle
					node.x = r*Math.cos angle
					node.y = r*Math.sin angle
				#nodes = [central_node, line.hi..., line.other..., line.lo..., radical_node]
				nodes = [central_node, line.hi..., line.other..., line.lo...]
				nodes.obj = data: line.radical
				nodes
			
			new Graph lines
		
	log2 = (x) -> Math.log(x) / Math.log(2)
   
	radius = (base, angle) ->
		if (Math.round angle / 0.25/Math.PI) % 2 == 0
			base
		else
			Math.sqrt 2 * Math.pow base, 2
	   
	someAngle = (i) ->
		# this is some complicated shit man
		if i <= 1
			angle = i * Math.PI
		else
			exp = Math.floor log2 i
			a   = Math.pow 2, exp
			b   = Math.pow 2, exp-1
			c   = 1 + i % a
			angle = (1/a + c/b)*Math.PI

		
	{ CentralStationEmbedder }
