#lang racket/base
;; `#lang ait/classic`: the rest of the file is an unmodified Chaitin
;; LISP program. Running the module prints the same transcript as
;; `./lisp < program.l`.
;;
;; The source is embedded verbatim because the transcript echoes the
;; input character by character as the machine reads it.
(require racket/port)

(provide (rename-out [classic-read read]
                     [classic-read-syntax read-syntax]))

(define (classic-read in)
  (syntax->datum (classic-read-syntax #f in)))

(define (classic-read-syntax src in)
  (define text (port->bytes in))
  ;; Drop the newline that ends the #lang line.
  (define body (regexp-replace #rx#"^\r?\n" text #""))
  (datum->syntax
   #f
   `(module classic racket/base
      (require ait/machine)
      (run-machine (open-input-bytes ,body) (current-output-port)))))
