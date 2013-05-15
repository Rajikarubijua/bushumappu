Commands for your shell:

```bash
make # builds ALL the stuff
make run # runs some web server and chromium
watch make # compile automatically every two seconds
```
    
Or for the manual experience (DONT! Fix the `Makefile` instead!)

* `mkdir js` create the `js` directory
* `coffee -o js -cm src/main.coffee` compile the `src/*.coffee` files to `js`
* `python3 -m http.server` run a web server
* `chromium-browser "http://localhost:8000"` point a browser to your web server
