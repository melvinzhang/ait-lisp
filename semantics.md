Constants
=========
() / nil        The empty list.
true            Boolean true.
false           Boolean false.
no-time-limit   Used with 'try' to indicate no step limit.
out-of-time     Returned/Signaled when a 'try' exceeds its step limit.
out-of-data     Returned/Signaled when 'read-bit' or 'read-exp' exhausts the input tape.
success         Indicates successful completion of a 'try' block.
failure         Indicates an error or timeout occurred within a 'try' block.

Comments
========
[...]           Anything enclosed in square brackets is ignored by the reader.

Special Forms & Macros
======================
define symbol exp
define (symbol p1 p2 ...) exp
    Defines a global variable or function.

let symbol exp body
let (symbol p1 p2 ...) exp body
    Binds symbol(s) to value(s) within the scope of 'body'. 
    If a function-like signature is used, it binds the symbol to a lambda.

lambda (p1 p2 ...) exp
    Creates a function.

' exp
    Quote: returns 'exp' without evaluating it.

" exp
    Reads 'exp' as a raw S-expression, bypassing M-expression expansions.

if exp exp-true exp-false
    Conditional execution.

eval exp
    Evaluates 'exp' in a "clean" environment where all symbols (except nil) 
    initially evaluate to themselves.

try max-steps exp input-bits
    Runs 'exp' with a limited number of evaluation steps and an input tape 
    provided by 'input-bits' (a list of 0s and 1s). 
    Returns (success result captured-displays) or (failure reason captured-displays).
    Disables 'display' and captures output instead.

run-utm-on bits
    Macro that expands to: (car (cdr (try no-time-limit '(eval (read-exp)) bits)))
    Essentially executes the Lisp program serialized in the given bit-list.

Primitives
==========
car xs / cdr xs
    Standard list accessors.

cadr xs / caddr xs
    Macros for (car (cdr xs)) and (car (cdr (cdr xs))).

cons x xs
    Standard list constructor.

atom exp
    Returns true if 'exp' is an atom or number, false otherwise.

= exp1 exp2
    Structural equality for lists, atoms, and numbers.

display exp
    Prints 'exp' to stdout. Returns 'exp'.

debug exp
    Prints 'exp' with a "debug" label. Returns 'exp'.

append xs ys
    Appends list 'xs' and 'ys'.

length xs
    Returns the number of elements in list 'xs'.

< n m, > n m, <= n m, >= n m, + n m, * n m, ^ n m, - n m
    Arbitrary-precision arithmetic operations.

base2-to-10 bits
    Converts a list of bits (0s and 1s) to a number.

base10-to-2 n
    Converts a number to a list of bits.

size exp
    Returns the size of 'exp' in characters when printed.

bits exp
    Serializes 'exp' into a list of bits (8 bits per character, ending with a newline).

read-bit
    Reads one bit from the input tape (provided by 'try').

read-exp
    Reads and parses a full S-expression from the input tape (8 bits per character).