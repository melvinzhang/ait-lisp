[[[[[ UNIVERSAL TURING MACHINES & COMPLEXITY FOUNDATIONS ]]]]]

[ --- Basic UTM and Primitives (lm/xutm.l) --- ]
[utm.l]
 
[First steps with my new construction for]
[a self-delimiting universal Turing machine.]
[We show that]
[   H(x,y) <= H(x) + H(y) + c]
[and determine c.]
[Consider a bit string x of length |x|.]
[We also show that]
[   H(x) <= 2|x| + c]
[and that]
[   H(x) <= |x| + H(the binary string for |x|) + c]
[and determine both these c's.]
 
[First demo the new lisp primitive functions.]
 
append '(1 2 3 4 5 6 7 8 9 0) '(a b c d e f g h i)
read-bit
try 0 'read-bit nil
try 0 'read-bit '(1)
try 0 'read-bit '(0)
try 0 'read-bit '(x)
try 0 'cons cons read-bit nil cons cons read-bit nil nil '(1 0)
try 0 'cons cons display read-bit nil cons cons display read-bit nil nil '(1 0)
try 0 'cons cons display read-bit nil cons cons display read-bit nil cons cons display read-bit nil nil
      '(1 0)
try 0 'read-exp display bits a
try 0 'read-exp display bits b
try 0 'read-exp display bits c
try 0 'read-exp display bits d
try 0 'read-exp display bits e
try 0 'read-exp bits '(aa bb cc dd ee)
try 0 'read-exp bits '(12 (3 4) 56)
try 0 'cons read-exp cons read-exp nil
      append bits '(abc def) bits '(ghi jkl)
[]
[Here is the self-delimiting universal Turing machine!]
[(with slightly funny handling of out-of-tape condition)]
[]
define (U p) cadr try no-time-limit 'eval read-exp p
[]
[The length of this bit string is the]
[constant c in H(x) <= 2|x| + 2 + c.]
[]
length bits '
let (loop) let x read-bit
           let y read-bit
           if = x y
              cons x (loop)
              nil
(loop)
(U
 append
   bits
   'let (loop) let x read-bit let y read-bit if = x y cons x (loop) nil
    (loop)
 
   '(0 0 1 1 0 0 1 1 0 1)
)
(U
 append
   bits
   'let (loop) let x read-bit let y read-bit if = x y cons x (loop) nil
    (loop)
 
   '(0 0 1 1 0 0 1 1 0 0)
)
[]
[The length of this bit string is the]
[constant c in H(x,y) <= H(x) + H(y) + c.]
[]
length bits '
cons eval read-exp
cons eval read-exp
     nil
(U
 append
   bits 'cons eval read-exp cons eval read-exp nil
 append
   bits 'let (f) let x read-bit let y read-bit if = x y cons x (f) nil (f)
 append
   '(0 0 1 1 0 0 1 1 0 1)
 append
   bits 'let (f) let x read-bit let y read-bit if = x y cons x (f) nil (f)
 
   '(1 1 0 0 1 1 0 0 0 1)
)
[]
[The length of this bit string is the]
[constant c in H(x) <= |x| + H(|x|) + c]
[]
length bits '
let (loop k)
   if = 0 k nil
   cons read-bit (loop - k 1)
(loop debug base2-to-10 eval debug read-exp)
(U
 append
   bits '
   let (loop k) if = 0 k nil cons read-bit (loop - k 1)
   (loop debug base2-to-10 eval debug read-exp)
 append
  bits ''(1 0 0 0) [Arbitrary program for U to compute number of bits.]
 
   '(0 0 0 0  0 0 0 1) [That many bits of data.]
)

[ --- Relative & Conditional Complexity (ait/utm2.l) --- ]
[[[
 RELATIVE COMPLEXITY!
 Additional steps in my new construction for
 a self-delimiting universal Turing machine.

 We show that

    H(beta) <= n + H(n) + c for n-bit beta 
                                 
    H(x,y) <= H(x) + H(y) + c
      
    H(H(x)|x) <= c
                      
    H(x,y) <= H(x) + H(y|x) + c
]]]
 
[
 Here is the self-delimiting universal Turing machine
 with NO free data.  P is the program.
 [Run-utm-on p expands to this.]
]
define (U p)
   cadr try no-time-limit 'eval read-exp p
[Here is the version of U with one piece of free data:]

define (U2 p q) [q is a program for U for the free data]
   cadr try no-time-limit 
   display cons 'read-exp [run ((read-exp) (' q))]
           cons cons "' 
                cons q 
                nil 
           nil 
   p
