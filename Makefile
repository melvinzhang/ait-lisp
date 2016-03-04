SHELL = /bin/bash

lisp: src/lisp.c
	cc -O -o$@ $^

LM = https://www.cs.auckland.ac.nz/~chaitin
download_lm:
	wget ${HOME}/lisp.c
	for i in examples utm godel godel2 godel3 omega omega2 omega3; do \
		wget ${LM}/$$i.l; \
		wget ${LM}/x$$i.l; \
		wget ${LM}/$$i.r; \
		wget ${LM}/x$$i.r; \
	done
	wget ${LM}/omega2vb.l

UK = https://www.cs.auckland.ac.nz/~chaitin/unknowable
download_uk:
	for i in sets fixedpoint turing chaitin; do \
		wget ${UK}/$$i.l; \
		wget ${UK}/$$i.r; \
	done
	wget ${UK}/godel.l -O godel4.l
	wget ${UK}/godel.r -O godel4.r

%.test: lisp
	diff <(./lisp < $*.l | grep -v Elapsed) <(grep -v Elapsed $*.r)

tests:
	for i in *.l; do make `basename $$i .l`.test; done
