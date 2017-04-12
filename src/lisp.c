/* lisp.c: high-speed LISP interpreter */

/*
   The storage required by this interpreter is 8 * 4 = 32 bytes times
   the symbolic constant SIZE, which is 32 * 1,000,000 =
   32 megabytes.  To run this interpreter in small machines,
   reduce the #define SIZE 1000000 below.

   To compile, type
      cc -O -olisp lisp.c
   To run interactively, type
      lisp
   To run with output on screen, type
      lisp <test.l
   To run with output in file, type
      lisp <test.l >test.r

   Reference:  Kernighan & Ritchie,
   The C Programming Language, Second Edition,
   Prentice-Hall, 1988.
*/

#include <stdio.h>
#include <stdlib.h>

// numbers of nodes of tree storage
#define SIZE 1000000
// end of list marker
#define nil 0

#define PFCAR 1
#define PFCDR 2
#define PFCONS 3
#define PFATOM 4
#define PFEQ 5
#define PFDISPLAY 6
#define PFDEBUG 7
#define PFAPPEND 8
#define PFLENGTH 9
#define PFLT 10
#define PFGT 11
#define PFLEQ 12
#define PFGEQ 13
#define PFPLUS 14
#define PFTIMES 15
#define PFPOW 16
#define PFMINUS 17
#define PF2TO10 18
#define PF10TO2 19
#define PFSIZE 20
#define PFREADBIT 21
#define PFBITS 22
#define PFREADEXP 23

// tree storage
long car[SIZE], cdr[SIZE];
// is it an atom?
short atom[SIZE];
// is it a number?
short numb[SIZE];

// The following are only used for atoms

// bindings of each atom
long vlst[SIZE];
// print name of each atom = list of characters in reverse
long pname[SIZE];

// The following are only used for atoms that are the names of primitive functions

// primitive function number (for interpreter switch)
short pf_numb[SIZE];
// number of arguments + 1 (for input parser)
short pf_args[SIZE];

// list of all atoms (& every other token read except numbers)
long obj_lst;

// locations of atoms in tree storage
long wrd_nil, wrd_true, wrd_false, wrd_define, wrd_let, wrd_lambda, wrd_quote, wrd_if;
long wrd_car, wrd_cdr, wrd_cadr, wrd_caddr, wrd_eval, wrd_try;
long wrd_no_time_limit, wrd_out_of_time, wrd_out_of_data, wrd_success, wrd_failure;
long left_bracket, right_bracket, left_paren, right_paren, double_quote;
long wrd_zero, wrd_one;
long wrd_read_exp, wrd_utm;

// next free node
long next_free = 0;
// column in each 50 character chunk of output
// (preceeded by 12 char prefix)
long col = 0;
// number of calls to eval
long time_eval = 0;
// stack of binary data for try's
long turing_machine_tapes;
// stack of flags whether to capture displays or not
long display_enabled;
// stack of stubs to collect captured displays on
long captured_displays;
// for converting s-expressions into lists of bits
long q;
// buffer for converting lists of bits into s-expressions
// contains list of all the words in an input record
long buffer2;


// initialize atoms
void initialize_atoms(void);
// make an atom
long mk_atom(long number, char const *name, long args);
// make an number
long mk_numb(long value);
// make list of characters
long mk_string(char const *p);
// are two lists of characters equal ?
long eq_wrd(long x, long y);
// look up word in object list ?
long lookup_word(long x);
// get free node & stuff x & y in it
long cons(long x, long y);
// output expression
long out(char const *x, long y);
// output list
void out_lst(long x);
// output atom
void out_atm(long x);
// output character
void out_chr(long x);
// read word
long in_word2(void);
// read word - skip comments
long in_word(void);
// input m-exp
long in(long mexp, long rparenokay);
// check if list of characters are exclusively digits
long only_digits(long x);
// initialize and evaluate expression
long ev(long e);
// evaluate expression
long eval(long e, long d);
// evaluate list of expressions
long evalst(long e, long d);
// clean environment
void clean_env(void);
// restore unclean environment
void restore_env(void);
// bind values of arguments to formal parameters
void bind(long vars, long args);
// append two lists
long append(long x, long y);
// equal predicate
long eq(long x, long y);
// number of elements in list
long length(long x);
// compare two decimal numbers
long compare(long x, long y);
// add 1 to decimal number
long add1(long x);
// subtract 1 from decimal number
long sub1(long x);
// pick-up decimal number from atom & convert non-number to zero
long nmb(long x);
// from reversed list of digits of decimal number
long remove_leading_zeros(long x);
// add two decimal numbers
long addition(long x, long y, long carry_in);
// multiply two decimal numbers
long multiplication(long x, long y);
// base raised to the power exponent
long exponentiation(long base, long exponent);
// x - y assumes x >= y
long subtraction(long x, long y, long borrow_in);
// convert bit string to decimal number
long base2_to_10(long x);
// used to convert decimal number to bit string
long halve(long x);
// convert decimal number to bit string
long base10_to_2(long x);
// number of characters in print representation
long size(long x);
// read one square of Turing machine tape
long read_bit(void);
// convert character into 8 bits
void write_chr(long x);
// convert atom into 8 bits per character
void write_atm(long x);
// convert s-exp into list of bits
void write_lst(long x);
// read record from Turing machine tape
long read_record(void);
// read one character from Turing machine tape
long read_char(void);
// read word from Turing machine tape
long read_word(void);
// read s-exp from Turing machine tape
long read_expr(long rparenokay);