[Here's the version given two things, not one:]

define (U3 p q r) [q, r are programs for U for the free data]
   cadr try no-time-limit 
   display cons 'read-exp [run ((read-exp) (' q) (' r))]
           cons cons "' 
                cons q 
                nil 
           cons cons "' 
                cons r 
                nil 
           nil 
   p
[
   Consider an n-bit string beta.
   We show that H(beta) <= n + H(n) + 912.
]
define pi
   let (loop k)
      if = k 0 nil
      cons read-bit (loop - k 1)
   (loop eval read-exp)
[Size it.]
length bits pi
[Use it.]
(U
   append bits pi   
   append bits 12
          '(0 0 1 1 1 1 1 1 0 0 0 1)
)
[
   Proof that H(x,y) <= H(x) + H(y) + 432.
]
define rho
   cons eval read-exp cons eval read-exp nil
[Size it.]
length bits rho
[Use it.]
(U
   append bits rho
   append bits pi
   append bits 5
   append '(1 1 1 1 1)
   append bits pi
   append bits 9
          '(0 0 0 0 0 0 0 0 0)
)
[
   Proof that H(H(x)|x) <= 208.
]
define (alpha x*)     [x* = minimum-size program for x]
   length x*          [get H(x) from x*]
[Size it.]
length bits alpha
[Use it.]

(U2 
 
[This is the program to calculate H(x):]

bits alpha  

[This is the program x* for x,]
[supposedly smallest possible:]

bits' + 1 1   

)
[Check size of program is correct]
* 8 + 1 display size display '+ 1 1
[
   Proof that H(x,y) <= H(x) + H(y|x) + 2872.

   The 2872-bit prefix gamma proves this.

   Gamma does the job, but it's slow.
   So below we will present delta, which is a greatly
   sped up version of gamma.  The speed up is
   achieved by introducing a new primitive function
   to do the job.  The was-read mechanism used below
   is much faster than our technique here using try
   to get the bits of the program p = x* as we run it.
]

define gamma

   [read program p bit by bit until we get it all]

   let (loop p)
      if = success car try no-time-limit 'eval read-exp p
      [then] p 
      [else] (loop append p cons read-bit nil)

   let x* (loop nil)         [get x* = program for x]
   let x run-utm-on x*       [get x from x*]
   let y                     [get y from x* by running]
       eval cons 'read-exp   [((read-exp) (' x*))]
            cons cons "' 
                 cons x*
                      nil 
                 nil 

   [form the pair x, y]
   cons x cons y nil
[Size it.]
length bits gamma
[Use it.]

run-utm-on

[get pair x, y by combining                   ]
[a program for x and a program to get y from x]

append 

   bits gamma

append

   [x* = program to calculate x = 2]
   [[Supposedly x* is smallest possible,]] 
   [[but this works for ANY x* for x.]]

   bits' + 1 1 

   [program to calculate y = x+1 from x*]

   bits' lambda(x*) + 1 run-utm-on x*
[
   This technique for getting a program as well as its output
   by inching along using try is slow.

   Now let's speed up gamma by using bits to get the binary
   representation of x*.
   With it we will prove that H(x,y) <= H(x) + H(y|x) + 1176.
]
define delta
   let x* read-exp           [get sexp of x*]
   let y* read-exp           [get sexp of y*]
   let x  eval x*            [calculate x from x*]
   let y  (y* bits x*)       [calculate y from y* and bits of x*]
   cons x cons y nil
