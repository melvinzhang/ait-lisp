#lang s-exp syntax/module-reader
ait
#:wrapper1 (λ (t)
             (parameterize ([current-readtable
                             (make-at-readtable #:datum-readtable 'dynamic)])
               (t)))
(require (only-in scribble/reader make-at-readtable))