// lisp main program
int main(void)
{
  printf("LISP Interpreter Run\n");
  initialize_atoms();

  while (1) {
    long e, f, name, def;
    printf("\n");
    /* read lisp meta-expression, ) not okay */
    e = in(1, 0);
    printf("\n");
    f = car[e];
    name = car[cdr[e]];
    def = car[cdr[cdr[e]]];
    if (f == wrd_define) {
      /* definition */
      if (atom[name]) {
        /* variable definition, e.g., define x (a b c) */
      }
      else {
        /* function definition, e.g., define (F x y) cons x cons y nil */
        long var_list = cdr[name];
        name = car[name];
        def = cons(wrd_lambda, cons(var_list, cons(def, nil)));
      }
      out("define", name);
      out("value", def);
      /* new binding replaces old */
      car[vlst[name]] = def;
      continue;
    }
    /* write corresponding s-expression */
    e = out("expression", e);
    /* evaluate expression */
    e = out("value", ev(e));
  }
}

void initialize_atoms(void) /* initialize atoms */
{
  if (nil != mk_atom(0, "()", 0)) {
    printf("nil != 0\n");
    exit(0); /* terminate execution */
  }
  wrd_nil = mk_atom(0, "nil", 0);
  car[vlst[wrd_nil]] = nil; /* so that value of nil is () */
  wrd_true = mk_atom(0, "true", 0);
  wrd_false = mk_atom(0, "false", 0);
  wrd_no_time_limit = mk_atom(0, "no-time-limit", 0);
  wrd_out_of_time = mk_atom(0, "out-of-time", 0);
  wrd_out_of_data = mk_atom(0, "out-of-data", 0);
  wrd_success = mk_atom(0, "success", 0);
  wrd_failure = mk_atom(0, "failure", 0);
  wrd_define = mk_atom(0, "define", 3);
  wrd_let = mk_atom(0, "let", 4);
  wrd_lambda = mk_atom(0, "lambda", 3);
  wrd_cadr = mk_atom(0, "cadr", 2);
  wrd_caddr = mk_atom(0, "caddr", 2);
  wrd_utm = mk_atom(0, "run-utm-on", 2);
  wrd_quote = mk_atom(0, "'", 2);
  wrd_if = mk_atom(0, "if", 4);
  wrd_car = mk_atom(PFCAR, "car", 2);
  wrd_cdr = mk_atom(PFCDR, "cdr", 2);
  mk_atom(PFCONS, "cons", 3);
  mk_atom(PFATOM, "atom", 2);
  mk_atom(PFEQ, "=", 3);
  mk_atom(PFDISPLAY, "display", 2);
  mk_atom(PFDEBUG, "debug", 2);
  mk_atom(PFAPPEND, "append", 3);
  mk_atom(PFLENGTH, "length", 2);
  mk_atom(PFLT, "<", 3);
  mk_atom(PFGT, ">", 3);
  mk_atom(PFLEQ, "<=", 3);
  mk_atom(PFGEQ, ">=", 3);
  mk_atom(PFPLUS, "+", 3);
  mk_atom(PFTIMES, "*", 3);
  mk_atom(PFPOW, "^", 3);
  mk_atom(PFMINUS, "-", 3);
  mk_atom(PF2TO10, "base2-to-10", 2);
  mk_atom(PF10TO2, "base10-to-2", 2);
  mk_atom(PFSIZE, "size", 2);
  mk_atom(PFREADBIT, "read-bit", 1);
  mk_atom(PFBITS, "bits", 2);
  wrd_read_exp = mk_atom(PFREADEXP, "read-exp", 1);
  wrd_eval = mk_atom(0, "eval", 2);
  wrd_try = mk_atom(0, "try", 4);
  left_bracket = mk_atom(0, "[", 0);
  right_bracket = mk_atom(0, "]", 0);
  left_paren = mk_atom(0, "(", 0);
  right_paren = mk_atom(0, ")", 0);
  double_quote = mk_atom(0, "\"", 0);
  wrd_zero = mk_numb(nil);
  wrd_one = mk_numb(cons('1', nil));
}

