[[[[[
   Show that a real r is Solovay random
   iff it is strong Chaitin random.

   An effective covering A_k of k is a function
   of k that enumerates bit strings s,
   which are the initial bits of the covered
   reals.  We assume that no s in A_k is a
   proper prefix or extension of another.
   Thus the measure of the cover A_k of k is
   exactly Sum_{s in A_k} of 2^{-|s|},
   where |s| is the length of the bit string s.
]]]]]

[First part: not Sol random ===> not Ch random] 

[We create the following set of requirements] 
[(output, size-of-program)]
[ (s, |s|) : s in A_n, n >= N, Sum_{n >= N} mu A_n <= 1] 

[Stage k>=0, look at all A_n, n = N to N+k for time k.]
[Then have to combine stage 0, stage 1,...] 
[and eliminate duplicates]

[infinite computation that displays strings] 
[in cover A_m with total measure Sum_m of mu A_m < infinity]
define (A m) 
   cdr cons
   [test case, A_m = string of m 1's]
   display base10-to-2 - ^ 2 m 1
   nil

define      A
value       (lambda (m) (cdr (cons (display (base10-to-2 (- (^
             2 m) 1))) nil)))

[in the proof we pick N so that] 
[the total measure Sum_{m >= N} of mu A_m <= 1]
[for example,]
define N 5

define      N
value       5

define (is-in? x l) [is x in the list l?]
   if atom l    false
   if = x car l true
   (is-in? x cdr l)

define      is-in?
value       (lambda (x l) (if (atom l) false (if (= x (car l))
             true (is-in? x (cdr l)))))

define (convert-to-requirements cover) [display requirements]
   if atom cover requirements [finished?]
   let s         car cover [get first string]
   let cover     cdr cover [get rest of strings]
   let requirement 
       cons s cons length s nil [form (s, |s|)]
   if (is-in? requirement requirements) [duplicate?]
   [yes] (convert-to-requirements cover)
   [no]  let requirements cons display requirement requirements
         (convert-to-requirements cover)

define      convert-to-requirements
value       (lambda (cover) (if (atom cover) requirements ((' 
            (lambda (s) ((' (lambda (cover) ((' (lambda (requi
            rement) (if (is-in? requirement requirements) (con
            vert-to-requirements cover) ((' (lambda (requireme
            nts) (convert-to-requirements cover))) (cons (disp
            lay requirement) requirements))))) (cons s (cons (
            length s) nil))))) (cdr cover)))) (car cover))))

define (stage k)
   if = k 5 stop! [[[stop infinite computation!!!]]]
   let (loop i) [i = 0 to k]
      if > i k (stage + k 1) [go to next stage]
      let expr cons cons "' cons A nil
                    cons + N i nil
      let cover caddr try k expr nil    
      let requirements (convert-to-requirements cover)
      (loop + i 1) [bump i]
   [initialize i]
   (loop 0)

define      stage
value       (lambda (k) (if (= k 5) stop! ((' (lambda (loop) (
            loop 0))) (' (lambda (i) (if (> i k) (stage (+ k 1
            )) ((' (lambda (expr) ((' (lambda (cover) ((' (lam
            bda (requirements) (loop (+ i 1)))) (convert-to-re
            quirements cover)))) (car (cdr (cdr (try k expr ni
            l))))))) (cons (cons ' (cons A nil)) (cons (+ N i)
             nil)))))))))

[to remove duplicates]
define requirements ()

define      requirements
value       ()

[run it]
(stage 0)

expression  (stage 0)
display     ((1 1 1 1 1) 5)
display     ((1 1 1 1 1 1) 6)
display     ((1 1 1 1 1 1 1) 7)
display     ((1 1 1 1 1 1 1 1) 8)
display     ((1 1 1 1 1 1 1 1 1) 9)
value       stop!
