[[[[[ INCOMPLETENESS & LIMITS OF FORMAL SYSTEMS ]]]]]

[ --- Limits on Proofs of Elegance (lm/xgodel.l) --- ]
[godel.l]
 
[Show that a formal system of lisp complexity H_lisp (FAS) = N]
[cannot enable us to exhibit an elegant S-expression of]
[size greater than N + 419.]
[An elegant lisp expression is one with the property that no]
[smaller S-expression has the same value.]
[Setting: formal axiomatic system is never-ending lisp expression]
[that displays elegant S-expressions.]
 
[Idea is to have a program P search for something X that can be proved]
[to be more complex than P is, and therefore P can never find X.]
[I.e., idea is to show that if this program halts we get a contradiction,]
[and therefore the program doesn't halt.]
 
define (size-it-and-run-it exp)
    cadr cons display size display exp
         cons eval exp
              nil
 
(size-it-and-run-it'
+ 5 15
)
 
(size-it-and-run-it'
 
[Examine list x for element that is more than n characters in size.]
[If not found returns false.]
let (examine x n)
    if atom x  false
[]
[   if < n size car x  car x     <=== Change This So Something Interesting Will Happen!]
[]
    if < 1 size car x  car x
    (examine cdr x n)
 
[Here we are given the formal axiomatic system FAS.]
let fas 'display elegant-expression   [Insert FAS here preceeded by "'".]
 
[N = the number of characters in this program including the FAS.]
let n display + 419 size display fas  [N = 419 + |FAS|.]
 
[Loop running the formal axiomatic system.]
let (loop t)                          []
  let v display try display t fas nil [Run the formal system for T time steps.]
  let s (examine caddr v n)           [Did it output an elegant s-exp larger than this program?]
  if s eval s                         [If found elegant s-exp bigger than this program,]
                                      [run it so that its output is our output. Contradiction!]
  if = failure car v (loop + t 1)     [If not, keep looping,]
  failure                             [or halt if formal system halted.]
                                      []
(loop 0)                              [Start loop running with T = 0.]
                                      []
) [end size-it-and-run-it]

[ --- Limits on Proofs of Elegance - Variant (unknowable/chaitin.l) --- ]
[[[[[

 Show that a formal axiomatic system (fas) can only prove 
 that finitely many LISP expressions are elegant.  
 (An expression is elegant if no smaller expression has 
 the same value.)

 More precisely, show that a fas of LISP complexity N can't 
 prove that a LISP expression X is elegant if X's size is 
 greater than N + 356.

 (fas N) returns the theorem proved by the Nth proof 
 (Nth S-expression) in the fas, or nil if the proof is 
 invalid, or stop to stop everything.

]]]]]

[
 This expression searches for an elegant expression 
 that is larger than it is and returns the value of 
 that expression as its own value.
]

define expression  [Formal Axiomatic System #1]
       let (fas n) if = n 1 '(is-elegant x)
                   if = n 2  nil
                   if = n 3 '(is-elegant yyy)
                   [else]    stop 

       let (loop n)
           let theorem [be] display (fas n)
           if = nil theorem [then] (loop + n 1)
           if = stop theorem [then] fas-has-stopped
           if = is-elegant car theorem
              if > display size cadr theorem 
                   display + 356 size fas
                 [return] eval cadr theorem
              [else] (loop + n 1)
           [else] (loop + n 1)

       (loop 1)

[Show that this expression knows its own size.]

size expression
  
[
 Run #1.

 Here it doesn't find an elegant expression 
 larger than it is:
]

eval expression

define expression  [Formal Axiomatic System #2]
       let (fas n) if = n 1 '(is-elegant x)
                   if = n 2  nil
                   if = n 3 '(is-elegant yyy)
                   if = n 4  cons is-elegant 
                             cons ^ 10 509     [<=====]
                                  nil
                   [else]    stop 

       let (loop n)
           let theorem [be] display (fas n)
           if = nil theorem [then] (loop + n 1)
           if = stop theorem [then] fas-has-stopped
           if = is-elegant car theorem
              if > display size cadr theorem 
                   display + 356 size fas
                 [return] eval cadr theorem
              [else] (loop + n 1)
           [else] (loop + n 1)

       (loop 1)

[Show that this expression knows its own size.]

size expression

[
 Run #2.

 Here it finds an elegant expression 
 exactly one character larger than it is: 
]

eval expression

define expression  [Formal Axiomatic System #3]
       let (fas n) if = n 1 '(is-elegant x)
                   if = n 2  nil
                   if = n 3 '(is-elegant yyy)
                   if = n 4  cons is-elegant  
                             cons ^ 10 508     [<=====]
                                  nil
                   [else]    stop 

       let (loop n)
           let theorem [be] display (fas n)
           if = nil theorem [then] (loop + n 1)
           if = stop theorem [then] fas-has-stopped
           if = is-elegant car theorem
              if > display size cadr theorem  
                   display + 356 size fas
                 [return] eval cadr theorem
              [else] (loop + n 1)
           [else] (loop + n 1)

       (loop 1)

[Show that this expression knows its own size.]

size expression

[
 Run #3.

 Here it finds an elegant expression 
 exactly the same size as it is: 
]

eval expression

define expression  [Formal Axiomatic System #4]
       let (fas n) if = n 1 '(is-elegant x)
                   if = n 2  nil
                   if = n 3 '(is-elegant yyy)
                   if = n 4  cons is-elegant 
                             cons cons "- 
                                  cons ^ 10 600  [<=====]
                                  cons 1 
                                       nil 
                                  nil
                   [else]    stop 

       let (loop n)
           let theorem [be] display (fas n)
           if = nil theorem [then] (loop + n 1)
           if = stop theorem [then] fas-has-stopped
           if = is-elegant car theorem
              if > display size cadr theorem 
                   display + 356 size fas
                 [return] eval cadr theorem
              [else] (loop + n 1)
           [else] (loop + n 1)

       (loop 1)

[Show that this expression knows its own size.]

size expression

[
 Run #4.

 Here it finds an elegant expression 
 much larger than it is, and evaluates it: 
]

eval expression

[ --- Limits on Complexity Lower Bounds (lm/xgodel2.l) --- ]
[godel2.l]
 
[Show that a formal system of complexity N]
[can't prove that a specific object has]
[complexity > N + 4696.]
[Formal system is a never halting lisp expression]
[that output pairs (lisp object, lower bound]
[on its complexity).  E.g., (x 4) means]
[that x has complexity H(x) greater than or equal to 4.]
 
[Examine pairs to see if 2nd element is greater than lower bound.]
[Returns false to indicate not found, or pair if found.]
define (examine pairs lower-bound)
    if atom pairs false
    if < lower-bound cadr car pairs
       car pairs
       (examine cdr pairs lower-bound)
(examine '((x 2)(y 3)) 0)
(examine '((x 2)(y 3)) 1)
(examine '((x 2)(y 3)) 2)
(examine '((x 2)(y 3)) 3)
(examine '((x 2)(y 3)) 4)
 
[This is an identity function with the size-effect of]
[displaying the number of bits in a binary string.]
define (display-number-of-bits string)
    cadr cons display length string cons string nil
 
[This is the universal Turing machine U followed by its program.]
cadr try no-time-limit 'eval read-exp
 
[Display number of bits in entire program.]
(display-number-of-bits
 
append [Append prefix and data.]
 
[Display number of bits in the prefix.]
(display-number-of-bits bits '
 
[Examine pairs to see if 2nd element is greater than lower bound.]
[Returns false to indicate not found, or pair if found.]
let (examine pairs lower-bound)
    if atom pairs false
    if < lower-bound cadr car pairs
       car pairs
       (examine cdr pairs lower-bound)
 
                            []
[Main Loop - t is time limit, fas is bits of formal axiomatic system read so far.]
let (loop t fas)            [Run formal axiomatic system again.]
 let v debug try debug t 'eval read-exp debug fas
 [Look for theorem which is pair with 2nd element > # of bits read + size of this prefix.]
 let s (examine caddr v debug + length fas 4696)
 if s car s                 [Found it! Output first element of theorem and halt. Contradiction!]
 if = car v success failure [Surprise, formal system halts, so we do too.]
 if = cadr v out-of-data  (loop t append fas cons read-bit nil)
                            [Read another bit of the formal axiomatic system.]
 if = cadr v out-of-time  (loop + t 1 fas)
                            [Increase time limit]
 unexpected-condition       [This should never happen.]
                            []
(loop 0 nil)    [Initially, 0 time limit and no bits of formal axiomatic system read.]
 
) [end of prefix, start of formal axiomatic system]
 
bits ' display'(x 4881)
 
) [end of entire program for universal Turing machine U]

[ --- Limits on Determining Bits of Omega (lm/xgodel3.l) --- ]
[godel3.l]
 
[Show that a formal system of complexity N]
[can't determine more than N + 9488 + 6912]
[= N + 16400 bits of Omega.]
[Formal system is a never halting lisp expression]
[that outputs lists of the form (1 0 X 0 X X X X 1 0).]
[This stands for the fractional part of Omega,]
[and means that these 0,1 bits of Omega are known.]
[X stands for an unknown bit.]
 
[Count number of bits in an omega that are determined.]
define (number-of-bits-determined w)
    if atom w 0
    + (number-of-bits-determined cdr w)
      if = X car w
         0
         1
[Test it.]
(number-of-bits-determined '(X X X))
(number-of-bits-determined '(1 X X))
(number-of-bits-determined '(1 X 0))
(number-of-bits-determined '(1 1 0))
 
[Merge bits of data into unknown bits of an omega.]
define (supply-missing-bits w)
    if atom w nil
    cons if = X car w
            read-bit
            car w
    (supply-missing-bits cdr w)
[Test it.]
cadr try no-time-limit '
let (supply-missing-bits w)
    if atom w nil
    cons if = X car w
            read-bit
            car w
    (supply-missing-bits cdr w)
(supply-missing-bits '(0 0 X 0 0 X 0 0 X))
'(1 1 1)
cadr try no-time-limit '
let (supply-missing-bits w)
    if atom w nil
    cons if = X car w
            read-bit
            car w
    (supply-missing-bits cdr w)
(supply-missing-bits '(1 1 X 1 1 X 1 1 1))
'(0 0)
 
[Examine omegas in list w to see if in any one of them]
[the number of bits that are determined is greater than n.]
[Returns false to indicate not found, or what it found.]
define (examine w n)
    if atom w false
    if < n (number-of-bits-determined car w)
       car w
       (examine cdr w n)
[Test it.]
(examine '((1 1)(1 1 1)) 0)
(examine '((1 1)(1 1 1)) 1)
(examine '((1 1)(1 1 1)) 2)
(examine '((1 1)(1 1 1)) 3)
(examine '((1 1)(1 1 1)) 4)
 
[This is an identity function with the size-effect of]
[displaying the number of bits in a binary string.]
define (display-number-of-bits string)
    cadr cons display length string
         cons string
              nil
 
[This is the universal Turing machine U followed by its program.]
cadr try no-time-limit 'eval read-exp
 
append [Append missing bits of Omega to rest of program.]
 
[Display number of bits in entire program excepting the missing bits of Omega.]
(display-number-of-bits
 
append [Append prefix and formal axiomatic system.]
 
[Display number of bits in the prefix.]
(display-number-of-bits bits '
 
[Count number of bits in an omega that are determined.]
let (number-of-bits-determined w)
    if atom w 0
    + (number-of-bits-determined cdr w)
      if = X car w
         0
         1
 
[Merge bits of data into unknown bits of an omega.]
let (supply-missing-bits w)
    if atom w nil
    cons if = X car w
            read-bit
            car w
    (supply-missing-bits cdr w)
 
[Examine omegas in list w to see if in any one of them]
[the number of bits that are determined is greater than n.]
[Return false to indicate not found, or what it found.]
let (examine w n)
    if atom w false
[]
[   if < n (number-of-bits-determined car w)  <==== Change n to 1 here so will succeed.]
[]
    if < 1 (number-of-bits-determined car w)
       car w
       (examine cdr w n)
 
                              []
[Main Loop - t is time limit, fas is bits of formal axiomatic system read so far.]
let (loop t fas)              [Run formal axiomatic system again.]
 let v debug try debug t 'eval read-exp debug fas
 []
 [Look for theorem which determines more than]
 [   (c + # of bits read + size of this prefix)]
 [bits of Omega.  Here c = 9488 is the constant in the inequality]
 [   H(Omega_n) > n - c]
 [(see omega3.l and omega3.r).]
 []
 let s (examine caddr v + 9488 debug + length fas 6912)
 if s (supply-missing-bits s) [Found it! Merge in undetermined bits, output result, and halt. Contradiction!]
 if = car v success  failure  [Surprise, formal system halts, so we do too.]
 if = cadr v out-of-data  (loop t append fas cons read-bit nil)
                              [Read another bit of the formal axiomatic system.]
 if = cadr v out-of-time  (loop + t 1 fas)
                              [Increase time limit.]
 unexpected-condition         [This should never happen.]
                              []
(loop 0 nil)    [Initially, 0 time limit and no bits of formal axiomatic system read.]
 
) [end of prefix, start of formal axiomatic system]
 
[Toy formal system with only one theorem.]
bits 'display '(1 X 0)
 
) [end of prefix and formal axiomatic system]
 
'(1) [Missing bit of Omega that is needed.]

[ --- Self-Referential Unprovability (unknowable/godel.l) --- ]
[[[[[

 A LISP expression that asserts that it itself is unprovable!

 Let g(x): x -> (is-unprovable (value-of (('x)('x))))

 Then (is-unprovable (value-of (('g)('g))))
 asserts that it itself is not a theorem!

]]]]]

define (g x) 
   let (L x y) cons x cons y nil [Makes x and y into list.]
   (L is-unprovable (L value-of (L (L "' x) (L "' x))))

[Here we try g:]

(g x)

[
 Here we calculate the LISP expression 
 that asserts its own unprovability: 
]

(g g)

[Here we extract the part that it uses to name itself:]

cadr cadr (g g)

[Here we evaluate the name to get back the entire expression:] 

eval cadr cadr (g g)

[Here we check that it worked:]

= (g g) eval cadr cadr (g g)

[ --- Unsolvability of the Halting Problem (unknowable/turing.l) --- ]
[[[[[

 Proof that the halting problem is unsolvable by using
 it to construct a LISP expression that halts iff it doesn't.

]]]]]

define (turing x) 
[Insert supposed halting algorithm here.]
let (halts? S-exp) false [<=============]
[Form ('x)]
let y [be] cons "' cons x nil [in]
[Form (('x)('x))]
let z [be] display cons y cons y nil [in]
[If (('x)('x)) has a value, then loop forever, otherwise halt]
if (halts? z) [then] eval z [loop forever]
              [else] nil [halt]

[
 (turing turing) decides whether it itself has a value, 
 then does the opposite!

 Here we suppose it doesn't have a value, 
 so it turns out that it does:
]

(turing turing)

define (turing x) 
[Insert supposed halting algorithm here.]
let (halts? S-exp) true [<==============]
[Form ('x)]
let y [be] cons "' cons x nil [in]
[Form (('x)('x))]
let z [be] [[[[display]]]] cons y cons y nil [in]
[If (('x)('x)) has a value, then loop forever, otherwise halt]
if (halts? z) [then] eval z [loop forever]
              [else] nil [halt]

[
 And here we suppose it does have a value, 
 so it turns out that it doesn't.

 It loops forever evaluating itself again and again!
]

(turing turing) 

[ --- Base Godel Proof (lm/godel.l) --- ]
[[[
    Show that a formal system of lisp complexity
    H_lisp (FAS) = N cannot enable us to exhibit
    an elegant S-expression of size greater than N + 410.
    An elegant lisp expression is one with the property
    that no smaller S-expression has the same value.
    Setting: formal axiomatic system is never-ending
    lisp expression that displays elegant S-expressions.
]]]
 
[Here is the key expression.]
 
define expression
 
let (examine x)
    if atom x  false
    if < n size car x  car x
    (examine cdr x)
 
let fas 'display ^ 10 430 [insert FAS here preceeded by ']
 
let n + 410 size fas
 
let t 0
 
let (loop)
  let v try t fas nil
  let s (examine caddr v)
  if s eval s
  if = success car v failure
  let t + t 1
  (loop)
 
(loop)
[Size expression.]
size expression
[Run expression & show that it knows its own size
 and can find something bigger than it is.]
eval expression
[Here it fails to find anything bigger than it is.]
 
let (examine x)
    if atom x  false
    if < n size car x  car x
    (examine cdr x)
 
let fas 'display ^ 10 429 [insert FAS here preceeded by ']
 
let n + 410 size fas
 
let t 0
 
let (loop)
  let v try t fas nil
  let s (examine caddr v)
  if s eval s
  if = success car v failure
  let t + t 1
  (loop)
 
(loop)

[ --- Base Complexity Limits (lm/godel2.l) --- ]
[[[
 Show that a formal system of complexity N
 can't prove that a specific object has
 complexity > N + 4872.
 Formal system is a never halting lisp expression
 that output pairs (lisp object, lower bound
 on its complexity).  E.g., (x 4) means
 that x has complexity H(x) greater than or equal to 4.
]]]
 
[Here is the prefix.]
 
define pi
 
let (examine pairs)
    if atom pairs false
    if < n cadr car pairs
       car pairs
       (examine cdr pairs)
 
let t 0
 
let fas nil
 
let (loop)
  let v try t 'eval read-exp fas
  let n + 4872 length fas
  let p (examine caddr v)
  if p car p
  if = car v success failure
  if = cadr v out-of-data
     let fas append fas cons read-bit nil
     (loop)
  if = cadr v out-of-time
     let t + t 1
     (loop)
  unexpected-condition
 
(loop)
[Size pi.]
length bits pi
[Size pi + fas.]
length
append bits pi
       bits 'display '(xyz 9999)
[Here pi finds something suitable.]
 
cadr try no-time-limit 'eval read-exp
append bits pi
       bits 'display '(xyz 5073)
[Here pi doesn't find anything suitable.]
 
cadr try no-time-limit 'eval read-exp
append bits pi
       bits 'display '(xyz 5072)

[ --- Base Omega Determination Limits (lm/godel3.l) --- ]
[[[
 Show that a formal system of complexity N
 can't determine more than N + 8000 + 7328
 = N + 15328 bits of Omega.
 Formal system is a never halting lisp expression
 that outputs lists of the form (1 0 X 0 X X X X 1 0).
 This stands for the fractional part of Omega,
 and means that these 0,1 bits of Omega are known.
 X stands for an unknown bit.
]]]
 
[Here is the prefix.]
 
define pi
 
let (number-of-bits-determined w)
    if atom w 0
    + (number-of-bits-determined cdr w)
      if = X car w
         0
         1
 
let (supply-missing-bits w)
    if atom w nil
    cons if = X car w
            read-bit
            car w
    (supply-missing-bits cdr w)
 
let (examine w)
    if atom w false
   [if < n (number-of-bits-determined car w)]
   [   Change n to 1 here so will succeed.  ]
    if < 1 (number-of-bits-determined car w)
       car w
       (examine cdr w)
 
let t 0
 
let fas nil
 
let (loop)
  let v try t 'eval read-exp fas
  let n + 8000 + 7328 length fas
  let w (examine caddr v)
  if w (supply-missing-bits w)
  if = car v success failure
  if = cadr v out-of-data
     let fas append fas cons read-bit nil
     (loop)
  if = cadr v out-of-time
     let t + t 1
     (loop)
  unexpected-condition
 
(loop)
[Size pi.]
length bits pi
[Run pi.]
 
cadr try no-time-limit 'eval read-exp
append bits pi
append [Toy formal system with only one theorem.]
       bits 'display '(1 X 0)
       [Missing bit of omega that is needed.]
       '(1)
