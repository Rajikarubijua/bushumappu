#!/bin/bash
pandoc -f markdown -t latex -o implementierung.tex --smart implementierung.md

sed -i 's/ä/"a/' *.tex
sed -i 's/Ä/"A/' *.tex
sed -i 's/ü/"u/' *.tex
sed -i 's/Ü/"U/' *.tex
sed -i 's/ö/"o/' *.tex
sed -i 's/Ö/"O/' *.tex
sed -i 's/ß/\ss /' *.tex

pdflatex documentation.tex &&
bibtex documentation.aux &&
pdflatex documentation.tex &&
pdflatex documentation.tex &&
rm -f *.aux *.log *.nav *.out *.snm *.toc *.blg *.bbl .log implementierung.tex

notify-send -t 3000  "pdflatex: " "$(date +%H:%M) done!"

