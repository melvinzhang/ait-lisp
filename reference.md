Chaitin Lisp: Language Reference
================================

This document provides a formal specification of the Chaitin Lisp dialect.

1. Data Types
-------------
- **Symbols (Atoms)**: Named identifiers. The symbol `nil` represents the empty list and the boolean false.
- **Numbers**: Arbitrary-precision non-negative integers.
- **Pairs (Cons Cells)**: A fundamental structure containing two elements: a `car` and a `cdr`.
- **Lists**: Either `nil` or a pair whose `cdr` is a list. This dialect only supports "proper" lists.

2. The Reader (M-Expressions)
-----------------------------
The reader transforms input text into S-expressions before evaluation. It distinguishes between raw S-expressions and "M-expression" shorthand.

### 2.1 Expansion Rules
If the reader encounters a symbol associated with a primitive, it consumes the required number of arguments ($N$) and wraps them in a list:
- `+ x y` → `(+ x y)`
- `car x` → `(car x)`

### 2.2 Read-time Macros
The following transformations occur during the `read` phase:
- `' <exp>` → `(quote <exp>)`
- `" <exp>` → Reads `<exp>` as a raw S-expression (disables expansion).
- `cadr <x>` → `(car (cdr <x>))`
- `caddr <x>` → `(car (cdr (cdr <x>)))`
- `run-utm-on <bits>` → `(car (cdr (try no-time-limit '(eval (read-exp)) <bits>)))`
- `let <sym> <val> <body>` → `((' (lambda (<sym>) <body>)) <val>)`
- `let (<sym> <args>) <val> <body>` → `((' (lambda (<sym>) <body>)) (' (lambda (<args>) <val>)))`

### 2.3 Comments
Tokens enclosed in square brackets `[...]` are ignored. Comments may be nested.

3. Evaluation Semantics
-----------------------
Evaluation is performed by the `eval` function, which takes an expression and a time limit (step count).

### 3.1 Atomic Evaluation
- **Numbers**: Evaluate to themselves.
- **Symbols**: Evaluate to the value currently bound to them.
- **Clean Environment**: Within `eval` or `try`, all symbols (except `nil`) are initially bound to themselves. This allows symbols to act as constants in algebraic manipulations.

### 3.2 List Evaluation
1. The first element (operator) is evaluated.
2. If the operator is `quote`, the second element is returned unevaluated.
3. If the operator is `if`, the condition is evaluated. If it results in `true`, the second branch is evaluated; otherwise, the third.
4. For all other cases, the remaining elements (arguments) are evaluated from left to right.
5. If the operator is a `lambda`, the arguments are bound to the lambda's parameters in a new scope, and the body is evaluated.
6. If the operator is a Primitive, the corresponding internal logic is executed.

4. Primitives
-------------

### 4.1 List Manipulation
- `(car x)`, `(cdr x)`: 
    - If `x` is a pair, returns the head or tail.
    - If `x` is an atom or number, returns `x`.
- `(cons x y)`: 
    - If `y` is a list, returns a new list with `x` at the head.
    - If `y` is an atom (not `nil`), returns `x` (dotted pairs are forbidden).
- `(atom x)`: Returns `true` if `x` is not a pair; `false` otherwise.
- `(= x y)`: Returns `true` if `x` and `y` are structurally identical; `false` otherwise.

### 4.2 Arithmetic
Operations use arbitrary-precision logic. There are no negative numbers.
- `(+ n m)`, `(* n m)`, `(^ n m)`: Standard addition, multiplication, and exponentiation.
- `(- n m)`: Floor subtraction. Returns `max(0, n - m)`.

### 4.3 Conversions
- `(base2-to-10 bits)`: Converts a list of `0`/`1` bits to a number (MSB first).
- `(base10-to-2 n)`: Converts a number to a list of bits. `0` returns `nil`.
- `(size x)`: Returns the character count of the printed representation of `x`.
- `(bits x)`: Serializes `x` into a list of bits (8 bits per character, MSB first, ending with `\n`).

5. The Try Mechanism
--------------------
`(try limit expression tape)`
Executes `expression` with a step `limit` and an input `tape` (a list of bits).
- **Time**: Each `eval` call decrements the limit.
- **I/O**: `(read-bit)` and `(read-exp)` consume bits from the tape. `(display)` output is captured instead of printed.
- **Returns**: 
    - `(success result displays)` if the evaluation completes.
    - `(failure reason displays)` if a timeout (`out-of-time`) or EOF (`out-of-data`) occurs.