long mk_atom(long number, char const *name, long args) /* make an atom */
{
  long a;
  a = cons(nil, nil);  /* get an empty node */
  car[a] = cdr[a] = a; /* so that car & cdr of atom = atom */
  atom[a] = 1;
  numb[a] = 0;
  pname[a] = mk_string(name);
  pf_numb[a] = number;
  pf_args[a] = args;
  /* initially each atom evaluates to self */
  vlst[a] = cons(a, nil);
  /* put on object list */
  obj_lst = cons(a, obj_lst);
  return a;
}

long mk_numb(long value) /* make an number */
{ /* digits are in reverse order, and 0 has empty list of digits */
  long a;
  a = cons(nil, nil);  /* get an empty node */
  car[a] = cdr[a] = a; /* so that car & cdr of atom = atom */
  atom[a] = 1;
  numb[a] = 1;
  pname[a] =
      value; /* must make 00099 into 99 and 000 into empty list of digits */
  /* if necessary before calling this routine (to avoid removing leading zeros
   * unnecessarily) */
  pf_numb[a] = 0;
  pf_args[a] = 0;
  vlst[a] = 0;
  /* do not put on object list ! */
  return a;
}

long mk_string(char const *p) /* make list of characters */
{                             /* in reverse order */
  long v = nil;
  while (*p != '\0') v = cons(*p++, v);
  return v;
}

long cons(long x, long y) /* get free node & stuff x & y in it */
{
  long z;

  /* if y is not a list, then cons is x */
  if (y != nil && atom[y]) return x;

  if (next_free >= SIZE) {
    printf("Storage overflow!\n");
    exit(0);
  }

  z = next_free++;
  car[z] = x;
  cdr[z] = y;
  atom[z] = 0;
  numb[z] = 0;
  pname[z] = 0;
  pf_numb[z] = 0;
  pf_args[z] = 0;
  vlst[z] = 0;

  return z;
}

long out(char const *x, long y) /* output expression */
{
  printf("%-12s", x);
  col = 0; /* so can insert \n and 12 blanks
              every 50 characters of output */
  out_lst(y);
  printf("\n");
  return y;
}

void out_lst(long x) /* output list */
{
  if (numb[x] && pname[x] == nil) {
    out_chr('0');
    return;
  } /* null list of digits means zero */
  if (atom[x]) {
    out_atm(pname[x]);
    return;
  }
  out_chr('(');
  while (!atom[x]) {
    out_lst(car[x]);
    x = cdr[x];
    if (!atom[x]) out_chr(' ');
  }
  out_chr(')');
}

void out_atm(long x) /* output atom */
{
  if (x == nil) return;
  out_atm(cdr[x]); /* output characters in reverse order */
  out_chr(car[x]);
}

void out_chr(long x) /* output character */
{
  if (col++ == 50) {
    printf("\n%-12s", " ");
    col = 1;
  }
  putchar(x);
}

long eq_wrd(long x, long y) /* are two lists of characters equal ? */
{
  if (x == nil) return y == nil;
  if (y == nil) return 0;
  if (car[x] != car[y]) return 0;
  return eq_wrd(cdr[x], cdr[y]);
}

long lookup_word(long x) /* is word in object list ? */
{
  long i = obj_lst;
  while (!atom[i]) {
    /* if word is already in object list, don't make a new atom */
    if (eq_wrd(pname[car[i]], x)) return car[i];
    i = cdr[i];
  }
  /* if word isn't in object list, make new atom & add it to object list */
  i = mk_atom(0, "", 0); /* adds word to object list */
  pname[i] = x;
  return i;
}

