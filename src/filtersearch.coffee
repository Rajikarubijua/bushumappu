define ['utils'], ({P}) ->

	class FilterSearch
		constructor: ({@graph, @view})->
			@inHandler = new InputHandler {@graph}

		filter: () ->
			criteria = @inHandler.getInputData()
			for node in @graph.nodes
				if @isWithinCriteria(node.data, criteria)
					node.style.filtered = false
				else
					node.style.filtered = true

			for edge in @graph.edges
				nearHidden = edge.source.style.filtered or edge.target.style.filtered 
				if nearHidden 
					edge.style.filtered = true

			@view.update()

		search: () ->
			searchresult = []
			criteria = @inHandler.getInputData()
			for node in @graph.nodes
				node.style.isSearchresult = false
				if @isWithinCriteria(node.data, criteria)
					node.style.isSearchresult = true
					searchresult.push node

			@view.update()
			searchresult

		resetFilter: (id) -> 
			@inHandler.fillStandardInput(id)

		resetAll: () ->
			for node in @graph.nodes
				node.style.isSearchresult = false
				node.style.filtered = false
			for edge in @graph.edges
				edge.style.isSearchresult = false
				edge.style.filtered = false
			@inHandler.clearInput()
			@view.update()

		autoFocus: (kanji) ->
			@view.autoFocus(kanji)

		isWithinCriteria: (kanji, criteria) ->
			{strokeMin, strokeMax, frqMin, frqMax, gradeMin, gradeMax, inKanji, inOn, inKun, inMean} = criteria
			withinStroke 	= kanji.stroke_n >= strokeMin and kanji.stroke_n <= strokeMax
			withinFrq 		= kanji.freq <= frqMin and kanji.freq >= frqMax   #attention: sort upside down
			withinGrade 	= kanji.grade >= gradeMin and kanji.grade <= gradeMax
			withinInKanji 	= @check kanji.kanji,   inKanji
			withinInOn 		= @check kanji.onyomi,  inOn
			withinInKun		= @check kanji.kunyomi, inKun
			withinInMean	= @check kanji.meaning, inMean

			# check if every criteria fits
			withinStroke and withinFrq and withinGrade and withinInKanji and withinInOn and withinInKun and withinInMean

		# check if in kanji valuedata has at least one item of input fielddata
		check: (arrValueData, arrFieldData) ->
			# ignore empty fields
			if arrFieldData == undefined or arrFieldData == ''
				return true
			# exclude unknown kanji
			if arrValueData == undefined
				return false
			
			token_jp = '、'
			token_dt = ','

			if arrValueData.indexOf(token_jp) == -1
				arrValueData = arrValueData.split token_dt
			else
				arrValueData = arrValueData.split token_jp

			if arrFieldData.indexOf(token_jp) == -1
				arrFieldData = arrFieldData.split token_dt
			else
				arrFieldData = arrFieldData.split token_jp

			for item in arrFieldData
				for value in arrValueData
					if value == item and item != ''
						return true
			false

		setup: () ->
			@inHandler.fillStandardInput('', true)


	class InputHandler
		constructor: ({@graph})->

		displayResult: ( result ) ->
			resultString = ''
			for node in result
				resultString = "#{resultString} <div class='searchKanji'>#{node.data.kanji}</div>"
			
			if resultString == ''
				resultString = 'nothing found in current view'

			d3.select('table #kanjiresult')[0][0].innerHTML =
				"#{resultString}"

		# if flag then fill force
		fillStandardInput: (id, flag) ->
			flag ?= false
			if id == 'btn_clear1' or flag
				@fillInputData '#count_min',	1
				@fillInputData '#count_max', @getStrokeCountMax(@graph)
			if id == 'btn_clear2' or flag
				@fillInputData '#frq_min',	@getFreqMax(@graph)
				@fillInputData '#frq_max',	1
			if id == 'btn_clear3' or flag
				@fillInputData '#grade_min',	1
				@fillInputData '#grade_max',	Object.keys(my.jouyou_grade).length

		# fill fields with standard and with test data
		fillSeaFilTest: ()->
			@fillStandardInput(@graph, '', true)

			# testing
			@fillInputData '#kanjistring',	'日,木,森'
			@fillInputData '#onyomistring',	'ニチ'
			@fillInputData '#kunyomistring', 'ひ,き'
			@fillInputData '#meaningstring', 'day'

		clearInput: () ->
			@fillStandardInput('', true)
			@fillInputData '#kanjistring',	''
			@fillInputData '#onyomistring',	''
			@fillInputData '#kunyomistring', ''
			@fillInputData '#meaningstring', ''

		fillInputData: (id, value) ->
			path = "#seafil form #{id}"
			d3.select(path).property 'value', value

		getInputInt: (id) ->
			path = "#seafil form #{id}"
			+d3.select(path).property('value').trim()

		getInput: (id) ->
			path = "#seafil form #{id}"
			d3.select(path).property('value').trim()

		getInputData: () ->
			strokeMin 	: @getInputInt '#count_min'
			strokeMax 	: @getInputInt '#count_max'
			frqMin		: @getInputInt '#frq_min'
			frqMax		: @getInputInt '#frq_max'
			gradeMin	: @getInputInt '#grade_min'
			gradeMax	: @getInputInt '#grade_max'
			inKanji 	: @getInput '#kanjistring'
			inOn 		: @getInput '#onyomistring'
			inKun 		: @getInput '#kunyomistring'
			inMean 		: @getInput '#meaningstring'

		getStrokeCountMax: () ->
			max = 1
			for kanji in @graph.kanjis()
				if kanji.stroke_n > max
					max = kanji.stroke_n
			max

		getFreqMax: () ->
			max = 1
			for kanji in @graph.kanjis()
				if kanji.freq > max
					max = kanji.freq
			max	


	{FilterSearch}
