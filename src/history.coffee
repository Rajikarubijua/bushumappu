define ['utils'], ({P, arrayUnique}) ->
	class History
		constructor: () ->
			@history = []

		# add a string
		addCentral: (central) ->
			@history.unshift central
			@history = arrayUnique @history
			@render()

		render: () ->
			list = '<ul class=historylist>'
			max_size = 10
			size = 0
			for kanji in @history
				if size == max_size
					break
				if size == 0					
					list = "#{list} <li class=firsthisKanji> #{kanji} </li>"
				else
					list = "#{list} <li class=hisKanji> #{kanji} </li>"
				size = size + +'1'	# i also like to live dangerously

			list = "#{list} </ul>"
			d3.select('#history')[0][0].innerHTML = list

	{ History }