long in_word2(void) {       /* read word */
  static long buffer = nil; /* buffer with all the words in a line of input */
  long character, word, line, end_of_line, end_of_buffer;
  while (buffer == nil) {                /* read in a line */
    line = end_of_line = cons(nil, nil); /* stub */
    do {                                 /* read characters until '\n' */
      character = getchar();
      if (character == EOF) {
        printf(
          "End of LISP Run\n\n"
          "Calls to eval = %ld\n"
          "Calls to cons = %ld\n",
          time_eval, next_free
        );
        exit(0); /* terminate execution */
      }
      putchar(character);
      /* add character to end of line */
      end_of_line = cdr[end_of_line] = cons(character, nil);
    }
    while (character != '\n');
    line = cdr[line]; /* remove stub at beginning of line */
    /* break line into words at  ( ) [ ] ' " characters */
    buffer = end_of_buffer = cons(nil, nil); /* stub */
    word = nil;
    while (line != nil) {
      character = car[line];
      line = cdr[line];
      /* look for characters that break words */
      if (character == ' ' || character == '\n' || character == '(' ||
          character == ')' || character == '[' || character == ']' ||
          character == '\'' ||
          character == '\"') { /* add nonempty word to end of buffer */
        if (word != nil) end_of_buffer = cdr[end_of_buffer] = cons(word, nil);
        word = nil;
        /* add break character to end of buffer */
        if (character != ' ' && character != '\n')
          end_of_buffer = cdr[end_of_buffer] = cons(cons(character, nil), nil);
      } else { /* add character to word (in reverse order) */
        /* keep only nonblank printable ASCII codes */
        if (32 < character && character < 127) word = cons(character, word);
      }
    }
    buffer = cdr[buffer]; /* remove stub at beginning of buffer */
  }
  /* if buffer nonempty, return first word in buffer */
  word = car[buffer];
  buffer = cdr[buffer];
  /* first check if word consists only of digits */
  if (only_digits(word)) word = mk_numb(remove_leading_zeros(word));
  /* also makes 00099 into 99 and 0000 into null */
  else
    word = lookup_word(word); /* look up word in object list */
  /* also does mk_atom and adds it to object list if necessary */
  return word;
}

long only_digits(long x) /* check if list of characters are exclusively digits */
{
  while (x != nil) {
    long digit = car[x];
    if (digit < '0' || digit > '9') return 0;
    x = cdr[x];
  }
  return 1;
}

long in_word(void) /* read word - skip comments */
{
  long w;
  while (1) {
    w = in_word2();
    if (w != left_bracket) return w;
    while (in_word() != right_bracket)
      ; /* comments may be nested */
  }
}

long in(long mexp, long rparenokay) /* input m-exp */
{
  long w = in_word(), first, last, next, name, def, body, var_lst, i;
  if (w == right_paren) {
    if (rparenokay) {
      return w;
    } else {
      return nil;
    }
  }
  if (w == left_paren) { /* explicit list */
    first = last = cons(nil, nil);
    while ((next = in(mexp, 1)) != right_paren)
      last = cdr[last] = cons(next, nil);
    return cdr[first];
  }
  if (!mexp) return w;                    /* atom */
  if (w == double_quote) return in(0, 0); /* s-exp */
  if (w == wrd_cadr) {  /* expand cadr */
    long sexp = in(1, 0);
    sexp = cons(wrd_cdr, cons(sexp, nil));
    return cons(wrd_car, cons(sexp, nil));
  }
  if (w == wrd_caddr) { /* expand caddr */
    long sexp = in(1, 0);
    sexp = cons(wrd_cdr, cons(sexp, nil));
    sexp = cons(wrd_cdr, cons(sexp, nil));
    return cons(wrd_car, cons(sexp, nil));
  }
  if (w == wrd_utm) {
    long sexp = in(1, 0);
    sexp = cons(sexp, nil);
    sexp = cons(cons(wrd_quote, cons(cons(wrd_eval, cons(cons(wrd_read_exp, nil), nil)), nil)), sexp);
    sexp = cons(wrd_try, cons(wrd_no_time_limit, sexp));
    sexp = cons(wrd_cdr, cons(sexp, nil));
    sexp = cons(wrd_car, cons(sexp, nil));
    return sexp;
  }
  if (w == wrd_let) { /* expand let name def body  */
    name = in(1, 0);
    def = in(1, 0);
    body = in(1, 0);
    if (!atom[name]) { /* let (name var_lst) def body */
      var_lst = cdr[name];
      name = car[name];
      def = cons(wrd_quote,
                 cons(cons(wrd_lambda, cons(var_lst, cons(def, nil))), nil));
    }
    return /* let name def body */
        cons(cons(wrd_quote,
                  cons(cons(wrd_lambda, cons(cons(name, nil), cons(body, nil))),
                       nil)),
             cons(def, nil));
  }
  i = pf_args[w];
  if (i == 0) return w; /* normal atom */
  /* atom is a primitive function with i-1 arguments */
  first = last = cons(w, nil);
  while (--i > 0) last = cdr[last] = cons(in(1, 0), nil);
  return first;
}

