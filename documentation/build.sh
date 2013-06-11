#!/bin/bash
pdflatex documentation.tex
pdflatex documentation.tex
rm -f *.aux *.log *.nav *.out *.snm *.toc *.blg *.bbl .log

notify-send -t 3000  "pdflatex: " "$(date +%H:%M) done!"