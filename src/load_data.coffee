define ['utils'], ({ P, async, parseMaybeNumber }) ->

	load = (cb) ->
		# load ALL the data concurrently
		async.map {
			krad: (cb) -> d3.text "data/krad", cb
			radk: (cb) -> d3.text "data/radk", cb
			# XXX radk doesn't contain radicals "邑龠" which are in krad
			jouyou: (cb) -> d3.text "data/jouyou", cb
			kext: (cb) -> d3.text "data/kext", cb
			}, cb
			
	parse = (data) ->
		parseKrad 	data.krad[1]
		parseRadk 	data.radk[1]
		parseJouyou data.jouyou[1]
		parseKext 	data.kext[1]

	parseKrad = (content) ->
		lines = content.split '\n'

		for line, i in lines
			# parse line
			continue if line[0] == '#' || !line
			kanji = line[0]
			if line[1..3] != ' : '
				throw "expected \" : \" at line #{i}, got \"#{line[1..3]}\""
			radicals = line[4..].trim().split ' '
			# fill datastructures
			o = my.kanjis[kanji] ?= { kanji }
			o.radicals = radicals
			for radical in radicals
				o = my.radicals[radical] ?= { radical }
				o.kanjis ?= ""
				o.kanjis += kanji

	parseRadk = (lines) ->
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
				if radical
					radical.strokes_n = +strokes_n
					radical.kanjis = strUnique radical.kanjis, kanjis
				[ _, radical, strokes_n ] = m
				radical = my.radicals[radical]

	parseJouyou = (content) ->
		lines = content.split '\n'
		allkanji = ""

		for line, i in lines
			# parse line
			continue if line[0] == '#' || !line
			# fill data
			grade  = +line.match /^\d+/
			kanjis = (line.match /:(.*)$/)[1]
			my.jouyou_grade[grade] = kanjis
			allkanji += kanjis

		for char in allkanji
			my.jouyou.push char
			for radical in my.kanjis[char].radicals
				my.jouyou_radicals[radical] ?= ""
				my.jouyou_radicals[radical] += char

	parseKext = (content) ->
		lines = content.split '\n'
		
		for line, i in lines
			continue if line[0] == '#' || !line
			entries = line.split(";")
			for entry in entries
				[ name, obj ] = entry.split(":")	
				name = name?.trim()
				obj = obj?.trim()
				continue if not obj
				if name == "KANJI" 
					kanji = my.kanjis[obj]
					# XXX prints kanji which are not in my.kanjis (krad) but in kext
					# if not kanji? then P obj 
					continue
				map =
					STROKECOUNT: 'stroke_n'
					FREQ: 'freq'
					ON: 'onyomi'
					KUN: 'kunyomi'
					MEAN: 'meaning'
				kanji?[map[name]] ?= parseMaybeNumber obj
	
	(cb) -> load (data) ->
		parse data
		cb()