long ev(long e) /* initialize and evaluate expression */
{
  long v;
  turing_machine_tapes = cons(nil, nil);
  display_enabled = cons(1, nil);
  captured_displays = cons(nil, nil);
  v = eval(e, wrd_no_time_limit);
  return (v < 0 ? -v : v);
}

long eval(long e, long d) /* evaluate expression */
{
  /*
   e is expression to be evaluated
   d is permitted depth - decimal integer, or wrd_no_time_limit
  */
  long f, v, args, x, y, z, vars, body, var;

  time_eval++;

  if (numb[e]) return e;
  /* find current binding of atomic expression */
  if (atom[e]) return car[vlst[e]];

  /* lambda expression evaluates to itself */
  if (car[e] == wrd_lambda) return e;

  f = eval(car[e], d); /* evaluate function */
  e = cdr[e];          /* remove function from list of arguments */
  if (f < 0) return f; /* function = error value? */

  if (f == wrd_quote) return car[e]; /* quote */

  if (f == wrd_if) { /* if then else */
    v = eval(car[e], d);
    e = cdr[e];
    if (v < 0) return v; /* error? */
    if (v == wrd_false) e = cdr[e];
    return eval(car[e], d);
  }

  args = evalst(e, d);       /* evaluate list of arguments */
  if (args < 0) return args; /* error? */

  x = car[args];           /* pick up first argument */
  y = car[cdr[args]];      /* pick up second argument */
  z = car[cdr[cdr[args]]]; /* pick up third argument */

  switch (pf_numb[f]) {
    case PFCAR:
      return car[x];
    case PFCDR:
      return cdr[x];
    case PFCONS:
      return cons(x, y);
    case PFATOM:
      return (atom[x] ? wrd_true : wrd_false);
    case PFEQ:
      return (eq(x, y) ? wrd_true : wrd_false);
    case PFDISPLAY:
      if (car[display_enabled])
        return out("display", x);
      else {
        long stub, old_end, new_end;
        stub = car[captured_displays];
        old_end = car[stub];
        new_end = cons(x, nil);
        cdr[old_end] = new_end;
        car[stub] = new_end;
        return x;
      }
    case PFDEBUG:
      return out("debug", x);
    case PFAPPEND:
      return append((atom[x] ? nil : x), (atom[y] ? nil : y));
    case PFLENGTH:
      return mk_numb(length(x));
    case PFLT:
      return (compare(nmb(x), nmb(y)) == '<' ? wrd_true : wrd_false);
    case PFGT:
      return (compare(nmb(x), nmb(y)) == '>' ? wrd_true : wrd_false);
    case PFLEQ:
      return (compare(nmb(x), nmb(y)) != '>' ? wrd_true : wrd_false); /* <= */
    case PFGEQ:
      return (compare(nmb(x), nmb(y)) != '<' ? wrd_true : wrd_false); /* >= */
    case PFPLUS:
      return mk_numb(addition(nmb(x), nmb(y), 0)); /* no carry in initially */
    case PFTIMES:
      return mk_numb(multiplication(nmb(x), nmb(y)));
    case PFPOW:
      return mk_numb(exponentiation(nmb(x), nmb(y)));
    case PFMINUS:
      if (compare(nmb(x), nmb(y)) != '>')
        return mk_numb(nil); /* y too big to subtract from x */
      else
        return mk_numb(remove_leading_zeros(subtraction(nmb(x), nmb(y), 0)));
    /* no borrow in initially */
    case PF2TO10:
      return mk_numb(base2_to_10(x)); /* convert bit string to decimal number */
    case PF10TO2:
      return base10_to_2(nmb(x)); /* convert decimal number to bit string */
    case PFSIZE:
      return mk_numb(size(x)); /* size of print representation of x */
    case PFREADBIT:
      return read_bit(); /* read one square of Turing machine tape */
                         /* convert s-exp to list of bits */
    case PFBITS: {
      v = q = cons(nil, nil);
      write_lst(x);
      write_chr('\n');
      return cdr[v];
    }
    /* read lisp s-expression from Turing machine tape, 8 bits per char */
    case PFREADEXP: {
      v = read_record();
      if (v < 0) return v;
      return read_expr(0);
    }
  }

  if (d != wrd_no_time_limit) {
    if (d == nil) return -wrd_out_of_time; /* depth exceeded -> error! */
    d = sub1(d);                           /* decrement depth */
  }

  if (f == wrd_eval) {
    clean_env(); /* clean environment */
    v = eval(x, d);
    restore_env(); /* restore unclean environment */
    return v;
  }

  if (f == wrd_try) {
    long stub,
        old_try_has_smaller_time_limit = 0; /* assume normal case, that x < d */
    if (x != wrd_no_time_limit) x = nmb(x); /* convert s-exp into number */
    if (x == wrd_no_time_limit ||
        (d != wrd_no_time_limit && compare(x, d) != '<')) {
      old_try_has_smaller_time_limit = 1;
      x = d; /* continue to use older more constraining time limit */
    }
    turing_machine_tapes = cons(z, turing_machine_tapes);
    display_enabled = cons(0, display_enabled);
    stub = cons(0, nil); /* stub to grow list on */
    car[stub] = stub;    /* car of stub gives end of list */
    captured_displays = cons(stub, captured_displays);
    clean_env();
    v = eval(y, x);
    restore_env();
    turing_machine_tapes = cdr[turing_machine_tapes];
    display_enabled = cdr[display_enabled];
    stub = cdr[car[captured_displays]]; /* remove stub */
    captured_displays = cdr[captured_displays];
    if (old_try_has_smaller_time_limit && v == -wrd_out_of_time) return v;
    if (v < 0) return cons(wrd_failure, cons(-v, cons(stub, nil)));
    return cons(wrd_success, cons(v, cons(stub, nil)));
  }

  // f is a lambda expression
  if (car[f] == wrd_lambda) {
    f = cdr[f];
    vars = car[f];
    f = cdr[f];
    body = car[f];

    bind(vars, args);

    v = eval(body, d);

    /* unbind */
    while (!atom[vars]) {
      var = car[vars];
      if (atom[var]) vlst[var] = cdr[vlst[var]];
      vars = cdr[vars];
    }
    return v;
  }

  // everything else is a function that returns itself
  return f;
}

