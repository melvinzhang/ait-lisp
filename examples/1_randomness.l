[[[[[ RANDOMNESS & EQUIVALENCE OF DEFINITIONS ]]]]]

[ --- Part 1: Solovay vs Chaitin Randomness (ait/chaitin.l) --- ]
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

[in the proof we pick N so that] 
[the total measure Sum_{m >= N} of mu A_m <= 1]
[for example,]
define N 5

define (is-in? x l) [is x in the list l?]
   if atom l    false
   if = x car l true
   (is-in? x cdr l)

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

[to remove duplicates]
define requirements ()

[run it]
(stage 0)

[ --- Part 2: Solovay vs Chaitin Randomness (ait/chaitin2.l) --- ]
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

[Second part: not Ch random ===> not Sol random] 

define (is-in? x l) [is x an element of list l?]
   if atom l     false
   if = x car l  true
   (is-in? x cdr l)

define (union x y) [set-theoretic union of two sets x y]
   if atom x y
   if (is-in? car x y) (union cdr x y)
   cons car x (union cdr x y)

define (is-bit-string? x) [is x a list of 0's and 1's?]
   if = x nil   true
   if atom x    false
   if = 0 car x (is-bit-string? cdr x)
   if = 1 car x (is-bit-string? cdr x)
   false

define C [test computer---real thing is eval read-exp]
   let (loop x y) [xx yy zz 01 ===> xyz]
     if = x y cons x (loop read-bit read-bit)
     nil
   (loop read-bit read-bit)

[
 The hypothesis that
 the real number r is not Chaitin random
 means that there is a K such that
 for infinitely many values of n
   H(r_n) < n + K, 
 where r_n is the first n bits of r.

 For this example, let's suppose that K = 5.
]

define K 5

[
 Our proof depends on the fact that there is a c such that
 the probability that an n-bit string s has
  H(s) < n + K 
 is less than 2^{-H(n) + K + c}.
]

[
 Now let's do stage N of A_n = n-bit strings s with H(s) < |s| + K. 
 At stage N we look at all programs p less than n + K bits in size for time up to N.
]

define (quasi-compressible N n)
   (look-at nil)

[this routine has free parameters N, n, K, C]

