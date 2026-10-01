#lang racket/base
;; #lang ait/scribble: a Scribble document whose checks run as it builds.
;;
;; The body is prose, as in #lang scribble/base, with the ait forms
;; available. Object code is shown as written along with its measured
;; size; expect, bound, property and threshold render their results
;; with a ✓ or ✗; and a final section lists every check. Running the
;; module directly prints failed checks and exits with status 1 if any.
;;
;;   raco scribble --html --dest out doc.scrbl   renders it
;;   racket doc.scrbl                            only runs the checks

(require (for-syntax racket/base)
         (prefix-in doclang: scribble/doclang)
         scribble/base
         scribble/core
         scribble/html-properties
         scribble/latex-properties
         racket/list
         racket/runtime-path
         racket/string
         "forms.rkt")

(provide (except-out (all-from-out racket/base) #%module-begin)
         (all-from-out scribble/base)
         (except-out (all-from-out "forms.rkt") report-summary! print-check)
         (rename-out [ait-doc-module-begin #%module-begin])
         #%ait-check
         define-lisp define-lisp* lisp-code show-lisp
         m mm theorem proof)

(define-runtime-path css-file "scribble/ait.css")
(define-runtime-path tex-file "scribble/ait.tex")

(define-syntax (ait-doc-module-begin stx)
  (syntax-case stx ()
    [(_ id post-process exprs . body)
     #'(doclang:#%module-begin
        id ait-post-process exprs
        (module+ main (report-summary! #:list-failures? #t))
        . body)]))

;; --- Styles ---

(define (cls name) (style name '()))

(define katex "https://cdn.jsdelivr.net/npm/katex@0.16.11/dist/")

(define page-properties
  (list (css-addition css-file)
        (tex-addition tex-file)
        (head-extra `(link ([rel "stylesheet"] [href ,(string-append katex "katex.min.css")])))
        (head-extra `(script ([defer "defer"] [src ,(string-append katex "katex.min.js")]) ""))
        (head-extra `(script ([defer "defer"]
                              [src ,(string-append katex "contrib/auto-render.min.js")]
                              [onload "renderMathInElement(document.body)"])
                             ""))))

;; Adds the page styles, then a final section listing every check.
(define (ait-post-process doc)
  (define s (part-style doc))
  (struct-copy part doc
               [style (style (style-name s) (append page-properties (style-properties s)))]
               [parts (append (part-parts doc) (list (checks-part)))]))

(define (checks-part)
  (define cs (checks))
  (define failed (count (λ (c) (not (check-ok? c))) cs))
  (part #f
        (list (list 'part "ait-checks"))
        (list "Checks")
        (style #f '(unnumbered))
        '()
        (list (para (format "~a checks ran while this document was built; ~a."
                            (length cs)
                            (if (zero? failed) "all passed" (format "~a failed" failed))))
              (if (null? cs)
                  (para "")
                  (tabular #:style (cls "AitChecks")
                           (for/list ([c cs])
                             (list (badge (check-ok? c))
                                   (element (cls "AitWhere") (check-where c))
                                   (para (label-elem c) " " (detail-elem c)))))))
        '()))

;; --- Math ---

;; @m{...} is inline TeX, @mm{...} display TeX; KaTeX renders them in HTML.
(define (tex s) (element (style #f '(exact-chars)) s))
(define (m . strs) (tex (string-append "\\(" (string-append* strs) "\\)")))
(define (mm . strs) (paragraph (cls "AitDisplayMath")
                               (tex (string-append "\\[" (string-append* strs) "\\]"))))

;; --- Prose blocks ---

(define (theorem #:title [title "Theorem"] . content)
  (nested #:style (cls "AitTheorem") (bold title ".") " " content))

(define (proof . content)
  (nested #:style (cls "AitProof") (italic "Proof.") " " content))

;; --- Object code ---

;; @define-lisp[name]{...} defines name as the parsed expression and
;; shows the source as written, with what it measures.
(define-syntax-rule (define-lisp name piece ...)
  (begin
    (define name (lisp piece ...))
    (source-block 'name (list piece ...) (measure-caption name))))

(define-syntax-rule (define-lisp* name piece ...)
  (begin
    (define name (lisp* piece ...))
    (source-block 'name (list piece ...)
                  (format "~a definitions, total size ~a"
                          (length name) (apply + (map size name))))))

;; @lisp-code{...} shows object code without defining anything.
(define (lisp-code . pieces) (source-block #f pieces (measure-caption (apply lisp pieces))))

(define (measure-caption e)
  (define hs (holes e))
  (if (null? hs)
      (format "size ~a" (size e))
      (format "size ~a outside the holes ~a"
              (overhead e)
              (string-join (map (λ (h) (format "{~a}" h)) hs) ", "))))

(define (source-block name pieces caption)
  (define text
    (regexp-replace
     #rx"^[ \t]*\n+"
     (string-trim
      (string-append* (for/list ([p pieces]) (if (string? p) p (show p))))
      #:left? #f)
     ""))
  (nested #:style (cls "AitCode")
          (verbatim text)
          (para #:style (cls "AitCaption")
                (if name (list (tt (symbol->string name)) ": ") '())
                caption)))

;; @show-lisp[e] shows an S-expression as the machine prints it.
(define (show-lisp e #:width [width 72])
  (define s (show e))
  (nested #:style (cls "AitCode")
          (verbatim (string-join (for/list ([i (in-range 0 (string-length s) width)])
                                   (substring s i (min (string-length s) (+ i width))))
                                 "\n"))
          (para #:style (cls "AitCaption") (format "size ~a" (size e)))))

;; --- Checks ---

(define (badge ok?)
  (case ok?
    [(#t) (element (cls "AitPass") "✓")]
    [(#f) (element (cls "AitFail") "✗")]
    [else ""]))

;; Labels and details hold object code, so they are shown verbatim:
;; no decoding of quotes or dashes.
(define (code s) (element 'tt s))

(define (label-elem c)
  (if (eq? 'property (check-kind c))
      (check-label c)
      (code (check-label c))))

(define (detail-elem c) (code (check-detail c)))

(define (#%ait-check c)
  (cond
    [(check-table c)
     (define-values (kname explain rows) (apply values (check-table c)))
     (define kn (symbol->string kname))
     (nested #:style (cls "AitThreshold")
             (if explain (para explain) '())
             (tabular #:style (cls "AitTable")
                      #:row-properties '(bottom-border ())
                      (cons (list (tt kn) "size" "observed")
                            (for/list ([r rows])
                              (list (tt (format "~a" (car r)))
                                    (format "~a" (cadr r))
                                    (code (caddr r))))))
             (if (eq? 'none (check-ok? c))
                 '()
                 (para (badge (check-ok? c)) " " (check-label c) " " (detail-elem c))))]
    [else
     (paragraph (cls "AitCheck")
                (list (badge (check-ok? c)) " " (label-elem c) " " (detail-elem c)))]))
