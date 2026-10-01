#lang racket/base
;; Command-line runner, a drop-in for ./lisp:
;;   racket src/ait/run.rkt < lm/godel.l
;;   racket src/ait/run.rkt lm/godel.l
(require racket/cmdline "machine.rkt")

(module+ main
  (define file
    (command-line #:args ([file #f]) file))
  (if file
      (call-with-input-file file run-machine)
      (run-machine)))
