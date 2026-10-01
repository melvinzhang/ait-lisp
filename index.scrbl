#lang ait/scribble
@; The site's front page, rendered to docs/index.html by `make docs`.

@title{AIT LISP}

Chaitin's programs from algorithmic information theory, as documents whose
claims are checked when they are built.

@itemlist[
  @item{@hyperlink["godel.html"]{Elegant S-expressions cannot be proved elegant}

        From @tt{lm/godel.l}: derives the constant 410 and shows where the
        searcher starts refuting the formal system.}
  @item{@hyperlink["kraft.html"]{The Kraft inequality criterion for constructing computers}

        From @tt{ait/kraft.l}: checks the algorithm's claims on 300 random
        requirement lists.}
]

Each page is written in @tt{#lang ait/scribble} and rendered with
@tt{make docs}. Source:
@hyperlink["https://github.com/melvinzhang/ait-lisp"]{github.com/melvinzhang/ait-lisp}.
