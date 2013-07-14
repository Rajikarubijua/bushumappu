define ['utils'], ({P, arrayUnique}) ->
	class History
		constructor: () ->
			@history = []
			@fclass = 'firsthisKanji'
			@nclass = 'hisKanji'
			@target = {}

		# add a string
		addCentral: (central) ->
			@history.unshift central
			@history = arrayUnique @history

		render: () ->
			list = '<ul class=historylist>'
			max_size = 10
			size = 0
			for kanji in @history
				if size == max_size
					break
				if size == 0
					#current central station is not gonna be displayed					
					#list = "#{list} <li class=#{@fclass}> #{kanji} </li>"
				else
					list = "#{list} <li class=#{@nclass}> #{kanji} </li>"
				size = size + +'1'	# i also like to live dangerously

			list = "#{list} </ul>"
			#d3.select('#history')[0][0].innerHTML = list

			me = this
			onClick = () ->
				kanji = this.innerHTML
				me.target.changeToCentralFromStr kanji

			d3.select(".#{@nclass}").on 'click.history', onClick
			
			list

		setup: (eventtarget) ->
			@target = eventtarget

		getCurrentCentral: () ->
			@history[0]

	{ History }