define (look-at p) [produces quasi-compressible strings of length n]
   if = length p + n K [p too long?]
      nil
   let v try N C ['eval read-exp] p
   if = success car v
      let w cadr v   
      if (is-bit-string? w)
         if = n length w
            cons w nil
         nil
      nil
   [
    Also works with append below instead of union
    because duplicates are removed later by (process interval).
   ]
   (union (look-at append p cons 0 nil)
          (look-at append p cons 1 nil))

[
 List of intervals in covering so far.
 used to avoid overlapping intervals in covering.

 This is easy to do because here because
 all intervals are the same length.
]
define intervals ()

define (process-all x) [process list of intervals x]
   if atom x  intervals
   let intervals append (process car x) intervals
   (process-all cdr x)

define (process interval) [process individual interval]
   if (is-in? interval intervals) 
      [then don't need to repeat it]
      nil
      [else interval is fine as is]
      cons display interval nil 

[
 Put it all together---Here is cover A_n
 covering all reals r having n-bit prefix r_n 
 with H(r_n) < n + K.

 And we have measure \mu A_n <= 2^{-H(n)+K+c}
 so that Sum_n \mu A_n <= \Omega 2^{K+c} <= 2^{K+c} < infinity .

 Hence a real r which is not strongly Chaitin random
 will be in infinitely many of the A_n, 
 which have convergent total measure,
 and hence will not be Solovay random.
]
define (A n)
   let intervals nil
   let (stage N)
      if = N 7 stop! [to stop test run---remove if real thing]
      let quasi-compressible-strings (quasi-compressible N n)
      let intervals (process-all quasi-compressible-strings) 
      (stage + 1 N)
   [go!!!!!]
   (stage 0)

[n = 2, i.e., quasi-compressible 2-bit strings]
(A 2) 

[ --- Part 3: Martin-Lof vs Chaitin Randomness (ait/martin-lof.l) --- ]
[[[[[
   Show that a real r is Martin-Lof random
   iff it is Chaitin random.

   An effective covering A_k of k is a function
   of k that enumerates bit strings s,
   which are the initial bits of the covered
   reals.  We assume that no s in A_k is a
   proper prefix or extension of another.
   Thus the measure of the cover A_k of k is
   exactly Sum_{s in A_k} of 2^{-|s|},
   where |s| is the length of the bit string s.
]]]]]

[First part: not M-L random ===> not Ch random] 

[We create the following set of requirements] 
[(output, size-of-program)]
[ (s, |s|-n) : s in A_{n^2}, n >= 2 ] 

[Stage k>=0, look at all A_{n^2} n = 2 to 2+k for time k.]
[Then have to combine stage 0, stage 1,...]
[and eliminate duplicates]

[infinite computation that displays strings] 
[in cover A_m with measure mu <= 1/2^m]
define (A m) 
   cdr cons
   [test case, A_m = string of m 1's]
   display base10-to-2 - ^ 2 m 1 
   nil

define (is-in? x l) [is x in the list l?]
   if atom l    false
   if = x car l true
   (is-in? x cdr l)

define (convert-to-requirements cover n) [display requirements]
   if  atom cover requirements [finished?]
   let s          car cover [get first string]
   let cover      cdr cover [get rest of strings]
   let requirement 
       cons s cons - length s n nil [form (s, |s|-n)]
   if (is-in? requirement requirements) [duplicate?]
   [yes] (convert-to-requirements cover n)
   [no]  let requirements cons display requirement requirements
         (convert-to-requirements cover n)

define (stage k)
   if = k 4 stop! [[[stop infinite computation!!!]]]
   let (loop i) [i = 0 to k]
      if  > i k (stage + k 1) [go to next stage]
      let n + 2 i [n = 2 + i]
      let expr cons cons "' cons A nil
                    cons * n n nil
      let cover caddr try k expr nil  [caddr = displays]
      let requirements (convert-to-requirements cover n)
      (loop + i 1) [bump i]
   [initialize i]
   (loop 0)

[to remove duplicates]
define requirements ()

[run it]
(stage 0)

[ --- Part 4: Martin-Lof vs Chaitin Randomness (ait/martin-lof2.l) --- ]
[[[[[
   Show that a real r is Martin-Lof random
   iff it is Chaitin random.

   An effective covering A_k of k is a function
   of k that enumerates bit strings s,
   which are the initial bits of the covered
   reals.  We assume that no s in A_k is a
   proper prefix or extension of another.
   Thus the measure of the cover A_k of k is
   exactly Sum_{s in A_k} of 2^{-|s|},
   where |s| is the length of the bit string s.
]]]]]

[Second part: not Ch random ===> not M-L random] 

define (is-in? x l) [is x an element of list l?]
   if atom l     false
   if = x car l  true
   (is-in? x cdr l)

define (is-prefix-of? x y) [is bit string x a prefix of bit string y?]
   if atom x  true
   if atom y  false
   if = car x car y (is-prefix-of? cdr x cdr y)
   false

define (is-bit-string? x) [is x a list of 0's and 1's?]
   if = x nil   true
   if atom x    false
   if = 0 car x (is-bit-string? cdr x)
   if = 1 car x (is-bit-string? cdr x)
   false

define C [test computer---real thing is eval read-exp]
   let (loop) [doubles all bits up to & including first 1]
     if = 1 read-bit '(1 1)
     cons 0 cons 0 (loop)
   (loop)

[Now let's do stage n of A_k = strings s with H(s) <= |s| - k.] 
[At stage n we look at programs p up to n bits in size for time up to n.]

define (compressible-by-k n k)
   (look-at nil)

[this routine has free parameters n, k, C]

define (look-at p) [produces strings compressible by k within time n]
   let v try n C ['eval read-exp] p
   if = success car v
      let w cadr v   
      if (is-bit-string? w)
         if >= length w + k length p
            cons w nil
         nil
      nil
   [otherwise failure]
   if = n length p nil [stop!]
   append (look-at append p cons 0 nil)
          (look-at append p cons 1 nil)

[list of intervals in covering so far]
[used to avoid overlapping intervals in covering]
define intervals ()

define (process-all x) [process list of intervals x]
   if atom x  intervals
   let intervals append (process car x) intervals
   (process-all cdr x)

define (process interval) [process individual interval]
   if (new-interval-covered-by-previous-one? interval intervals) 
      [then don't need to repeat it]
      nil
   let holes (new-interval-covers-previous-ones interval intervals)
   if atom holes
      [then interval is fine as is]
      cons display interval nil 
   [get max granularity needed]
   let max (max-length holes) 
   [convert everything to same granularity]
   let holes (extend-all holes max)
   [and remove overlap]
   (subtract (extend interval max) holes)

[returns true/false]
define (new-interval-covered-by-previous-one? interval intervals)
   if atom intervals  false
   if (is-prefix-of? car intervals interval)  true
   (new-interval-covered-by-previous-one? interval cdr intervals)

[returns set of previous intervals covered by this one]
define (new-interval-covers-previous-ones interval intervals)
   if atom intervals  nil
   if (is-prefix-of? interval car intervals)
      [then] cons car intervals (new-interval-covers-previous-ones interval cdr intervals)
      [else]                    (new-interval-covers-previous-ones interval cdr intervals)
   
[get maximum length of a list of bit strings]
define (max-length list) 
   if atom list   0
   let len1 length car list
   let len2 (max-length cdr list)
   if > len1 len2   
      [then] len1 
      [else] len2 

[produce set of all extensions of a given bit string to a given length]
[(assumed >= to its current length)]
define (extend bit-string len)
   if = len length bit-string   
      [has correct length; return singleton set]
      cons bit-string nil
   append (extend append bit-string cons 0 nil len)
          (extend append bit-string cons 1 nil len)

[extend all the bit strings in a given list to the same length]
define (extend-all list len)
   if atom list   nil
   append (extend     car list len)
          (extend-all cdr list len)

[subtract set of intervals y from set of intervals x]
define (subtract x y)
   if atom x   nil    
   if (is-in? car x y)
   [then]                          (subtract cdr x y)
   [else] cons debug display car x (subtract cdr x y)

[
 Put it all together---Here is cover A_k
 covering all reals r having any n-bit prefix r_n 
 with H(r_n) <= n - k.
 And we have measure \mu A_k <= 2^{-k+c}.
 Actual proof uses A_{k+c}
 so that measure \mu A_{k+c} <= 2^{-k}.
 Hence a real r with prefixes whose complexity
 dips arbitrarily far below their length will be
 in all the A_k and hence will not be M-L random.
]
define (A k)
   let intervals nil
   let (stage n)
      let compressible-strings (compressible-by-k n k)
      let intervals (process-all compressible-strings) 
      if = n 12 stop! [to stop test run---remove if real thing]
      (stage + 1 n)
   [go!!!!!]
   (stage 0)

[k = compression amount = 8 bits]
(A 8) 

[ --- Part 5: Solovay vs Martin-Lof Randomness (ait/solovay.l) --- ]
[[[[[
   Show that a real r is Solovay random
   iff it is Martin-Lof random.

   An effective covering A_k of k is a function
   of k that enumerates bit strings s,
   which are the initial bits of the covered
   reals.  We assume that no s in A_k is a
   proper prefix or extension of another.
   Thus the measure of the cover A_k of k is
   exactly Sum_{s in A_k} of 2^{-|s|},
   where |s| is the length of the bit string s.
]]]]]

[First part: not M-L random ===> not Solovay random] 

[
This is immediate.  We are given coverings A_k such
that real r is in A_k for all k and the measure of A_k <= 2^{-k}.
It follows immediately that r is in infinitely many of the
A_k and the sum of the measure of A_k summed over all k converges.
Thus r is not Solovay random.
]

[Second part: not Solovay random ===> not M-L random] 

[
Suppose that a real r is in infinitely many of the 
coverings A_n and that Sum_k mu A_n <= 2^c.
Consider B_k defined as the set of all reals that are
in at least 2^{k+c} of the A_n.
Then r is in all of the B_k and the measure of 
B_k is <= 2^{-k}, so r is not Martin-Lof random.

Now let's program this!

Instead, I'll program B_k which is the set of all reals
that are in at least k of the A_n.
The proof then results from considering B_{2^{k+c}} .

The main function has two parameters, the stage n, and
the number of times something has to be repeated to
be taken into account.  At stage n, with number 
of repeats r, we look at A_0 through A_n for time n,
and put into our condensed result cover only subintervals
that are covered at least r times.

The key auxiliary function given n generates A_0 through A_n for time n,
then expands all intervals to the same max length and counts how
many times each is repeated.  Then it is easy to select those that
are covered the requisite number of times.

First step is to run A_0 through A_n for time n and append the results.
Then we get the max length and do a binary tree walk.  We start with
s and see if it's a prefix of at least r things.
If so, s will be in our result, and we backtrack.
If not, if s has max length, we stop recursion.
Otherwise, we look at s0 and at s1.
And we start with s = nil.
This gives our covering at stage n,
then we have to eliminate overlaps to
get our final result.
]

[ 
 Test case: A_n is defined to be the set of
 all natural numbers greater than n,
 where k is represented as k 1's followed by a 0.
 Then measure of A_n is 2^{-n-1}, and
 1=10 is in one of the A_n, 2=110 is in two of them,
 3=1110 is in three of them, etc.

 I.e., 1=10 is only in A_0,
       2=110 is only in A_0 & A_1,
       3=1110 is only in A_0 A_1 & A_2, etc.

 In this case the total measure of the A_n is 
 1/2 + 1/4 + 1/8 + ... = 1.
 For the proof in general, all we know is that
 this total measure converges to a finite sum, not 1.
]
define (A n) [displays infinite set 1^k 0, k > n] 
  let (loop k)
      cons display 
         append base10-to-2 - ^ 2 k 1 [2^k - 1 = k 1's]
            cons 0 nil [followed by a 0 bit]
      (loop + k 1)
  (loop + n 1) 

[now put together in one list stage n of A_0 through A_n]
define (sum n)
   let (loop k sum)
      if > k n sum
      (loop + k 1 
            append caddr try n cons cons "' cons A nil cons k nil nil
                   sum)
   (loop 0 nil)

[
 (count x y) 
 Now count how many times something x is contained in / 
 is an extension of an element of y
]
define (count x y) 
   if atom y 0
   if (is-prefix-of? car y x) + 1 (count x cdr y)
   (count x cdr y)

define (is-prefix-of? x y) [is bit string x a prefix of bit string y?]
   if atom x  true
   if atom y  false
   if = car x car y (is-prefix-of? cdr x cdr y)
   false

[get maximum length of a list of bit strings]
define (max-length list) 
   if atom list   0
   let len1 length car list
   let len2 (max-length cdr list)
   if > len1 len2   
      [then] len1 
      [else] len2 

[
 Now we get what (sum n) covers with multiplicity >= k.
 The measure of the multiplicity k covering will
 be bounded by the finite total measure (here 1) divided by k.
]

define (exceeds-count n k)
   let sum-n (sum n)
   let max-length-sum-n (max-length sum-n)
   (look-at nil)

[
 This routine has free parameters sum-n, max-length-sum-n, k.
 It gets us the MINIMAL multiplicity >= k covering for (sum n)!
]
define (look-at x) [produces strings x covered with multiplicity >= k in (sum n)]
   if = length x max-length-sum-n
      let n (count x sum-n)
      if >= n k cons x nil [found an interval x that is covered >= k times]
                nil  [didn't find an interval x that is covered >= k times]
   [otherwise break x into subintervals]
   let x0 append x cons 0 nil
   let x1 append x cons 1 nil
   let v  append (look-at x0)
                 (look-at x1)
   [consolidate subintervals?]
   if = v cons x0 cons x1 nil [yes!] cons x nil
          [no, leave covering as is] v

[
 Now we put this all together into B_k, which is
 the limit as n goes to infinity of (exceeds-count n k),
 k fixed, n --> infinity.

 I.e., B_k is what A_0, A_1, A_2, ... covers with
 multiplicity >= k.

 Thus the measure of B_k will be bounded by the
 total measure of the A_n (if it exists) divided by k.

 The main problem is to avoid overlaps in B_k,
 which we do using a completely general algorithm.
]

[list of intervals in covering so far]
[used to avoid overlapping intervals in covering]
define intervals ()

define (process-all x) [process list of intervals x]
   if atom x  intervals
   let intervals append (process car x) intervals
   (process-all cdr x)

define (process interval) [process individual interval]
   if (new-interval-covered-by-previous-one? interval intervals) 
      [then don't need to repeat it]
      nil
   let holes (new-interval-covers-previous-ones interval intervals)
   if atom holes
      [then interval is fine as is]
      [output it with display!]
      cons display interval nil 
   [get max granularity needed]
   let max (max-length holes) 
   [convert everything to same granularity]
   let holes (extend-all holes max)
   [and remove overlap]
   [subtract will output residue with display]
   (subtract (extend interval max) holes)

[returns true/false]
define (new-interval-covered-by-previous-one? interval intervals)
   if atom intervals  false
   if (is-prefix-of? car intervals interval)  true
   (new-interval-covered-by-previous-one? interval cdr intervals)

[returns set of previous intervals covered by this one]
define (new-interval-covers-previous-ones interval intervals)
   if atom intervals  nil
   if (is-prefix-of? interval car intervals)
      [then] cons car intervals (new-interval-covers-previous-ones interval cdr intervals)
      [else]                    (new-interval-covers-previous-ones interval cdr intervals)
   
[produce set of all extensions of a given bit string to a given length]
[(assumed >= to its current length)]
define (extend bit-string len)
   if = len length bit-string   
      [has correct length; return singleton set]
      cons bit-string nil
   append (extend append bit-string cons 0 nil len)
          (extend append bit-string cons 1 nil len)

[extend all the bit strings in a given list to the same length]
define (extend-all list len)
   if atom list   nil
   append (extend     car list len)
          (extend-all cdr list len)

[subtract set of intervals y from set of intervals x]
[output residue with display!]
define (subtract x y)
   if atom x   nil    
   if (is-in? car x y)
   [then]                    (subtract cdr x y)
   [else] cons display car x (subtract cdr x y)

define (is-in? x l) [is x an element of list l?]
   if atom l     false
   if = x car l  true
   (is-in? x cdr l)

[
 Put it all together---Here is cover B_k,
 which is what is covered by A_0, A_1, A_2, ...
 with multiplicity >= k, and therefore has
 measure bounded by the total measure of the A_n
 divided by k.
 Supposing that this total measure is <= 2^c
 and considering B_{2^{k+c}}, 
 we see that if a real r is in infinitely many of
 the A_n, then it will be in all of the 
 B_{2^{k+c}}, each of which has measure <= 1/2^k.
 Hence if a real r is not Solovay random,
 it follows that it will not be M-L random.
 Here we write the code for B_k, not for
 B_{2^{k+c}}.
]
define (B k)
   let intervals nil
   let (stage n)
      if = n 6 stop! [to stop test run---remove if real thing]
      let exceed-count (exceeds-count n k)
      let intervals (process-all exceed-count) 
      (stage + 1 n)
   [go!!!!!]
   (stage 0)

[k = multiplicity = repeated/covered 2 or more times in the A_n]
(B 2) 
