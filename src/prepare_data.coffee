define ['utils'], ({ }) ->

	prepare_data = ->
		jouyou_kanjis = []
		for radical, kanjis of my.jouyou_radicals
			kanjis = (my.kanjis[k] for k in kanjis)
			my.radicals[radical].jouyou = kanjis
			for k in kanjis
				if k not in jouyou_kanjis
					jouyou_kanjis.push k
					
		setup_kanji_grades()
		
		{ jouyou_kanjis }
		
	setup_kanji_grades = ->
		for grade, kanjis of my.jouyou_grade
			for kanji in kanjis
				my.kanjis[kanji].grade = +grade
		

	prepare_data
