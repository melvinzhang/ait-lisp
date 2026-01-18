# Lisp Programs Analysis

This document categorizes the Lisp programs found in the `ait/`, `lm/`, and `unknowable/` directories by their mathematical and computational themes.

---

## 1. Randomness & Equivalence of Definitions
These programs explore the relationships between different definitions of algorithmic randomness (Chaitin, Solovay, and Martin-Löf).

- ### ait/chaitin.l & ait/chaitin2.l
  **Purpose:** Demonstrates the equivalence between Solovay randomness and strong Chaitin randomness. Part 1 implements an effective covering for non-Solovay random reals; Part 2 shows that non-Chaitin random reals are not Solovay random by constructing a covering with finite total measure.
- ### ait/martin-lof.l & ait/martin-lof2.l
  **Purpose:** Establishes the equivalence between Martin-Löf randomness and Chaitin randomness. Part 1 shows that non-Martin-Löf random reals are not Chaitin random; Part 2 constructs a covering to show the converse.
- ### ait/solovay.l
  **Purpose:** Proves that a real is Solovay random if and only if it is Martin-Löf random by constructing Martin-Löf coverings from Solovay coverings.

---

## 2. Universal Turing Machines & Complexity Foundations
These programs build the infrastructure of Algorithmic Information Theory, defining universal machines and proving core complexity bounds.

- ### lm/utm.l & lm/xutm.l
  **Purpose:** Introduces the self-delimiting universal Turing machine and establishes basic complexity bounds (e.g., $H(x,y) \le H(x) + H(y) + c$). `xutm.l` is an expanded version with more tests for Lisp primitives.
- ### ait/utm2.l
  **Purpose:** Extends the UTM construction to handle relative/conditional complexity, proving bounds like $H(x,y) \le H(x) + H(y|x) + c$.
- ### ait/decomp.l
  **Purpose:** Proves the fundamental decomposition theorem: $H(y|x) \le H_C(x,y) - H(x) + c$.
- ### ait/lemma.l
  **Purpose:** A helper for the decomposition theorem, proving $H(x) \le -\log_2 \sum_y P((x, y)) + c$.
- ### ait/exec.l
  **Purpose:** Simulates a self-delimiting Turing machine from an enumeration of program-output pairs.
- ### ait/kraft.l
  **Purpose:** Implements the Kraft inequality algorithm to assign prefix-free bit strings to program requirements.
- ### ait/occam.l
  **Purpose:** Implements "Occam's Razor" by constructing a computer that assigns shorter programs to high-probability outputs ($H(x) \le -\log_2 P_C(x) + c$).

---

## 3. Halting Probability (Omega)
Programs focused on the calculation, optimization, and complexity of Chaitin's halting probability $\Omega$.

- ### lm/omega.l, lm/xomega.l, lm/omega2.l, lm/xomega2.l
  **Purpose:** Various iterations of calculating $\Omega$ in the limit from below. The `omega2` versions are more memory-efficient (recursive), and `x` versions include more comments/tests.
- ### lm/omega2vb.l
  **Purpose:** An optimized version of the $\Omega$ calculation that prunes the search tree using the prefix-free property.
- ### lm/omega3.l & lm/xomega3.l
  **Purpose:** Proves that the first $n$ bits of $\Omega$ are algorithmically incompressible ($H(\Omega_n) > n - c$).

---

## 4. Incompleteness & Limits of Formal Systems
These programs demonstrate the boundaries of what formal axiomatic systems (FAS) can prove regarding complexity and elegance.

- ### lm/godel.l, lm/xgodel.l & unknowable/chaitin.l
  **Purpose:** Demonstrates Chaitin's version of Gödel's Incompleteness Theorem: a formal system of complexity $N$ cannot prove that an S-expression of size significantly greater than $N$ is "elegant."
- ### lm/godel2.l & lm/xgodel2.l
  **Purpose:** Proves that a formal system of complexity $N$ cannot establish that a specific object has complexity $H(x) > N + c$.
- ### lm/godel3.l & lm/xgodel3.l
  **Purpose:** Shows that a formal system of complexity $N$ cannot determine more than approximately $N$ bits of $\Omega$.
- ### unknowable/godel.l
  **Purpose:** A classic diagonal construction of a Lisp expression that asserts its own unprovability.
- ### unknowable/turing.l
  **Purpose:** A proof of the unsolvability of the halting problem by constructing a Lisp expression that halts if and only if it is predicted not to halt.

---

## 5. Foundations & Tools
Basic test suites, set theory, and self-referential constructions.

- ### lm/examples.l & lm/xexamples.l
  **Purpose:** Comprehensive test suites and tutorials for the Lisp interpreter's primitives and features.
- ### unknowable/sets.l
  **Purpose:** A library for elementary finite set theory (membership, union, intersection, power sets) implemented in Lisp.
- ### unknowable/fixedpoint.l
  **Purpose:** Construction of a Lisp "fixed point" or quine—an expression that evaluates to itself.