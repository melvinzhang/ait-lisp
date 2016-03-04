SHELL = /bin/bash

lisp: src/lisp.c
	cc -O -o$@ $^

LM = https://www.cs.auckland.ac.nz/~chaitin
download_lm:
	wget ${LM}/lisp.c -P src
	for i in examples utm godel godel2 godel3 omega omega2 omega3 omega2vb; do \
		wget ${LM}/$$i.l  -P lm/ ; \
		wget ${LM}/$$i.r  -P lm/; \
		wget ${LM}/x$$i.l -P lm/; \
		wget ${LM}/x$$i.r -P lm/; \
	done

UK = https://www.cs.auckland.ac.nz/~chaitin/unknowable
download_uk:
	wget ${UK}/lisp.java -P src
	wget ${UK}/Sexp.java -P src
	for i in sets fixedpoint turing chaitin godel; do \
		wget ${UK}/$$i.l -P unknowable/; \
		wget ${UK}/$$i.r -P unknowable/; \
	done

AIT = https://www.cs.auckland.ac.nz/~chaitin/ait/
download_ait:
	for i in utm2 exec kraft occam decomp lemma martin-lof martin-lof2 solovay chaitin chaitin2; do \
		wget ${AIT}/$$i.l -P ait/; \
		wget ${AIT}/$$i.r -P ait/; \
	done

%.test: lisp
	diff <(./lisp < $*.l | grep -v Elapsed) <(grep -v Elapsed $*.r)

tests:
	for i in unknowable/*.l; do make $${i%.l}.test; done
