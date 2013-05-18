window.my = {} # the global object where we can put stuff into it

load = (cb) ->
	i = 0
	tryEnd = () -> end() if --i == 0
	# load ALL the data concurrently
	++i; d3.text "data/krad", (content) ->
		copyAttrs my, parseKrad content.split '\n'
		tryEnd()
	++i; d3.text "data/radk", (content) ->
		copyAttrs my, parseRadk content.split '\n'
		tryEnd()
	end = () ->
		# everything of 'my' which is named '*_set' becomes a sorted array
		for k, set of my
			if k[-4..] == '_set'
				my[k] = (Object.keys set).sort()
		# XXX radk doesn't contain radicals "邑龠" which are in krad
		
		my.kanji_map = {}
		for kanji, radicals of my.kanji_radicals_map
			strokes_n = 0
			for radical in radicals
				strokes_n += my.radical_map[radical]?.strokes_n
			my.kanji_map[kanji] = { kanji, radicals, strokes_n }
		cb()

main = () ->
	body = d3.select 'body'
	body.append('pre').text somePrettyPrint my
	svg = my.svg = body.append('svg')
		.attr('width', 600)
		.attr('height', 400)
		.style('border', '1px solid black')
	drawStuff svg

parseKrad = (lines) ->
	kanji_radicals_map = {}
	radicals_set = {}
	atomic_radicals_set = {}

	for line, i in lines
		# parse line
		continue if line[0] == '#' || !line
		kanji = line[0]
		if line[1..3] != ' : '
			throw "expected \" : \" at line #{i}, got \"#{line[1..3]}\""
		radicals = line[4..].trim().split ' '
		# fill datastructures
		kanji_radicals_map[kanji] = radicals
		for radical in radicals
			radicals_set[radical] = true
		
	for radical of radicals_set
		radicals = kanji_radicals_map[radical]
		if (!radicals) or (radicals.length == 1 and radical in radicals)
			atomic_radicals_set[radical] = true 
			
	{ kanji_radicals_map, radicals_set, atomic_radicals_set }

parseRadk = (lines) ->
	radical_map = {}
	radical = null
	strokes_n = null
	kanjis = ""
	$line = /\$ (.) (\d+) ?.*/
	
	for line, i in lines
		# parse line
		continue if line[0] == '#' || !line
		m = line.match $line
		if m == null
			kanjis += line.trim()
		else
			radical_map[radical] = { radical, strokes_n, kanjis } if radical
			[ _, radical, strokes_n ] = m
			strokes_n = +strokes_n
			
	{ radical_map }
			
expect = (regex, line, i) ->
	m = line.match regex
	throw "expected #{regex} at #{i}" if m == null
	return m

somePrettyPrint = (o) ->
	# everything in 'o' gets pretty printed for development joy
	w = firstColumnWidth = 30
	lines = for k in (Object.keys o).sort()
		v = o[k]
		if Array.isArray v
			k = W w, "["+k+"]"
			v = v.length
		else if typeof v is 'object'
			k = W w, "{"+k+"}"
			v = (Object.keys v).length
		else
			k = W w, " "+k+" "
			v = JSON.stringify v
		k+" "+v
	lines.join "\n"


drawStuff = (svg) ->
	w = svg.attr 'width'
	h = svg.attr 'height'

	atomics_n = my.atomic_radicals_set.length
	nodes = for kanji, i in my.atomic_radicals_set
			c = atomics_n * 1/8
			af = 55/144 * 2*Math.PI
			r = c * Math.sqrt i
			a = i * af
			x = r * Math.cos a
			y = r * Math.sin a
			x += w/2
			y += h/2
			{ kanji, x, y }
	links  = []

	force = d3.layout.force()
		.nodes(nodes)
		.links(links)
		.size([w, h])
		.start()

	kanji = svg.selectAll('.kanji')
		.data(nodes)
		.enter()
		.append('g')
	kanji
		.append("circle").attr(r: 12).style fill: 'none', stroke: 'black'
	kanji
		.append("text").text((d) -> d.kanji)
		.style "alignment-baseline": 'central', "text-anchor": "middle"
		
	force.on 'tick', (e) ->
		kanji.attr('transform', (d) -> "translate(#{d.x} #{d.y})")
	
copyAttrs = (a, b) -> a[k] = v for k, v of b
P = (args...) -> console.log args...; return args[-1..][0]
W = (width, str) ->
	str = ""+str
	width = Math.max str.length, width
	str + (" " for [1..width-str.length]).join ''

do ->
	i = 2
	runMain = -> main() if --i == 0
	window.onload = runMain
	load runMain
