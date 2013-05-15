src_coffee_files = $(wildcard src/*.coffee)
build_js_files   = $(src_coffee_files:src/%.coffee=js/%.js)

all: $(build_js_files)

js/%.js: src/%.coffee js
	coffee -o js -cm $< 

js:
	mkdir js
	
clean:
	rm -r js
	
run:
	( sleep 1 && chromium-browser "http://localhost:8000" ) &
	python3 -m http.server