void clean_env(void) /* clean environment */
{
  long o = obj_lst, var;
  while (o != nil) {
    var = car[o];
    vlst[var] = cons(var, vlst[var]); /* everything eval's to self */
    o = cdr[o];
  }
  car[vlst[wrd_nil]] = nil; /* except that value of nil is () */
}

void restore_env(void) /* restore unclean environment */
{
  long o = obj_lst, var;
  while (o != nil) {
    var = car[o];
    if (cdr[vlst[var]] != nil) /* was token read in by read-exp within a try */
      vlst[var] = cdr[vlst[var]];
    o = cdr[o];
  }
}

/* bind values of arguments to formal parameters */
void bind(long vars, long args) {
  long var;
  if (atom[vars]) return;
  bind(cdr[vars], cdr[args]);
  var = car[vars];
  if (atom[var]) vlst[var] = cons(car[args], vlst[var]);
}

long evalst(long e, long d) /* evaluate list of expressions */
{
  long x, y;
  if (e == nil) return nil;
  x = eval(car[e], d);
  if (x < 0) return x; /* error? */
  y = evalst(cdr[e], d);
  if (y < 0) return y; /* error? */
  return cons(x, y);
}

long append(long x, long y) /* append two lists */
{
  if (x == nil) return y;
  return cons(car[x], append(cdr[x], y));
}

long eq(long x, long y) /* equal predicate */
{
  if (x == y) return 1;
  if (numb[x] && numb[y]) return eq_wrd(pname[x], pname[y]);
  if (numb[x] || numb[y]) return 0;
  if (atom[x] || atom[y]) return 0;
  if (eq(car[x], car[y])) return eq(cdr[x], cdr[y]);
  return 0;
}

long length(long x) /* number of elements in list */
{
  if (atom[x]) return nil; /* is zero */
  return add1(length(cdr[x]));
}

long compare(long x, long y) /* compare two decimal numbers */
{
  long already_decided, digit1, digit2;
  if (x == nil && y == nil) return '=';
  if (x == nil && y != nil) return '<';
  if (x != nil && y == nil) return '>';
  already_decided = compare(cdr[x], cdr[y]);
  if (already_decided != '=') return already_decided;
  digit1 = car[x];
  digit2 = car[y];
  if (digit1 < digit2) return '<';
  if (digit1 > digit2) return '>';
  return '=';
}

long add1(long x) /* add 1 to decimal number */
{
  long digit;
  if (x == nil) return cons('1', nil);
  digit = car[x];
  if (digit != '9') return cons(digit + 1, cdr[x]);
  return cons('0', add1(cdr[x]));
}

long sub1(long x) /* subtract 1 from decimal number */
{
  long digit;
  if (x == nil) return x; /* 0 - 1 = 0 */
  digit = car[x];
  if (digit == '1' && cdr[x] == nil) return nil; /* 1 - 1 = 0 */
  if (digit != '0') return cons(digit - 1, cdr[x]);
  return cons('9', sub1(cdr[x]));
}

