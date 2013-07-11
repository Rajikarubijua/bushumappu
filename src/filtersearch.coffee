define ['utils'], ({P}) ->

	class FilterSearch

		setup: (view, isInitial) ->
			@view = view
			if @view.graph == undefined or isInitial
				@kanjis = @view.kanjis
			else
				@kanjis = @view.graph.kanjis()

			isInitial ?= false

			@inHandler = new InputHandler {@kanjis}
			@inHandler.fillStandardInput('', true)
			@inHandler.setupFilterSearchEvents(this, isInitial)
			@inHandler.renderKanjiList() if isInitial
			@inHandler.reloadInitialSwitch this if isInitial

		filter: (graph) ->
			criteria = @inHandler.getInputData()
			for node in graph.nodes
				if @isWithinCriteria(node.data, criteria)
					node.style.filtered = false
				else
					node.style.filtered = true

			for edge in graph.edges
				nearHidden = edge.source.style.filtered or edge.target.style.filtered 
				if nearHidden 
					edge.style.filtered = true

			@view.update()

		search: (graph) ->
			searchresult = []
			criteria = @inHandler.getInputData()
			for node in graph.nodes
				node.style.isSearchresult = false
				if @isWithinCriteria(node.data, criteria)
					node.style.isSearchresult = true
					searchresult.push node

			@view.update()
			searchresult

		update: () ->
			searchresult = []
			criteria = @inHandler.getInputData()
			for k in @kanjis
				if @isWithinCriteria(k, criteria)
					searchresult.push k

			@inHandler.renderKanjiList searchresult
			@inHandler.reloadInitialSwitch this


		resetFilter: (id) -> 
			@inHandler.fillStandardInput(id)

		resetAll: (graph) ->
			for node in graph.nodes
				node.style.isSearchresult = false
				node.style.filtered = false
			for edge in graph.edges
				edge.style.isSearchresult = false
				edge.style.filtered = false
			@inHandler.clearInput()
			@inHandler.clearSearchResult()
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


	class InputHandler
		constructor: ({@kanjis})->

		displayResult: ( result, length) ->
			length ?= 7
			resultString = ''
			i = 0
			for node in result
				if i == length
					resultString = "#{resultString} <span class=lower> [...] </span>"
					break
				i++
				resultString = "#{resultString} <div class='searchKanji'>#{node.data.kanji}</div>"
			
			if resultString == ''
				resultString = 'nothing found in current view'

			d3.select('#kanjiresultCount')[0][0].innerHTML = "#{result.length} found"
			d3.select('table #kanjiresult')[0][0].innerHTML =
				"#{resultString}"

		renderKanjiList: (arrKanjis) ->
			arrKanjis ?= @kanjis
			list = ''
			for k in arrKanjis
				list = "#{list} <div class='searchKanji'>#{k.kanji}</div>"
			if list == ''
				list = 'no kanji found'
			else
				list = "<div> #{arrKanjis.length} kanji have been found. </div> #{list}"

			d3.select('#kanjilist')[0][0].innerHTML = list

		# if flag then fill force
		fillStandardInput: (id, flag) ->
			flag ?= false
			if id == 'btn_clear1' or flag
				@fillInputData '#count_min',	1
				@fillInputData '#count_max', @getStrokeCountMax(@kanjis)
			if id == 'btn_clear2' or flag
				@fillInputData '#frq_min',	@getFreqMax(@kanjis)
				@fillInputData '#frq_max',	1
			if id == 'btn_clear3' or flag
				@fillInputData '#grade_min',	1
				@fillInputData '#grade_max',	Object.keys(my.jouyou_grade).length

		# fill fields with standard and with test data
		fillSeaFilTest: ()->
			@fillStandardInput('', true)

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

		clearSearchResult: () ->
			d3.select('#kanjiresult')[0][0].innerHTML = ''
			d3.select('#kanjiresultCount')[0][0].innerHTML = ""

		fillInputData: (id, value) ->
			path = "form #{id}"
			d3.selectAll(path).property 'value', value

		getInputInt: (id) ->
			path = "form #{id}"
			+d3.selectAll(path).property('value').trim()

		getInput: (id) ->
			path = "form #{id}"
			d3.selectAll(path).property('value').trim()

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

		getStrokeCountMax: (kanjis) ->
			max = 1
			for kanji in kanjis
				if kanji.stroke_n > max
					max = kanji.stroke_n
			max

		getFreqMax: (kanjis) ->
			max = 1
			for kanji in kanjis
				if kanji.freq > max
					max = kanji.freq
			max	

		setupFilterSearchEvents: (filsea, isInitial) ->

			filter = () ->
				filsea.filter(filsea.view.graph)

			autoFocus = () ->
				kanji = d3.event.srcElement.innerHTML
				filsea.autoFocus(kanji)

			search = () ->
				result = filsea.search(filsea.view.graph)
				filsea.inHandler.displayResult(result)
				d3.selectAll('#kanjiresult .searchKanji').on 'click' ,  autoFocus

			resetFilter = () ->
				filsea.resetFilter(d3.event.srcElement.id)
				filsea.update()

			resetAll = () ->
				filsea.resetAll(filsea.view.graph)

			update = () ->
				filsea.update()

			# all
			d3.selectAll('#btn_clear1').on 'click' ,  resetFilter
			d3.selectAll('#btn_clear2').on 'click' ,  resetFilter
			d3.selectAll('#btn_clear3').on 'click' ,  resetFilter

			if !isInitial
				# central view
				d3.select('#btn_filter').on 'click' , filter
				d3.select('#btn_search').on 'click' , search
				d3.select('#btn_reset').on 'click' ,  resetAll
			else
				# initial view
				d3.selectAll('form input[type=text]').on 'change' , update

		reloadInitialSwitch: (filsea) ->

			switchToMain = () ->
				#d3.select('#overlay').style 'display', 'none'
				d3.select('#overlay').remove()
				strKanji = d3.event.srcElement.innerHTML
				filsea.view.changeToCentralFromStr(strKanji)

			d3.selectAll('#overlay .searchKanji').on 'click', switchToMain


	{FilterSearch}
