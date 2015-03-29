define 'detail_table', ['utils'], ({P, arrayUnique}) ->
	class DetailTable
		constructor: () ->
			@list = []

		addKanji: (kanji) ->
			if kanji not in @list
				@list.unshift kanji
				@list = arrayUnique @list
				@render()
			else
				P "cannot add: kanji is already in table"

		removeKanji: (kanji) ->

			for k in @list
				if k.kanji == kanji
					kanji = k

			if kanji in @list
				newlist = []
				for k in @list
					if k.kanji != kanji.kanji
						newlist.push k
				@list = newlist
				@render() 
			else
				P "cannot remove: kanji is not in table"


		render: () ->
			table = d3.select('table#details tbody')
			table_data = [[],[],[],[],[]]
			table.selectAll('td.content').remove()
			
			for k in @list
				radicals = (r.radical for r in k.radicals)
				table_data[0].push k.kanji
				table_data[1].push k.meaning
				table_data[2].push radicals
				table_data[3].push k.onyomi
				table_data[4].push k.kunyomi

			# enter
			table_tr = table.selectAll('tr').data(table_data)
			table_td = table_tr.selectAll('td.content').data((d) -> d)
			table_tr.enter()
				.append('tr')
				.classed('content', true)
			
			table_td.enter()
				.append('td')
				.classed("content", true)
			
			table_td.text((d) -> d)

			@updateListener()

		updateListener: () ->

			me = this

			setFuncTimer = ( obj, ms, func) ->
				obj.funcTimer = setTimeout(((d) -> func d), ms)
				
			clearFuncTimer = (obj) ->	
				clearTimeout(obj.funcTimer)
				obj.funcTimer = null

			displayDeleteTableCol = (d) ->
				# do not display this for the very first column 
				# that contains description text
				return if d == undefined
				# we only need 1 button
				return if d3.select(this).selectAll('g')[0].length != 0
				
				removeBtn = d3.select(this).append('g').classed('remove-col-btn', true)
				removeBtn.append('text').text('X')
				removeBtn.on('click.removeTableCol', (d) -> 
					me.removeKanji d
					d3.event.stopPropagation() 
				)
				this.removeBtn = removeBtn

			table = d3.select('table#details tbody')			
			colLabels = table.select('tr').selectAll('td')
				.on('mouseenter.hoverLabel', (d) -> 
					that = this
					setFuncTimer(that, 500, -> displayDeleteTableCol.call(that, d)))
				.on('mouseleave.resetHoverLabel', (d) ->
					clearFuncTimer(this)
					d3.select(d3.event.srcElement.childNodes[1]).remove())

	{ DetailTable }