[Size it.]
length bits delta
[Use it.]

run-utm-on

[get pair x, y by combining                   ]
[a program for x and a program to get y from x]

append 

   bits delta

append

   [x* = program to calculate x = 2]
   [[Supposedly x* is smallest possible,]] 
   [[but this works for ANY x* for x.]]

   bits' + 1 1

   [program to calculate y = x+1 from x*]

   bits' lambda(x*) + 1 run-utm-on x*

[ --- Fundamental Decomposition Theorem (ait/decomp.l) --- ]
[[[[[
   FUNDAMENTAL DECOMPOSITION
   We prove here that 
      H(y|x) <= H_C(x,y) - H(x) + c
]]]]]

define (all-together x*)

let c debug 100 [constant to satisfy Kraft (see lemma)]

let x debug run-utm-on debug x*

let H-of-x debug length x*

[programs we've discovered that calculate pairs 
 starting with x]
let programs nil

let (stage n)
    [generate requirements for all new programs we've
     discovered that produce (x y) pairs]
    let programs 
        (add-to-set debug (halts? nil debug n) programs) 
    (stage + n 1)

[at stage n = 0, 1, 2, 3, ...]
[look at all programs with <=n bits that halt within time n]
[returns list of all of them that produce pairs (x y)]
let (halts? p bits-left)
   let v try n C p [C is eval read-exp if C = U]
   if = success car v (look-at cadr v)
   if = 0 bits-left nil
   append (halts? append p cons 0 nil - bits-left 1)
          (halts? append p cons 1 nil - bits-left 1)

[returns (p) if C(p) = (x y), otherwise ()]
let (look-at v)
   if (and (is-pair v) 
            = x car v ) cons p nil
      nil

[logical "and"]
let (and p q)
   if p q false

[is x a pair?]
let (is-pair? x)
   if atom x         false
   if atom cdr x     false
   if atom cdr cdr x true
                     false

[is an element in a set?]
let (is-in-set? element set)
   if atom set          false
   if = element car set true
   (is-in-set? element cdr set)

[forms set union avoiding duplicates, 
 and makes requirement for each new find]
let (add-to-set new old)
   if  atom new  old 
   let first-new car new
   let rest-new  cdr new
   if (is-in-set? first-new old) (add-to-set rest-new old)
   (do (make-requirement first-new)
       cons first-new (add-to-set rest-new old)
   )
       
[first argument discarded, done for side-effect only!]
let (do x y) y

[given new p such that C(p) = (x y), 
 we produce the requirement for C_x
 that there be a program for y that is |p|-H(x)+c bits long]
let (make-requirement p)
   display cons cadr cadr try no-time-limit C p 
           cons - + c length p H-of-x
                nil

