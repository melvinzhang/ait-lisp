[[[[[ HALTING PROBABILITY (OMEGA) ]]]]]

[ --- Omega Calculation: Basic (lm/xomega.l) --- ]
[omega.l]
 
[Omega in the limit from below!]
 
[Generate all bit strings of length k.]
define (all-bit-strings-of-size k)
    if = 0 k '(())
    (extend-by-one-bit (all-bit-strings-of-size - k 1))
[Append 0 and 1 to each element of list.]
define (extend-by-one-bit x)
    if atom x nil
    cons append car x '(0)
    cons append car x '(1)
    (extend-by-one-bit cdr x)
(extend-by-one-bit'((a)(b)))
(all-bit-strings-of-size 0)
(all-bit-strings-of-size 1)
(all-bit-strings-of-size 2)
(all-bit-strings-of-size 3)
[Count programs in list p that halt within time t.]
define (count-halt p t)
    if atom p 0
    +
    if = success display car try t 'eval debug read-exp car p
       1 0
    (count-halt cdr p t)
(count-halt cons bits '+ 10 15
            cons bits 'let(f)(f)(f)
                 nil
 99)
(count-halt cons append bits 'read-bit '(1)
            cons append bits 'read-exp '(1)
                 nil
 99)
[The kth lower bound on Omega]
[is the number of k-bit strings that halt on U within time k]
[divided by 2 raised to the power k.]
define (omega k) cons (count-halt (all-bit-strings-of-size k) k)
                 cons /
                 cons ^ 2 k
                      nil
(omega 0)
(omega 1)
(omega 2)
(omega 3)
(omega 8)

[ --- Omega Calculation: Recursive (lm/xomega2.l) --- ]
[omega2.l]
 
[Omega in the limit from below!]
[Version II.]
 
[Count programs with prefix bit string p that halt within time t]
[among all possible extensions by e more bits.]
define (count-halt prefix time bits-left-to-extend)
    if = bits-left-to-extend 0
    if = success display car try time 'eval debug read-exp display prefix
       1 0
    + (count-halt append prefix '(0) time - bits-left-to-extend 1)
      (count-halt append prefix '(1) time - bits-left-to-extend 1)
(count-halt bits 'cons read-bit cons read-bit nil no-time-limit 0)
(count-halt bits 'cons read-bit cons read-bit nil no-time-limit 1)
(count-halt bits 'cons read-bit cons read-bit nil no-time-limit 2)
(count-halt bits 'cons read-bit cons read-bit nil no-time-limit 3)
[The kth lower bound on Omega]
[is the number of k-bit strings that halt on U within time k]
[divided by 2 raised to the power k.]
define (omega k) cons (count-halt nil k k)
                 cons /
                 cons ^ 2 k
                      nil
(omega 0)
(omega 1)
(omega 2)
(omega 3)
(omega 8)

[ --- Omega Calculation: Optimized (lm/omega2vb.l) --- ]
[[[[ Omega in the limit from below! ]]]]
 
define (count-halt prefix bits-left-to-extend)
    let x try t 'eval read-exp prefix
    if = success car x    ^ 2 bits-left-to-extend
    if = out-of-time cadr x    0
    if = bits-left-to-extend 0    0
    + (count-halt append prefix '(0) - bits-left-to-extend 1)
      (count-halt append prefix '(1) - bits-left-to-extend 1)
define (omega t) cons (count-halt nil t)
                 cons /
                 cons ^ 2 t
                      nil
(omega 0)
(omega 1)
(omega 2)
(omega 3)
(omega 8)

[ --- Complexity of Omega (lm/xomega3.l) --- ]
[omega3.l]
 
[Show that]
[   H(Omega_n) > n - 9488.]
[Omega_n is the first n bits of Omega,]
[where we choose]
[   Omega = xxx0111111...]
[instead of]
[   Omega = xxx1000000...]
[if necessary.]
 
[This is an identity function with the size-effect of]
[displaying the length in bits of the binary prefix.]
define (display-length-of-prefix prefix)
    cadr cons display length prefix cons prefix nil
 
cadr try no-time-limit 'eval read-exp [Universal Turing machine U ---]
 
display
[--- followed by its program.]
append [Append prefix and data.]
 
[Code to display size of prefix in bits.]
(display-length-of-prefix bits '
 
[]
[Omega2.l follows.]
[]
 
let (count-halt prefix time bits-left-to-extend)
    if = bits-left-to-extend 0
    if = success car try time 'eval read-exp prefix
       1 0
    + (count-halt append prefix '(0) time - bits-left-to-extend 1)
      (count-halt append prefix '(1) time - bits-left-to-extend 1)
 
let (omega k) cons (count-halt nil k k)
              cons /
              cons ^ 2 k
                   nil
 
[]
[Read and execute from remainder of tape]
[a program to compute an n-bit]
[initial piece of Omega.]
[]
let w debug eval debug read-exp
 
[]
[Convert Omega to ratio of integers,]
[i.e., from a bit string to a rational number.]
[]
let n length w
let w debug cons base2-to-10 w
            cons /
            cons ^ 2 n
                 nil
                                     []
let (loop k)                         [Main Loop ---]
  let x debug (omega debug k)        [Compute the kth lower bound on Omega.]
  if debug (<=rat w x) (big nil k n) [Are the first n bits OK?  If not, bump k.]
     (loop + k 1)                    [If so, form the union of all output of n-bit]
                                     [programs within time k, output it, and halt.]
                                     [All n-bit programs that ever halt halt by time k.]
                                     [Thus this union is bigger than anything of complexity]
                                     [less than or equal to n!]
[                                    ]
[This total output will be bigger than each individual output,]
[and therefore must come from a program with more than n bits.]
[Therefore this program itself must be more than n bits long.]
[I.e., 9488 + H(Omega_n) > n. Q.E.D.]
[]
 
[Compare two rational numbers, i.e., is x= (a / b) <= y= (c / d)?]
let (<=rat x y)
    let a car debug x
    let b caddr x
    let c car debug y
    let d caddr y
    <= * a d * b c
 
[Union of all output of n-bit programs within time k.]
let (big prefix time bits-left-to-add)
 if = 0 bits-left-to-add
 try time 'eval read-exp prefix
 append (big append prefix '(0) time - bits-left-to-add 1)
        (big append prefix '(1) time - bits-left-to-add 1)
 
(loop 0)         [Start main loop running with k = 0.]
 
)  [end of prefix]
 
bits '           [Here is the data: an optimal program to compute n bits of Omega.]
 
'(0 0 0 0  0 0 0 1)       [n = 8! Are these really the first 8 bits of Omega?]

[ --- Base Omega (lm/omega.l) --- ]
[[[[ Omega in the limit from below! ]]]]
 
define (all-bit-strings-of-size k)
    if = 0 k '(())
    (extend-by-one-bit (all-bit-strings-of-size - k 1))
define (extend-by-one-bit x)
    if atom x nil
    cons append car x '(0)
    cons append car x '(1)
    (extend-by-one-bit cdr x)
define (count-halt p)
    if atom p 0
    +
    if = success car try t 'eval read-exp car p
       1 0
    (count-halt cdr p)
define (omega t) cons (count-halt (all-bit-strings-of-size t))
                 cons /
                 cons ^ 2 t
                      nil
(omega 0)
(omega 1)
(omega 2)
(omega 3)
(omega 8)

[ --- Base Omega 2 (lm/omega2.l) --- ]
[[[[ Omega in the limit from below! ]]]]
 
define (count-halt prefix bits-left-to-extend)
    if = bits-left-to-extend 0
    if = success car try t 'eval read-exp prefix
       1 0
    + (count-halt append prefix '(0) - bits-left-to-extend 1)
      (count-halt append prefix '(1) - bits-left-to-extend 1)
define (omega t) cons (count-halt nil t)
                 cons /
                 cons ^ 2 t
                      nil
(omega 0)
(omega 1)
(omega 2)
(omega 3)
(omega 8)

[ --- Base Omega 3 (lm/omega3.l) --- ]
[[[
 Show that
    H(Omega_n) > n - 8000.
 Omega_n is the first n bits of Omega,
 where we choose
    Omega = xxx0111111...
 instead of
    Omega = xxx1000000...
 if necessary.
]]]
 
[Here is the prefix.]
 
define pi
 
let (count-halt prefix bits-left-to-extend)
    if = bits-left-to-extend 0
    if = success car try t 'eval read-exp prefix
       1 0
    + (count-halt append prefix '(0) - bits-left-to-extend 1)
      (count-halt append prefix '(1) - bits-left-to-extend 1)
 
let (omega t) cons (count-halt nil t)
              cons /
              cons ^ 2 t
                   nil
 
let w eval read-exp
 
let n length w
 
let w cons base2-to-10 w
      cons /
      cons ^ 2 n
           nil
 
let (loop t)
  if (<=rat w (omega t))
     (big nil n)
     (loop + t 1)
 
let (<=rat x y)
    <= * car x caddr y * caddr x car y
 
let (big prefix bits-left-to-add)
 if = 0 bits-left-to-add
 cons cadr try t 'eval read-exp prefix
      nil
 append (big append prefix '(0) - bits-left-to-add 1)
        (big append prefix '(1) - bits-left-to-add 1)
 
(loop 0)
[Run pi.]
cadr try no-time-limit 'eval read-exp
append bits pi
       bits '
      [Program to compute first n = 8 bits of Omega]
            '(0 0 0 0  0 0 0 1)
[Size pi.]
length bits pi
