# AIT Lisp interpreter in C

Based on Lisp created by Gregory Chaitin to study Algorithmic Information Theory.

Programs are from:
* https://www.cs.auckland.ac.nz/~chaitin/lm.html
* https://www.cs.auckland.ac.nz/~chaitin/unknowable/
* https://www.cs.auckland.ac.nz/~chaitin/ait/

Lisp interpreters are from:
* https://www.cs.auckland.ac.nz/~chaitin/lisp.c
* https://www.cs.auckland.ac.nz/~chaitin/unknowable/lisp.java
* https://www.cs.auckland.ac.nz/~chaitin/unknowable/Sexp.java

# Chaitin Lisp: Detailed Language Reference

This document provides a formal specification of the Chaitin Lisp dialect, synthesizing its syntax, evaluation semantics, and primitive operations.

## 1. Data Types and Constants

### 1.1 Fundamental Types
- **Symbols (Atoms)**: Named identifiers. 
- **Numbers**: Arbitrary-precision non-negative integers.
- **Pairs (Cons Cells)**: A structure containing two elements: a `car` and a `cdr`.
- **Lists**: Either `nil` or a pair whose `cdr` is a list. This dialect only supports "proper" lists.

### 1.2 Reserved Constants
- `nil` or `()`: Represents the empty list and the boolean false.
- `true`: Boolean true.
- `false`: Boolean false (equivalent to `nil`).
- `no-time-limit`: Used with `try` to indicate an infinite step limit.
- `out-of-time`: Signaled/Returned when a `try` block exceeds its step limit.
- `out-of-data`: Signaled/Returned when `read-bit` or `read-exp` exhausts the input tape.
- `success` / `failure`: Symbols used to tag the result of a `try` execution.

## 2. The Reader (M-Expressions)

The reader transforms input text into S-expressions. It supports a shorthand notation called "M-expressions."

### 2.1 Expansion Rules
If the reader encounters a symbol associated with a primitive, it consumes the required number of arguments ($N$) and wraps them in a list:
- `+ x y` → `(+ x y)`
- `car x` → `(car x)`

### 2.2 Read-time Macros and Shorthands
- `' <exp>`: Quote. Expands to `(quote <exp>)`.
- `" <exp>`: Raw S-expression. Reads `<exp>` literally, disabling M-expression expansion.
- `cadr <x>` / `caddr <x>`: Expands to `(car (cdr <x>))` and `(car (cdr (cdr <x>)))`.
- `let <sym> <val> <body>`: Expands to `((' (lambda (<sym>) <body>)) <val>)`.
- `let (<sym> <args>) <val> <body>`: Expands to `((' (lambda (<sym>) <body>)) (' (lambda (<args>) <val>)))`.
- `run-utm-on <bits>`: Expands to `(car (cdr (try no-time-limit '(eval (read-exp)) <bits>)))`.

### 2.3 Comments
Tokens enclosed in square brackets `[...]` are ignored. Comments may be nested.

## 3. Special Forms

- **`define <sym> <exp>`**: Defines a global variable.
- **`define (<sym> <p1> <p2> ...) <exp>`**: Defines a global function.
- **`lambda (<p1> <p2> ...) <exp>`**: Creates an anonymous function.
- **`quote <exp>`**: Returns `<exp>` unevaluated.
- **`if <cond> <true-branch> <false-branch>`**: Conditional execution. If `<cond>` is non-nil, evaluates the second argument; otherwise, evaluates the third.
- **`eval <exp>`**: Evaluates `<exp>` in a "clean" environment where all symbols (except `nil`) initially evaluate to themselves.

## 4. Evaluation Semantics

Evaluation is performed by the `eval` function, which conceptually takes an expression and an environment.

### 4.1 Atomic Evaluation
- **Numbers**: Evaluate to themselves.
- **Symbols**: Evaluate to the value currently bound to them.
- **Clean Environment**: Within `eval` or `try`, all symbols (except `nil`) are initially bound to themselves. This allows symbols to act as constants (e.g., in algebraic logic).

### 4.2 List Evaluation
1. The operator (first element) is evaluated.
2. If the operator is `quote` or `if`, special rules apply (see Section 3).
3. For all other cases, arguments are evaluated from left to right.
4. If the operator is a `lambda`, parameters are bound in a new scope and the body is evaluated.
5. If the operator is a **Primitive**, the internal logic is executed.

## 5. Primitives

### 5.1 List Manipulation
- `(car x)` / `(cdr x)`: Returns the head or tail of a pair. If `x` is an atom or number, returns `x`.
- `(cons x y)`: Returns a new list with `x` at the head. If `y` is an atom (not `nil`), returns `x` (dotted pairs are forbidden).
- `(atom x)`: Returns `true` if `x` is an atom or number; `false` if it is a pair.
- `(= x y)`: Structural equality for lists, atoms, and numbers.
- `(append xs ys)`: Concatenates two lists.
- `(length xs)`: Returns the number of elements in a list.

### 5.2 Arithmetic
Operations use arbitrary-precision logic. There are no negative numbers.
- `(+ n m)`, `(* n m)`, `(^ n m)`: Addition, multiplication, and exponentiation.
- `(- n m)`: Floor subtraction. Returns max(0, n - m).
- `<, >, <=, >=`: Comparison operators returning `true` or `false`.

### 5.3 Conversions and Serialization
- `(base2-to-10 bits)`: Converts a list of `0`/`1` bits to a number (MSB first).
- `(base10-to-2 n)`: Converts a number to a list of bits. `0` returns `nil`.
- `(size x)`: Returns the character count of the printed representation of `x`.
- `(bits x)`: Serializes `x` into a list of bits (8 bits per character, MSB first, ending with `\n`).

### 5.4 I/O and Debugging
- `(display x)`: Prints `x` to stdout and returns `x`.
- `(debug x)`: Prints `x` with a "debug" label and returns `x`.

## 6. The Try Mechanism

The `try` function provides a sandboxed environment with resource limits.
**Syntax**: `(try limit expression tape)`

- **Time Limit**: `limit` specifies the maximum number of `eval` steps.
- **Input Tape**: `tape` is a list of bits (0s and 1s).
- **I/O Capture**: `(display)` output is captured into a list rather than printed to stdout.
- **Tape Operations**:
    - `(read-bit)`: Consumes one bit from the tape.
    - `(read-exp)`: Consumes bits to parse a full S-expression (8 bits per character).
- **Return Format**:
    - `(success result displays)`: On successful completion.
    - `(failure reason displays)`: If `out-of-time` or `out-of-data` occurs.