long nmb(long x) /* pick-up decimal number from atom & convert non-number to zero */
{
  if (numb[x]) return pname[x];
  return nil;
}

long remove_leading_zeros(long x) /* from reversed list of digits of decimal number */
{
  long rest, digit;
  if (x == nil) return nil;
  digit = car[x];
  rest = remove_leading_zeros(cdr[x]);
  if (rest == nil && digit == '0') return nil;
  return cons(digit, rest);
}

long addition(long x, long y, long carry_in) {
  long sum, digit1, digit2, rest1, rest2;
  if (x == nil && !carry_in) return y;
  if (y == nil && !carry_in) return x;
  if (x != nil) {
    digit1 = car[x];
    rest1 = cdr[x];
  } else {
    digit1 = '0';
    rest1 = nil;
  }
  if (y != nil) {
    digit2 = car[y];
    rest2 = cdr[y];
  } else {
    digit2 = '0';
    rest2 = nil;
  }
  sum = digit1 + digit2 + carry_in - '0';
  if (sum <= '9') return cons(sum, addition(rest1, rest2, 0));
  return cons(sum - 10, addition(rest1, rest2, 1));
}

long subtraction(long x, long y, long borrow_in) /* x - y assumes x >= y */
{
  long difference, digit1, digit2, rest1, rest2;
  if (y == nil && !borrow_in) return x;
  if (x != nil) {
    digit1 = car[x];
    rest1 = cdr[x];
  } else {
    digit1 = '0';
    rest1 = nil;
  }
  if (y != nil) {
    digit2 = car[y];
    rest2 = cdr[y];
  } else {
    digit2 = '0';
    rest2 = nil;
  }
  difference = digit1 - digit2 - borrow_in + '0';
  if (difference >= '0') return cons(difference, subtraction(rest1, rest2, 0));
  return cons(difference + 10, subtraction(rest1, rest2, 1));
}

long multiplication(long x, long y) /* goes faster if x is small */
{
  long sum = nil;
  if (y == nil) return nil; /* otherwise produces result 0000 */
  while (x != nil) {
    long digit = car[x];
    while (digit-- > '0') sum = addition(sum, y, 0);
    x = cdr[x];
    y = cons('0', y); /* these are where bad decimal numbers are generated if y is zero */
  }
  return sum;
}

long exponentiation(long base, long exponent) {
  long product = cons('1', nil);
  while (exponent != nil) {
    product = multiplication(base, product); /* multiply faster if smaller comes first */
    exponent = sub1(exponent);
  }
  return product;
}

long base2_to_10(long x) /* convert bit string to decimal number */
{
  long result = nil;
  while (!atom[x]) {
    long next_bit = car[x];
    x = cdr[x];
    if (!numb[next_bit] || pname[next_bit] != nil)
      next_bit = 1;
    else
      next_bit = 0;
    result = addition(result, result, next_bit);
  }
  return result;
}

long halve(long x) /* used to convert decimal number to bit string */
{
  long digit, next_digit, rest, halve_digit;
  if (x == nil) return x; /* half of 0 is 0 */
  digit = car[x] - '0';
  x = cdr[x];
  rest = halve(x);
  if (x == nil)
    next_digit = 0;
  else
    next_digit = car[x] - '0';
  next_digit = next_digit % 2; /* remainder when divided by 2 */
  halve_digit = '0' + (digit / 2) + (5 * next_digit);
  if (halve_digit != '0' || rest != nil) return cons(halve_digit, rest);
  return nil;
}

long base10_to_2(long x) /* convert decimal number to bit string */
{
  long bits = nil;
  while (x != nil) {
    long digit = car[x] - '0';
    bits = cons((digit % 2 ? wrd_one : wrd_zero), bits);
    x = halve(x);
  }
  return bits;
}

long size(long x) /* number of characters in print representation */
{
  long sum = nil;
  if (numb[x] && pname[x] == nil) return add1(nil); /* number zero */
  if (atom[x]) return length(pname[x]);
  while (!atom[x]) {
    sum = addition(sum, size(car[x]), 0);
    x = cdr[x];
    if (!atom[x]) sum = add1(sum); /* blank separator */
  }
  return add1(add1(sum)); /* open & close paren */
}

/* read one square of Turing machine tape */
long read_bit(void) {
  long x, tape = car[turing_machine_tapes];
  if (atom[tape]) return -wrd_out_of_data; /* tape finished ! */
  x = car[tape];
  car[turing_machine_tapes] = cdr[tape];
  if (!numb[x] || pname[x] != nil) return wrd_one;
  return wrd_zero;
}

