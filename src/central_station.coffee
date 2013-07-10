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
				angle = someAngle bin_i
				for node, node_i in nodes
					r = (node_i+node_offset) * node_r
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
		
	log2 = (x) -> Math.log(x) / Math.log(2)
	
	someAngle = (bin_i) ->
		# this is some complicated shit man
		if bin_i <= 1
			angle = bin_i * Math.PI
		else
			exp = Math.floor log2 bin_i
			a   = Math.pow 2, exp
			b   = Math.pow 2, exp-1
			c   = 1 + bin_i % a
			angle = (1/a + c/b)*Math.PI
		### based on following notes
		0		1				  1/1*0		0
		1		1				  1/1*1		1
		1.5		0.5			1/2 + 1/1*1		2
		0.5		0.5			1/2	      2		3
		0.75	0.25		1/4 + 1/2*1		4
		1.25	0.25		          2		5			1/a + 1/(a-1) * n
		1.75	0.25				  3		6
		0.25	0.25                  4		7
		0.375	0.125		1/8 + 1/4*1		8
		0.625	0.125                 2		9
		0.875	0.125                 3		10
		1.125	0.125
		0.625	0.125
		0.625	0.125
		0.625	0.125
		0.625	0.125


		a   = pow 2, fl log 2,i
		a-1 = pow 2, -1+ fl log 2,i
		n   = 1 + i % a
		###
		
	{ CentralStationEmbedder }
