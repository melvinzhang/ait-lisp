#lang racket/base
;; #lang ait: Racket, plus Chaitin LISP object code written @lisp{...}
;; and meta forms that measure, run and check it. See forms.rkt.
;;
;; Running a module prints each check as it happens, then a summary;
;; the main submodule exits with status 1 if any check failed.
(require "forms.rkt")

(provide (except-out (all-from-out racket/base) #%module-begin)
         (except-out (all-from-out "forms.rkt") report-summary!)
         (rename-out [ait-module-begin #%module-begin])
         #%ait-check)

;; Checks print as they run.
(define (#%ait-check c) (print-check c))

(define-syntax-rule (ait-module-begin form ...)
  (#%module-begin
   form ...
   (module+ main (report-summary!))))