void write_chr(long x) /* convert character to list of 8 bits */
{
  q = cdr[q] = cons((x & 128 ? wrd_one : wrd_zero), nil);
  q = cdr[q] = cons((x & 64 ? wrd_one : wrd_zero), nil);
  q = cdr[q] = cons((x & 32 ? wrd_one : wrd_zero), nil);
  q = cdr[q] = cons((x & 16 ? wrd_one : wrd_zero), nil);
  q = cdr[q] = cons((x & 8 ? wrd_one : wrd_zero), nil);
  q = cdr[q] = cons((x & 4 ? wrd_one : wrd_zero), nil);
  q = cdr[q] = cons((x & 2 ? wrd_one : wrd_zero), nil);
  q = cdr[q] = cons((x & 1 ? wrd_one : wrd_zero), nil);
}

void write_lst(long x) /* convert s-exp to list of bits */
{
  if (numb[x] && pname[x] == nil) {
    write_chr('0');
    return;
  } /* null list of digits means zero */
  if (atom[x]) {
    write_atm(pname[x]);
    return;
  }
  write_chr('(');
  while (!atom[x]) {
    write_lst(car[x]);
    x = cdr[x];
    if (!atom[x]) write_chr(' ');
  }
  write_chr(')');
}

void write_atm(long x) /* convert atom to 8 bits per character */
{
  if (x == nil) return;
  write_atm(cdr[x]); /* output characters in reverse order */
  write_chr(car[x]);
}

/* read one character from Turing machine tape */
long read_char(void) {
  long c, b, i = 8;
  c = 0;
  while (i-- > 0) {
    b = read_bit();
    if (b < 0) return b; /* error? */
    if (pname[b] != nil)
      b = 1;
    else
      b = 0;
    c = c + c + b;
  }
  return c;
}

long read_record(void) /* read record from Turing machine tape */
{                      /* fill buffer2 with all the words in an input record */
  long character, word, line, end_of_line, end_of_buffer;
  line = end_of_line = cons(nil, nil); /* stub */
  do {                                 /* read characters until '\n' */
    character = read_char();
    if (character < 0) return character; /* error? */
    ;
    /* add character to end of line */
    end_of_line = cdr[end_of_line] = cons(character, nil);
  }
  while (character != '\n');
  line = cdr[line]; /* remove stub at beginning of line */
  /* break line into words at ( ) characters */
  buffer2 = end_of_buffer = cons(nil, nil); /* stub */
  word = nil;
  while (line != nil) {
    character = car[line];
    line = cdr[line];
    /* look for characters that break words */
    if (character == ' ' || character == '\n' || character == '(' ||
        character == ')') { /* add nonempty word to end of buffer */
      if (word != nil) end_of_buffer = cdr[end_of_buffer] = cons(word, nil);
      word = nil;
      /* add break character to end of buffer */
      if (character != ' ' && character != '\n')
        end_of_buffer = cdr[end_of_buffer] = cons(cons(character, nil), nil);
    } else { /* add character to word (in reverse order) */
      /* keep only nonblank printable ASCII codes */
      if (32 < character && character < 127) word = cons(character, word);
    }
  }
  buffer2 = cdr[buffer2]; /* remove stub at beginning of buffer */
  return 0;               /* indicates no error */
}

long read_word(void) { /* read word from Turing machine tape */
  /* buffer2 has all the words in the input record */
  long word;
  /* (if buffer empty, returns as many right parens as needed) */
  if (buffer2 == nil) return right_paren;
  /* if buffer nonempty, return first word in buffer */
  word = car[buffer2];
  buffer2 = cdr[buffer2];
  /* first check if word consists only of digits */
  if (only_digits(word)) word = mk_numb(remove_leading_zeros(word));
  /* also makes 00099 into 99 and 0000 into null */
  else
    word = lookup_word(word); /* look up word in object list */
  /* also does mk_atom and adds it to object list if necessary */
  return word;
}

long read_expr(long rparenokay) /* read s-exp from Turing machine tape */
{
  long w = read_word(), first, last, next;
  if (w < 0) return w; /* error? */
  if (w == right_paren) {
    if (rparenokay) {
      return w;
    } else {
      return nil;
    }
  }
  if (w == left_paren) { /* explicit list */
    first = last = cons(nil, nil);
    while ((next = read_expr(1)) != right_paren) {
      if (next < 0) return next; /* error? */
      last = cdr[last] = cons(next, nil);
    }
    return cdr[first];
  }
  return w; /* normal atom */
}
