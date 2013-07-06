define ['utils'], ({P}) ->
	class History
		constructor: () ->
			@history = []

		addCentral: (central) ->
			# duplicate input?
			@history.unshift central
			@render()

		render: () ->
			list = ''
			max_size = 10
			size = 0
			for node in @history
				if size == max_size
					break
				if size == 0					
					list = "#{list} <div class=firsthisKanji> #{node.data.kanji} </div> <br>"
				else
					list = "#{list} <div class=hisKanji> #{node.data.kanji} </div>"
				size = size + +'1'	# i also like to live dangerously

			d3.select('#history')[0][0].innerHTML = list

	{ History }