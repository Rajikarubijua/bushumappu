config =
	showLines: 					false
	filterRadicals:				(radicals) -> radicals[...14]
	filterLinkedRadicals:		(radicals) -> radicals
	sunflowerKanjis:			true
	kmeansInitialVectorsRandom:	false
	kmeansClustersN:			-1 # 0 rule of thumb, -1 vector.length
	forceGraph:					false
	circularLines:				false
	gridSpacing:				gridSpacing = 48
	debugOverlay:				false
	transitionTime:				2000
	initialScale:				1
	edgesBeforeSnap:			false
	timeToOptimize:				3000
	optimizeMaxLoops:			0
	optimizeMaxSteps:			0
	slideshowSteps:				1
	nodeSize:					12
	showInitialMode:			false
	debugKanji:					'類'
	overlengthEdge:				gridSpacing * 10
	kanjiOffset:				8
	optimizer:					false

window?.config = config
self?.config = config
