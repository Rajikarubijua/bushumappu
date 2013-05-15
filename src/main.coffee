load = (cb) ->
	window.my = {}
	d3.text "data/krad", (content) ->
		copyAttrs my, parseKrad content.split '\n'
		for k, set of my
			if k[-4..] == '_set'
				my[k] = (Object.keys set).sort()
		cb()

main = () ->
	drawStuff()

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
		radicals = line[4..].split ' '
		# fill datastructures
		kanji_radicals_map[kanji] = radicals
		for radical in radicals
			radicals_set[radical] = true
		
	for radical of radicals_set
		radicals = kanji_radicals_map[radical]
		if (!radicals) or (radicals.length == 1 and radical in radicals)
			atomic_radicals_set[radical] = true 
			
	{ kanji_radicals_map, radicals_set, atomic_radicals_set }

drawStuff = () ->
	body = d3.select 'body'

	log = do ->
		w = 30
		for k, v of my
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
	log = log.join "\n"

	body.append('pre').text(log)

	[ w, h ] = [ 600, 400 ]

	svg = body.append('svg')
		.attr('width', w)
		.attr('height', h)
		.style('border', '1px solid black')

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
		.enter().append("text")
		.text((d) -> d.kanji)
		
	force.on 'tick', (e) ->
		kanji
			.attr('x', (d) -> d.x)
			.attr('y', (d) -> d.y)
	
copyAttrs = (a, b) -> a[k] = v for k, v of b
P = (args...) -> console.log args...; return args[0]
W = (width, str) ->
	str = ""+str
	width = Math.max str.length, width
	str + (" " for [1..width-str.length]).join ''

do ->
	i = 2
	runMain = -> main() if --i == 0
	window.onload = runMain
	load runMain
