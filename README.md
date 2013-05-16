Commands for your shell:

```bash
make # builds ALL the stuff
make run # runs some web server and chromium
make watch # compile automatically on changes
```
    
Or for the manual experience (DONT! Fix the `Makefile` instead!)

* `coffee -o js -cm src` compile the `src/*.coffee` files to `js`
* `coffee -o js -wm src` compile automatically on changes
* `python3 -m http.server` run a web server
* `chromium-browser "http://localhost:8000"` point a browser to your web server

