#!/bin/bash
sed -i 's/ä/"a/g' *.tex
sed -i 's/Ä/"A/g' *.tex
sed -i 's/ü/"u/g' *.tex
sed -i 's/Ü/"U/g' *.tex
sed -i 's/ö/"o/g' *.tex
sed -i 's/Ö/"O/g' *.tex
sed -i 's/ß/"s/g' *.tex

pdflatex documentation.tex &&
bibtex documentation.aux &&
pdflatex documentation.tex &&
pdflatex documentation.tex &&
rm -f *.aux *.log *.nav *.out *.snm *.toc *.blg *.bbl .log

notify-send -t 3000  "pdflatex: " "$(date +%H:%M) done!"

