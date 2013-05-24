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

Hacking:

* read the recent git log
* pick an [issue]( https://github.com/Rajikarubijua/bushumappu/issues )
  you want to do
* make small commits
* branch when it will take longer... it will take longer ;)
* if your code looks like hell after a long time of try and error,
  call for backup! Step back and think of some programming tactics:
 * splitting the task into phases
 * work first on single elements before recursion/iteration
 * you can change datastructures as you like
 * how would you do it with pen and paper?
