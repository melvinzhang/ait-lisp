HOME = https://www.cs.auckland.ac.nz/~chaitin

download:
	wget ${HOME}/lisp.c
	for i in examples utm godel godel2 godel3 omega omega2 omega3; do \
		wget ${HOME}/$$i.l; \
		wget ${HOME}/x$$i.l; \
		wget ${HOME}/$$i.r; \
		wget ${HOME}/x$$i.r; \
	done
	wget ${HOME}/omega2vb.l
