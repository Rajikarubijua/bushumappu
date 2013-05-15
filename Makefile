#!/usr/bin/env make
webserver  = python3 -m http.server
#webserver  = python2 -m SimpleHTTPServer
webbrowser = chromium-browser "http://localhost:8000"
#webbrowser = firefox "http://localhost:8000"

src_coffee_files = $(wildcard src/*.coffee)
build_js_files   = $(src_coffee_files:src/%.coffee=js/%.js)

PHONY+=all
all: check_build_deps $(build_js_files)

js/%.js: src/%.coffee js
	coffee -o js -cm $< 

js:
	mkdir js
	
PHONY+=clean
clean:
	rm -r js
	
PHONY+=run
run:
	( sleep 1 && $(webbrowser) ) &
	$(webserver)
	
PHONY+=check_build_deps
check_build_deps:
	@coffee --version || echo "Please install CoffeeScript 1.6.2+"