let C ' [here eval read-exp gives U]
[test case special-purpose computer C here in place of U:] 
[C(00100001) with x-1 and y-1 0's gives pair (x xy)]
[loop function gives number of bits up to next 1 bit]
   let (loop n)
      if = 1 read-bit n
      (loop + n 1)
   let x (loop 1)
   let y (loop 1)
   cons x cons * x y nil

[HERE GOES!]
(stage 0)

define x* 3
length bits x* 

[give all-together x*]
try 60 cons cons "'
            cons all-together 
            nil                      
       cons cons "' 
            cons bits x* 
            nil 
       nil 
    nil

define x* 4
length bits x* 

[give all-together x*]
try 60 cons cons "'
            cons all-together 
            nil                      
       cons cons "' 
            cons bits x* 
            nil 
       nil 
    nil

[ --- Complexity Lemma (ait/lemma.l) --- ]
[[[[[
   Lemma for 
      H(y|x) <= H(x,y) - H(x) + c

   We show that 
      H(x) <= -log_2 Sum_y P((x y)) + c 
 
   Proof: From U construct U' such that
      if U(p) = (x y), then U'(p) = x.

   Then apply the previous chapter to get
      H(x) <= -log_2 P'(x) + c  
           <= -log_2 Sum_y P((x y)) + c 
]]]]]

define U-prime

let (is-pair? x)
   if atom x         false
   if atom cdr x     false
   if atom cdr cdr x true
                     false

[run original program for U]

let v eval read-exp 

[and if is a pair, return first element]

if (is-pair? v) car v 

[otherwise loop forever]

   let (loop) [be] (loop) [in] 
      (loop)

[Test it!]

run-utm-on bits' xyz
run-utm-on bits' cons a nil
run-utm-on bits' cons a cons b nil
run-utm-on bits' cons a cons b cons c nil

cadr try 99 U-prime bits' xyz
cadr try 99 U-prime bits' cons a nil
cadr try 99 U-prime bits' cons a cons b nil
cadr try 99 U-prime bits' cons a cons b cons c nil

[ --- UTM Simulation from Enumeration (ait/exec.l) --- ]
[[[[[
   Given an expr to enumerate (program output) pairs,
   we simulate the Turing machine defined this way.
   We assume this r.e. set of programs is prefix free,
   i.e., no extension of a valid program is a valid
   program.  If so, we will carry out this simulation
   in a self-delimiting way, i.e., we won't read any
   unnecessary bits of the program.
]]]]]

define pi

[this is the prefix to put in front of the expr to
enumerate the infinite set of (program output) pairs]

    [graph is an unending expression for (p o) pairs]
    let graph read-exp 

    [program read so far; initialize to empty bit string]
    let p nil 

    let (look-for p [in] pairs)
       if atom pairs false
       [(add new macro caar -> car car to interpreter?)]
       if = p car car pairs [does first pair start with p?]
          car pairs   [if so, return first pair]
          [otherwise, keep looking]
          (look-for p [in] cdr pairs)

    let (look-for-extension-of p [in] pairs)
       if atom pairs false
       if (is-prefix? p car car pairs)
          true
          (look-for-extension-of p [in] cdr pairs)

    let (is-prefix? p q) [is p a prefix of q?]
       if atom p true
       if atom q false
       if = car p car q
          (is-prefix? cdr p cdr q)
          false

    let (loop t)
       [run for time t expr to generate (program output) pairs]
       [pairs are displayed by graph]
       let pairs debug caddr try debug t graph nil   
       let found-it? (look-for p pairs) [found pair with program p?]
       if found-it? cadr found-it? [if so, we have output for p!]
       [(if found-it? isn't false, then it's considered true)]
       [is an extension of p in there?]
       if (look-for-extension-of p [in] pairs) 
                  [if so, read another bit of p]
           [then] let p debug append p cons read-bit nil
                     (loop + t 1) [and generate more pairs]
                  [don't read more of p, just generate more pairs]
           [else] (loop + t 1) 

    [initialize time t to 0]
    (loop 0)

[graph = (1 0) (01 1) (001 2) (0001 3) (00001 4) etc.]
define graph 
    let (loop p n)
  [do!] cons display cons p cons n nil
             (loop  cons 0 p  + 1 n)
    (loop '(1) 0)

[test it!]

try 10 graph nil

run-utm-on

append

     bits pi

append

     bits graph

     '(0 0 0 1)

[ --- Kraft Inequality Criterion (ait/kraft.l) --- ]
[[[[[
   KRAFT INEQUALITY CRITERION FOR CONSTRUCTING COMPUTERS
   Take as input requirement pairs (output, size of program)
   and produce as output assignment pairs (program, output).
 
   We assume that the requirements are consistent.  
   I.e. the sum of 1/2 raised to each size is <= unity. 
   Then we can produce a set of assignments that meets
   the requirements and is prefex free, i.e. no extension
   of a valid program is a valid program.
  
   The basic data structure in this program is the free space pool.
   That's a list of prefixes all of whose extensions (by zero 
   or more bits) are unassigned programs.  Initially this is the 
   list consisting of the empty string because everything is free.

   The algorithm consists of assigning that program that meets
   each requirement that is available and that comes first in
   lexicographic order (0 before 1).

   The free space pool is kept in lexicographic order, to facilitate
   searching.  So the algorithm is to look for the first prefix in
   the pool that is <= the requested size in each requirement.

   If it has exactly the requested size, then that prefix is the
   program assigned to the output in the requirement.  If not,
   the prefix must be smaller than the requirement, and represents
   a piece of free storage that is a power of two larger than needed.
   So as program we assign the prefix extended by sufficiently many
   0's to reach the requested size, and then the prefix is replaced
   in the free space pool by prefix00001, prefix0001, prefix001,
   prefix01, prefix1, for all sizes up to the assigned size.
   This will always work if the Kraft inequality is satisfied.
   
   If this algorithm is given the requirements  
      (0 1) (1 2)  (2 3)   (3 4)...
   (i.e., a 1-bit p for 0, a 2-bit p for 1, a 3-bit p for 2, etc.)
   it will produce the assignments  
      (0 0) (10 1) (110 2) (1110 3)...  
   (i.e., p = 0 yields 0, p = 10 yields 1, p = 110 yields 2, etc.)
   In this case the free storage pool will always consist of a 
   single piece.

   Key fact: if you follow this first-fit algorithm, the free space
   will appear in blocks in the unit interval whose sizes are all
   distinct powers of two, and in order of increasing size.  So
   if an allocation cannot be made, the piece requested must be
   larger (at least twice as large) as the last & largest piece.
   But the total free storage is less than twice the size of the
   last & largest free piece, so allocating this would have violated
   the Kraft inequality.

   To actually run these programs, we have to feed the output of
   this program kraft.l into the previous one, exec.l.
   So there will in fact be an additional prefix in front of the
   assigned programs to tell U how to do kraft.l and how to do exec.l.
   
   Kraft is written as a function that is applied to a finite list
   of requirements and produces the corresponding finite list of
   assignments.  Exec.l will use try to run the requirement generator
   for more and more time to produce longer and longer lists of
   assignments.   It will then use the Kraft function to transform 
   these into longer and longer lists of assignments, which it will 
   use to actually run individual programs by reading them bit by 
   bit as required. The Kraft function has the property that applying 
   it to a longer list of requirements just produces a longer list 
   of assignments.  I.e., it's monotone, it never changes its mind. 
]]]]]

[used to assign a program to an output]

define (extend-with-0s bit-string [to] given-length) 
   if = length bit-string given-length  [then]
      bit-string  [else]
   append (extend-with-0s bit-string [to] - given-length 1) 
          cons 0 nil
[test it]
 
(extend-with-0s '(1 1 1) [to] 6)
(extend-with-0s '(1 1 1) [to] 5)
(extend-with-0s '(1 1 1) [to] 4)
(extend-with-0s '(1 1 1) [to] 3)
[used to subtract storage from a piece of free storage]

define (remove-piece free-prefix size-of-program)
   if = size-of-program length free-prefix
       nil  [then no storage left, else] 
   cons append (extend-with-0s free-prefix [to] - size-of-program 1) 
               cons 1 nil
        (remove-piece free-prefix - size-of-program 1)
[test it]

(remove-piece '(1 1 1) 6)
(remove-piece '(1 1 1) 5)
(remove-piece '(1 1 1) 4)
(remove-piece '(1 1 1) 3)
[ 
   Make-assignments uses debug to show us the 
   free-space-pool after making each assignment.
   If an assignment cannot be made because 
   there is not enough storage, we just skip it.
]
define (make-assignments free-space-pool requirements)

   let free-space-pool   debug free-space-pool   
                         [Done just to show pool!]

   if  atom requirements nil  [no requirements => no assignments]
                              [If so, we're finished!]

   let requirement       car  requirements
   let requirements      cdr  requirements
   let output-of-program car  requirement
   let size-of-program   cadr requirement
   let already-scanned   nil
   let not-yet-scanned   free-space-pool

   let (loop-thru-free-space-pool) [DEFINE IT!]

       if atom not-yet-scanned [cannot make this assignment!]
          [indicate problem and go to next requirement]
          cons not-enough-storage! 
               (make-assignments free-space-pool requirements)  

       let free-prefix      car not-yet-scanned
       let not-yet-scanned  cdr not-yet-scanned
       if < size-of-program length free-prefix

          [doesn't fit --- continue scanning]
          let already-scanned 
              append already-scanned 
                     cons free-prefix nil
          (loop-thru-free-space-pool)

       [fits! --- make assignment]
       [add to list of rest of assignments]
       let free-space-pool 
           append already-scanned 
           append (remove-piece free-prefix size-of-program)
                  not-yet-scanned

       let assignment  
           [make assignment - add to list of rest of assignments]
           [found free piece where it fits!] 
           [extend with zeros to correct size]
           cons (extend-with-0s free-prefix [to] size-of-program) 
           cons output-of-program 
                nil

       [return full list of assignments]
       cons assignment
            (make-assignments free-space-pool requirements)  

   [NOW DO IT!]
   (loop-thru-free-space-pool)
[put it all together]

define (kraft requirements)

   let free-space-pool '(()) [everything free]
   
   (make-assignments free-space-pool requirements)
[TEST KRAFT!]

(kraft '((x 0) (y 1))) 
(kraft '((a 1) (b 0) (c 1))) 
(kraft '((x 1) (y 2))) 
(kraft '((a 1) (b 2) (c 3) (d 4) (e 5))) 
(kraft '((e 5) (d 4) (c 3) (b 2) (a 1))) 
(kraft '((e 5) (c 3) (d 4) (a 1) (b 2))) 

[ --- Occam's Razor Concentration (ait/occam.l) --- ]
[[[[[
   Occam's razor---Concentration process.  
   From computer C construct C' such that 
   if P_C(x) >= 1/2^k, then 
   then C' has a k+1 bit program for x.
   Hence H(x) <= -log_2 P_C(x) + c
   where c depends only on C, not on x.
]]]]]

define all-together

[this is used to avoid duplicate requirements for C']
let previous-requirements nil

[test case special-purpose computer C:]
[ignores odd bits, multiplies by ten until hits a 1]
[this C has many programs that do the same job!]
[[to put U here instead, let C be 'eval read-exp]]
let C '
   let (loop n) 
      let ignore-it [be] read-bit [skip bit]
      if = 1 read-bit [then return] n
         [else] (loop * 10 n)
   (loop 10)

[stage n = 0, 1, 2, ... of overall concentration process]
[look at all n-bit programs for C, run them for time n]
[merge (output,multiplicity) pairs, emit requirements for C']
let (stage n)
   let previous-requirements 
      (make-requirements debug (how-many? nil debug n))
   (stage + n 1)

[produce (output,multiplicity) pairs] 
[by running all n-bit programs on C for time n]
let (how-many? p n)
   if = n length p

      [run program p for time n]
      let v try n [U => 'eval read-exp] C p
      if = success car v

          [program ran to completion]
          [indicate that it produces] 
          [its output with multiplicity one]
          cons cons cadr v cons 1 nil
               nil                   

          [otherwise program failed]
          nil 
          [empty list of (output,multiplicity) pairs]                   

      [otherwise use recursion to combine multiplicities]
      (merge (how-many? cons 0 p n)
             (how-many? cons 1 p n)
      )

[add one (output,multiplicity) pair to a list of such pairs]
let (merge1 pair list)
   if  atom list     cons pair nil
   let first-in-list car  list
   let rest-of-list  cdr  list
   let output        car  pair
   let multiplicity  cadr pair
   let output2       car  first-in-list
   let multiplicity2 cadr first-in-list
   if = output output2
      [= -> combine multiplicities]
      cons cons output cons + multiplicity multiplicity2 nil
           rest-of-list
      [!= -> don't combine multiplicities]
      cons first-in-list 
           (merge1 pair rest-of-list)

[combine two lists of (output,multiplicity) pairs]
let (merge list list2)
   if atom list list2
   (merge1 car list (merge cdr list list2))

[exponent in highest power of 2 <= n, n != 0]
let (log2 n)
   let (loop power exponent)
      let new-power    + power power [double it]
      let new-exponent + 1 exponent  [add 1 to it]
      if > new-power n [then return] exponent
         [else] (loop new-power new-exponent)
   (loop [initial power of two] 1 [initial exponent of 2] 0)

let (make-requirements list-of-pairs)
   if  atom list-of-pairs  previous-requirements
   let first-pair     car  list-of-pairs
   let list-of-pairs  cdr  list-of-pairs
   let output         car  first-pair
   let multiplicity   cadr first-pair
   let kraft-requirement 
       cons output cons - + n 1 (log2 multiplicity) nil
   let previous-requirements (make-requirements list-of-pairs)
   [keep only first appearance of requirement]
   if (is-in? kraft-requirement previous-requirements)
      previous-requirements
   cons debug display kraft-requirement previous-requirements 

let (is-in? x list) [is x in list?]
   if atom list     false
   if = x car list  true
   (is-in? x cdr list)

[HERE GOES!]
(stage 0)

try 60 all-together nil

[ --- Base UTM (lm/utm.l) --- ]
[[[
 First steps with my new construction for
 a self-delimiting universal Turing machine.
 We show that
    H(x,y) <= H(x) + H(y) + c
 and determine c.
 Consider a bit string x of length |x|.
 We also show that
    H(x) <= 2|x| + c
 and that
    H(x) <= |x| + H(the binary string for |x|) + c
 and determine both these c's.
]]]
 
[
 Here is the self-delimiting universal Turing machine!
]
define (U p) cadr try no-time-limit 'eval read-exp p
(U bits 'cons x cons y cons z nil)
(U append bits 'cons a debug read-exp
          bits '(b c d)
)
[
 The length of alpha in bits is the
 constant c in H(x) <= 2|x| + 2 + c.
]
define alpha
let (loop) let x read-bit
           let y read-bit
           if = x y
              cons x (loop)
              nil
(loop)
length bits alpha
(U
 append
   bits alpha
   '(0 0 1 1 0 0 1 1 0 1)
)
(U
 append
   bits alpha
   '(0 0 1 1 0 0 1 1 0 0)
)
[
 The length of beta in bits is the
 constant c in H(x,y) <= H(x) + H(y) + c.
]
define beta
cons eval read-exp
cons eval read-exp
     nil
length bits beta
(U
 append
   bits  beta
 append
   bits 'cons a cons b cons c nil
   bits 'cons x cons y cons z nil
)
(U
 append
   bits beta
 append
   append bits alpha '(0 0 1 1 0 0 1 1 0 1)
   append bits alpha '(1 1 0 0 1 1 0 0 1 0)
)
[
 The length of gamma in bits is the
 constant c in H(x) <= |x| + H(|x|) + c
]
define gamma
let (loop k)
   if = 0 k nil
   cons read-bit (loop - k 1)
(loop base2-to-10 eval read-exp)
length bits gamma
(U
 append
   bits gamma
 append
   [Arbitrary program for U to compute number of bits]
   bits' '(1 0 0 0)
   [That many bits of data]
   '(0 0 0 0  0 0 0 1)
)
