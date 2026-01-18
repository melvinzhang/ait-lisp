package main

import (
	"bufio"
	"fmt"
	"os"
)

// --- Constants ---

const (
	SIZE = 1000000
	NIL  = 0 // #define nil 0
)

const (
	PFCAR     = 1
	PFCDR     = 2
	PFCONS    = 3
	PFATOM    = 4
	PFEQ      = 5
	PFDISPLAY = 6
	PFDEBUG   = 7
	PFAPPEND  = 8
	PFLENGTH  = 9
	PFLT      = 10
	PFGT      = 11
	PFLEQ     = 12
	PFGEQ     = 13
	PFPLUS    = 14
	PFTIMES   = 15
	PFPOW     = 16
	PFMINUS   = 17
	PF2TO10   = 18
	PF10TO2   = 19
	PFSIZE    = 20
	PFREADBIT = 21
	PFBITS    = 22
	PFREADEXP = 23
)

// --- Globals ---

var (
	// tree storage
	car = make([]int, SIZE)
	cdr = make([]int, SIZE)
	// is it an atom?
	atom = make([]int, SIZE) // short in C
	// is it a number?
	numb = make([]int, SIZE) // short in C

	// bindings of each atom
	vlst = make([]int, SIZE)
	// print name of each atom = list of characters in reverse
	pname = make([]int, SIZE)

	// primitive function number
	pf_numb = make([]int, SIZE) // short
	// number of arguments + 1
	pf_args = make([]int, SIZE) // short

	// list of all atoms
	obj_lst int
)

// locations of atoms in tree storage
var (
	wrd_nil, wrd_true, wrd_false, wrd_define, wrd_let, wrd_lambda, wrd_quote, wrd_if int
	wrd_car, wrd_cdr, wrd_cadr, wrd_caddr, wrd_eval, wrd_try                         int
	wrd_no_time_limit, wrd_out_of_time, wrd_out_of_data, wrd_success, wrd_failure    int
	left_bracket, right_bracket, left_paren, right_paren, double_quote               int
	wrd_zero, wrd_one                                                                int
	wrd_read_exp, wrd_utm                                                            int
)

var (
	next_free            int = 0
	col                  int = 0
	time_eval            int = 0
	turing_machine_tapes int
	display_enabled      int
	captured_displays    int
	q                    int
	buffer2              int
)

var reader *bufio.Reader

// --- Initialization & Allocation ---

func initialize_atoms() {
	if NIL != mk_atom(0, "()", 0) {
		fmt.Println("nil != 0")
		os.Exit(0)
	}
	wrd_nil = mk_atom(0, "nil", 0)
	// so that value of nil is ()
	car[vlst[wrd_nil]] = NIL
	wrd_true = mk_atom(0, "true", 0)
	wrd_false = mk_atom(0, "false", 0)
	wrd_no_time_limit = mk_atom(0, "no-time-limit", 0)
	wrd_out_of_time = mk_atom(0, "out-of-time", 0)
	wrd_out_of_data = mk_atom(0, "out-of-data", 0)
	wrd_success = mk_atom(0, "success", 0)
	wrd_failure = mk_atom(0, "failure", 0)
	wrd_define = mk_atom(0, "define", 3)
	wrd_let = mk_atom(0, "let", 4)
	wrd_lambda = mk_atom(0, "lambda", 3)
	wrd_cadr = mk_atom(0, "cadr", 2)
	wrd_caddr = mk_atom(0, "caddr", 2)
	wrd_utm = mk_atom(0, "run-utm-on", 2)
	wrd_quote = mk_atom(0, "'", 2)
	wrd_if = mk_atom(0, "if", 4)
	wrd_car = mk_atom(PFCAR, "car", 2)
	wrd_cdr = mk_atom(PFCDR, "cdr", 2)
	mk_atom(PFCONS, "cons", 3)
	mk_atom(PFATOM, "atom", 2)
	mk_atom(PFEQ, "=", 3)
	mk_atom(PFDISPLAY, "display", 2)
	mk_atom(PFDEBUG, "debug", 2)
	mk_atom(PFAPPEND, "append", 3)
	mk_atom(PFLENGTH, "length", 2)
	mk_atom(PFLT, "<", 3)
	mk_atom(PFGT, ">", 3)
	mk_atom(PFLEQ, "<=", 3)
	mk_atom(PFGEQ, ">=", 3)
	mk_atom(PFPLUS, "+", 3)
	mk_atom(PFTIMES, "*", 3)
	mk_atom(PFPOW, "^", 3)
	mk_atom(PFMINUS, "-", 3)
	mk_atom(PF2TO10, "base2-to-10", 2)
	mk_atom(PF10TO2, "base10-to-2", 2)
	mk_atom(PFSIZE, "size", 2)
	mk_atom(PFREADBIT, "read-bit", 1)
	mk_atom(PFBITS, "bits", 2)
	wrd_read_exp = mk_atom(PFREADEXP, "read-exp", 1)
	wrd_eval = mk_atom(0, "eval", 2)
	wrd_try = mk_atom(0, "try", 4)
	left_bracket = mk_atom(0, "[", 0)
	right_bracket = mk_atom(0, "]", 0)
	left_paren = mk_atom(0, "(", 0)
	right_paren = mk_atom(0, ")", 0)
	double_quote = mk_atom(0, "\"", 0)
	wrd_zero = mk_numb(NIL)
	wrd_one = mk_numb(cons('1', NIL))
}

func mk_atom(number int, name string, args int) int {
	var a int
	a = cons(NIL, NIL)
	// so that car & cdr of atom = atom
	car[a] = a
	cdr[a] = a
	atom[a] = 1
	numb[a] = 0
	pname[a] = mk_string(name)
	pf_numb[a] = number
	pf_args[a] = args
	// initially each atom evaluates to self
	vlst[a] = cons(a, NIL)
	// put on object list
	obj_lst = cons(a, obj_lst)
	return a
}

func mk_numb(value int) int {
	var a int
	a = cons(NIL, NIL)
	car[a] = a
	cdr[a] = a
	atom[a] = 1
	numb[a] = 1
	pname[a] = value
	pf_numb[a] = 0
	pf_args[a] = 0
	vlst[a] = 0
	return a
}

func mk_string(p string) int {
	v := NIL
	for i := 0; i < len(p); i++ {
		v = cons(int(p[i]), v)
	}
	return v
}

func cons(x, y int) int {
	var z int
	// if y is not a list, then cons is x
	if y != NIL && atom[y] != 0 {
		return x
	}
	if next_free >= SIZE {
		fmt.Println("Storage overflow!")
		os.Exit(0)
	}
	z = next_free
	next_free++
	car[z] = x
	cdr[z] = y
	atom[z] = 0
	numb[z] = 0
	pname[z] = 0
	pf_numb[z] = 0
	pf_args[z] = 0
	vlst[z] = 0
	return z
}

// --- Output ---

func out(x string, y int) int {
	fmt.Printf("%-12s", x)
	col = 0
	out_lst(y)
	fmt.Printf("\n")
	return y
}

func out_lst(x int) {
	if numb[x] != 0 && pname[x] == NIL {
		out_chr('0')
		return
	}
	if atom[x] != 0 {
		out_atm(pname[x])
		return
	}
	out_chr('(')
	for atom[x] == 0 {
		out_lst(car[x])
		x = cdr[x]
		if atom[x] == 0 {
			out_chr(' ')
		}
	}
	out_chr(')')
}

func out_atm(x int) {
	if x == NIL {
		return
	}
	out_atm(cdr[x])
	out_chr(car[x])
}

func out_chr(x int) {
	if col == 50 {
		fmt.Printf("\n%-12s", " ")
		col = 1
	} else {
		col++
	}
	fmt.Printf("%c", x)
}

// --- Utils ---

func eq_wrd(x, y int) int {
	if x == NIL {
		if y == NIL {
			return 1
		}
		return 0
	}
	if y == NIL {
		return 0
	}
	if car[x] != car[y] {
		return 0
	}
	return eq_wrd(cdr[x], cdr[y])
}

func lookup_word(x int) int {
	i := obj_lst
	for atom[i] == 0 {
		if eq_wrd(pname[car[i]], x) != 0 {
			return car[i]
		}
		i = cdr[i]
	}
	i = mk_atom(0, "", 0)
	pname[i] = x
	return i
}

// --- IO Wrapper ---

func getchar() int {
	b, err := reader.ReadByte()
	if err != nil {
		fmt.Printf("End of LISP Run\n\nCalls to eval = %d\nCalls to cons = %d\n", time_eval, next_free)
		os.Exit(0)
	}
	return int(b)
}

// --- Parser ---

var in_word2_buffer int = NIL

func in_word2() int {
	var character, word, line, end_of_line, end_of_buffer int
	for in_word2_buffer == NIL {
		// Stub
		line = cons(NIL, NIL)
		end_of_line = line
		for {
			character = getchar()
			fmt.Printf("%c", character)
			new_node := cons(character, NIL)
			cdr[end_of_line] = new_node
			end_of_line = new_node
			if character == '\n' {
				break
			}
		}
		line = cdr[line] // remove stub

		in_word2_buffer = cons(NIL, NIL)
		end_of_buffer = in_word2_buffer // stub
		word = NIL

		for line != NIL {
			character = car[line]
			line = cdr[line]
			if character == ' ' || character == '\n' || character == '(' ||
				character == ')' || character == '[' || character == ']' ||
				character == '\'' || character == '"' {
				if word != NIL {
					new_node := cons(word, NIL)
					cdr[end_of_buffer] = new_node
					end_of_buffer = new_node
				}
				word = NIL
				if character != ' ' && character != '\n' {
					new_node := cons(cons(character, NIL), NIL)
					cdr[end_of_buffer] = new_node
					end_of_buffer = new_node
				}
			} else {
				if 32 < character && character < 127 {
					word = cons(character, word)
				}
			}
		}
		in_word2_buffer = cdr[in_word2_buffer] // remove stub
	}
	word = car[in_word2_buffer]
	in_word2_buffer = cdr[in_word2_buffer]
	if only_digits(word) != 0 {
		word = mk_numb(remove_leading_zeros(word))
	} else {
		word = lookup_word(word)
	}
	return word
}

func only_digits(x int) int {
	for x != NIL {
		digit := car[x]
		if digit < '0' || digit > '9' {
			return 0
		}
		x = cdr[x]
	}
	return 1
}

func in_word() int {
	var w int
	for {
		w = in_word2()
		if w != left_bracket {
			return w
		}
		for in_word() != right_bracket {
		}
	}
}

func in(mexp, rparenokay int) int {
	var w, first, last, next, name, def, body, var_lst, i int
	w = in_word()
	if w == right_paren {
		if rparenokay != 0 {
			return w
		} else {
			return NIL
		}
	}
	if w == left_paren {
		first = cons(NIL, NIL)
		last = first
		for {
			next = in(mexp, 1)
			if next == right_paren {
				break
			}
			new_node := cons(next, NIL)
			cdr[last] = new_node
			last = new_node
		}
		return cdr[first]
	}
	if mexp == 0 {
		return w
	}
	if w == double_quote {
		return in(0, 0)
	}
	if w == wrd_cadr {
		sexp := in(1, 0)
		sexp = cons(wrd_cdr, cons(sexp, NIL))
		return cons(wrd_car, cons(sexp, NIL))
	}
	if w == wrd_caddr {
		sexp := in(1, 0)
		sexp = cons(wrd_cdr, cons(sexp, NIL))
		sexp = cons(wrd_cdr, cons(sexp, NIL))
		return cons(wrd_car, cons(sexp, NIL))
	}
	if w == wrd_utm {
		sexp := in(1, 0)
		sexp = cons(sexp, NIL)
		sexp = cons(cons(wrd_quote, cons(cons(wrd_eval, cons(cons(wrd_read_exp, NIL), NIL)), NIL)), sexp)
		sexp = cons(wrd_try, cons(wrd_no_time_limit, sexp))
		sexp = cons(wrd_cdr, cons(sexp, NIL))
		sexp = cons(wrd_car, cons(sexp, NIL))
		return sexp
	}
	if w == wrd_let {
		name = in(1, 0)
		def = in(1, 0)
		body = in(1, 0)
		if atom[name] == 0 {
			var_lst = cdr[name]
			name = car[name]
			def = cons(wrd_quote, cons(cons(wrd_lambda, cons(var_lst, cons(def, NIL))), NIL))
		}
		return cons(cons(wrd_quote, cons(cons(wrd_lambda, cons(cons(name, NIL), cons(body, NIL))), NIL)), cons(def, NIL))
	}
	i = pf_args[w]
	if i == 0 {
		return w
	}
	// primitive function
	first = cons(w, NIL)
	last = first
	i--
	for i > 0 {
		new_node := cons(in(1, 0), NIL)
		cdr[last] = new_node
		last = new_node
		i--
	}
	return first
}

// --- Evaluator ---

func ev(e int) int {
	var v int
	turing_machine_tapes = cons(NIL, NIL)
	display_enabled = cons(1, NIL)
	captured_displays = cons(NIL, NIL)
	v = eval(e, wrd_no_time_limit)
	if v < 0 {
		return -v
	}
	return v
}

func eval(e, d int) int {
	var f, v, args, x, y, z, vars, body, var_ int

	time_eval++

	if numb[e] != 0 {
		return e
	}
	if atom[e] != 0 {
		return car[vlst[e]]
	}
	if car[e] == wrd_lambda {
		return e
	}

	f = eval(car[e], d)
	e = cdr[e]
	if f < 0 {
		return f
	}

	if f == wrd_quote {
		return car[e]
	}

	if f == wrd_if {
		v = eval(car[e], d)
		e = cdr[e]
		if v < 0 {
			return v
		}
		if v == wrd_false {
			e = cdr[e]
		}
		return eval(car[e], d)
	}

	args = evalst(e, d)
	if args < 0 {
		return args
	}

	x = car[args]
	y = car[cdr[args]]
	z = car[cdr[cdr[args]]]

	switch pf_numb[f] {
	case PFCAR:
		return car[x]
	case PFCDR:
		return cdr[x]
	case PFCONS:
		return cons(x, y)
	case PFATOM:
		if atom[x] != 0 {
			return wrd_true
		}
		return wrd_false
	case PFEQ:
		if eq(x, y) != 0 {
			return wrd_true
		}
		return wrd_false
	case PFDISPLAY:
		if car[display_enabled] != 0 {
			return out("display", x)
		} else {
			stub := car[captured_displays]
			old_end := car[stub]
			new_end := cons(x, NIL)
			cdr[old_end] = new_end
			car[stub] = new_end
			return x
		}
	case PFDEBUG:
		return out("debug", x)
	case PFAPPEND:
		paramX := x
		if atom[x] != 0 {
			paramX = NIL
		}
		paramY := y
		if atom[y] != 0 {
			paramY = NIL
		}
		return append_list(paramX, paramY)
	case PFLENGTH:
		return mk_numb(length(x))
	case PFLT:
		if compare(nmb(x), nmb(y)) == '<' {
			return wrd_true
		}
		return wrd_false
	case PFGT:
		if compare(nmb(x), nmb(y)) == '>' {
			return wrd_true
		}
		return wrd_false
	case PFLEQ:
		if compare(nmb(x), nmb(y)) != '>' {
			return wrd_true
		}
		return wrd_false
	case PFGEQ:
		if compare(nmb(x), nmb(y)) != '<' {
			return wrd_true
		}
		return wrd_false
	case PFPLUS:
		return mk_numb(addition(nmb(x), nmb(y), 0))
	case PFTIMES:
		return mk_numb(multiplication(nmb(x), nmb(y)))
	case PFPOW:
		return mk_numb(exponentiation(nmb(x), nmb(y)))
	case PFMINUS:
		if compare(nmb(x), nmb(y)) != '>' {
			return mk_numb(NIL)
		} else {
			return mk_numb(remove_leading_zeros(subtraction(nmb(x), nmb(y), 0)))
		}
	case PF2TO10:
		return mk_numb(base2_to_10(x))
	case PF10TO2:
		return base10_to_2(nmb(x))
	case PFSIZE:
		return mk_numb(size(x))
	case PFREADBIT:
		return read_bit()
	case PFBITS:
		v = cons(NIL, NIL)
		q = v
		write_lst(x)
		write_chr('\n')
		return cdr[v]
	case PFREADEXP:
		v = read_record()
		if v < 0 {
			return v
		}
		return read_expr(0)
	}

	if d != wrd_no_time_limit {
		if d == NIL {
			return -wrd_out_of_time
		}
		d = sub1(d)
	}

	if f == wrd_eval {
		clean_env()
		v = eval(x, d)
		restore_env()
		return v
	}

	if f == wrd_try {
		var stub int
		old_try_has_smaller_time_limit := 0
		if x != wrd_no_time_limit {
			x = nmb(x)
		}
		if x == wrd_no_time_limit || (d != wrd_no_time_limit && compare(x, d) != '<') {
			old_try_has_smaller_time_limit = 1
			x = d
		}
		turing_machine_tapes = cons(z, turing_machine_tapes)
		display_enabled = cons(0, display_enabled)
		stub = cons(0, NIL)
		car[stub] = stub
		captured_displays = cons(stub, captured_displays)
		clean_env()
		v = eval(y, x)
		restore_env()
		turing_machine_tapes = cdr[turing_machine_tapes]
		display_enabled = cdr[display_enabled]
		stub = cdr[car[captured_displays]]
		captured_displays = cdr[captured_displays]

		if old_try_has_smaller_time_limit != 0 && v == -wrd_out_of_time {
			return v
		}
		if v < 0 {
			return cons(wrd_failure, cons(-v, cons(stub, NIL)))
		}
		return cons(wrd_success, cons(v, cons(stub, NIL)))
	}

	if car[f] == wrd_lambda {
		f = cdr[f]
		vars = car[f]
		f = cdr[f]
		body = car[f]

		bind(vars, args)
		v = eval(body, d)

		for atom[vars] == 0 {
			var_ = car[vars]
			if atom[var_] != 0 {
				vlst[var_] = cdr[vlst[var_]]
			}
			vars = cdr[vars]
		}
		return v
	}

	return f
}

func clean_env() {
	o := obj_lst
	var var_ int
	for o != NIL {
		var_ = car[o]
		vlst[var_] = cons(var_, vlst[var_])
		o = cdr[o]
	}
	car[vlst[wrd_nil]] = NIL
}

func restore_env() {
	o := obj_lst
	var var_ int
	for o != NIL {
		var_ = car[o]
		if cdr[vlst[var_]] != NIL {
			vlst[var_] = cdr[vlst[var_]]
		}
		o = cdr[o]
	}
}

func bind(vars, args int) {
	var var_ int
	if atom[vars] != 0 {
		return
	}
	bind(cdr[vars], cdr[args])
	var_ = car[vars]
	if atom[var_] != 0 {
		vlst[var_] = cons(car[args], vlst[var_])
	}
}

func evalst(e, d int) int {
	var x, y int
	if e == NIL {
		return NIL
	}
	x = eval(car[e], d)
	if x < 0 {
		return x
	}
	y = evalst(cdr[e], d)
	if y < 0 {
		return y
	}
	return cons(x, y)
}

func append_list(x, y int) int {
	if x == NIL {
		return y
	}
	return cons(car[x], append_list(cdr[x], y))
}

func eq(x, y int) int {
	if x == y {
		return 1
	}
	if numb[x] != 0 && numb[y] != 0 {
		return eq_wrd(pname[x], pname[y])
	}
	if numb[x] != 0 || numb[y] != 0 {
		return 0
	}
	if atom[x] != 0 || atom[y] != 0 {
		return 0
	}
	if eq(car[x], car[y]) != 0 {
		return eq(cdr[x], cdr[y])
	}
	return 0
}

func length(x int) int {
	if atom[x] != 0 {
		return NIL
	}
	return add1(length(cdr[x]))
}

func compare(x, y int) int {
	var already_decided, digit1, digit2 int
	if x == NIL && y == NIL {
		return '='
	}
	if x == NIL && y != NIL {
		return '<'
	}
	if x != NIL && y == NIL {
		return '>'
	}
	already_decided = compare(cdr[x], cdr[y])
	if already_decided != '=' {
		return already_decided
	}
	digit1 = car[x]
	digit2 = car[y]
	if digit1 < digit2 {
		return '<'
	}
	if digit1 > digit2 {
		return '>'
	}
	return '='
}

func add1(x int) int {
	var digit int
	if x == NIL {
		return cons('1', NIL)
	}
	digit = car[x]
	if digit != '9' {
		return cons(digit+1, cdr[x])
	}
	return cons('0', add1(cdr[x]))
}

func sub1(x int) int {
	var digit int
	if x == NIL {
		return x
	}
	digit = car[x]
	if digit == '1' && cdr[x] == NIL {
		return NIL
	}
	if digit != '0' {
		return cons(digit-1, cdr[x])
	}
	return cons('9', sub1(cdr[x]))
}

func nmb(x int) int {
	if numb[x] != 0 {
		return pname[x]
	}
	return NIL
}

func remove_leading_zeros(x int) int {
	var rest, digit int
	if x == NIL {
		return NIL
	}
	digit = car[x]
	rest = remove_leading_zeros(cdr[x])
	if rest == NIL && digit == '0' {
		return NIL
	}
	return cons(digit, rest)
}

func addition(x, y, carry_in int) int {
	var sum, digit1, digit2, rest1, rest2 int
	if x == NIL && carry_in == 0 {
		return y
	}
	if y == NIL && carry_in == 0 {
		return x
	}
	if x != NIL {
		digit1 = car[x]
		rest1 = cdr[x]
	} else {
		digit1 = '0'
		rest1 = NIL
	}
	if y != NIL {
		digit2 = car[y]
		rest2 = cdr[y]
	} else {
		digit2 = '0'
		rest2 = NIL
	}
	sum = digit1 + digit2 + carry_in - '0'
	if sum <= '9' {
		return cons(sum, addition(rest1, rest2, 0))
	}
	return cons(sum-10, addition(rest1, rest2, 1))
}

func subtraction(x, y, borrow_in int) int {
	var difference, digit1, digit2, rest1, rest2 int
	if y == NIL && borrow_in == 0 {
		return x
	}
	if x != NIL {
		digit1 = car[x]
		rest1 = cdr[x]
	} else {
		digit1 = '0'
		rest1 = NIL
	}
	if y != NIL {
		digit2 = car[y]
		rest2 = cdr[y]
	} else {
		digit2 = '0'
		rest2 = NIL
	}
	difference = digit1 - digit2 - borrow_in + '0'
	if difference >= '0' {
		return cons(difference, subtraction(rest1, rest2, 0))
	}
	return cons(difference+10, subtraction(rest1, rest2, 1))
}

func multiplication(x, y int) int {
	sum := NIL
	if y == NIL {
		return NIL
	}
	for x != NIL {
		digit := car[x]
		x = cdr[x]
		for digit > '0' {
			sum = addition(sum, y, 0)
			digit--
		}
		y = cons('0', y)
	}
	return sum
}

func exponentiation(base, exponent int) int {
	product := cons('1', NIL)
	for exponent != NIL {
		product = multiplication(base, product)
		exponent = sub1(exponent)
	}
	return product
}

// --- Tape & Main ---

func base2_to_10(x int) int {
	result := NIL
	for atom[x] == 0 {
		next_bit := car[x]
		x = cdr[x]
		if numb[next_bit] == 0 || pname[next_bit] != NIL {
			next_bit = 1
		} else {
			next_bit = 0
		}
		result = addition(result, result, next_bit)
	}
	return result
}

func halve(x int) int {
	var digit, next_digit, rest, halve_digit int
	if x == NIL {
		return x
	}
	digit = car[x] - '0'
	x = cdr[x]
	rest = halve(x)
	if x == NIL {
		next_digit = 0
	} else {
		next_digit = car[x] - '0'
	}
	next_digit = next_digit % 2
	halve_digit = '0' + (digit / 2) + (5 * next_digit)
	if halve_digit != '0' || rest != NIL {
		return cons(halve_digit, rest)
	}
	return NIL
}

func base10_to_2(x int) int {
	bits := NIL
	for x != NIL {
		digit := car[x] - '0'
		bitVal := wrd_zero
		if digit%2 != 0 {
			bitVal = wrd_one
		}
		bits = cons(bitVal, bits)
		x = halve(x)
	}
	return bits
}

func size(x int) int {
	sum := NIL
	if numb[x] != 0 && pname[x] == NIL {
		return add1(NIL)
	}
	if atom[x] != 0 {
		return length(pname[x])
	}
	for atom[x] == 0 {
		sum = addition(sum, size(car[x]), 0)
		x = cdr[x]
		if atom[x] == 0 {
			sum = add1(sum)
		}
	}
	return add1(add1(sum))
}

func read_bit() int {
	var x int
	tape := car[turing_machine_tapes]
	if atom[tape] != 0 {
		return -wrd_out_of_data
	}
	x = car[tape]
	car[turing_machine_tapes] = cdr[tape]
	if numb[x] == 0 || pname[x] != NIL {
		return wrd_one
	}
	return wrd_zero
}

func write_chr(x int) {
	val := wrd_zero
	if x&128 != 0 {
		val = wrd_one
	}
	new_node := cons(val, NIL)
	cdr[q] = new_node
	q = new_node

	val = wrd_zero
	if x&64 != 0 {
		val = wrd_one
	}
	new_node = cons(val, NIL)
	cdr[q] = new_node
	q = new_node
	val = wrd_zero
	if x&32 != 0 {
		val = wrd_one
	}
	new_node = cons(val, NIL)
	cdr[q] = new_node
	q = new_node
	val = wrd_zero
	if x&16 != 0 {
		val = wrd_one
	}
	new_node = cons(val, NIL)
	cdr[q] = new_node
	q = new_node
	val = wrd_zero
	if x&8 != 0 {
		val = wrd_one
	}
	new_node = cons(val, NIL)
	cdr[q] = new_node
	q = new_node
	val = wrd_zero
	if x&4 != 0 {
		val = wrd_one
	}
	new_node = cons(val, NIL)
	cdr[q] = new_node
	q = new_node
	val = wrd_zero
	if x&2 != 0 {
		val = wrd_one
	}
	new_node = cons(val, NIL)
	cdr[q] = new_node
	q = new_node
	val = wrd_zero
	if x&1 != 0 {
		val = wrd_one
	}
	new_node = cons(val, NIL)
	cdr[q] = new_node
	q = new_node
}

func write_lst(x int) {
	if numb[x] != 0 && pname[x] == NIL {
		write_chr('0')
		return
	}
	if atom[x] != 0 {
		write_atm(pname[x])
		return
	}
	write_chr('(')
	for atom[x] == 0 {
		write_lst(car[x])
		x = cdr[x]
		if atom[x] == 0 {
			write_chr(' ')
		}
	}
	write_chr(')')
}

func write_atm(x int) {
	if x == NIL {
		return
	}
	write_atm(cdr[x])
	write_chr(car[x])
}

func read_char() int {
	c := 0
	i := 8
	for i > 0 {
		i--
		b := read_bit()
		if b < 0 {
			return b
		}
		if pname[b] != NIL {
			b = 1
		} else {
			b = 0
		}
		c = c + c + b
	}
	return c
}

func read_record() int {
	var character, word, line, end_of_line, end_of_buffer int
	line = cons(NIL, NIL)
	end_of_line = line
	for {
		character = read_char()
		if character < 0 {
			return character
		}
		new_node := cons(character, NIL)
		cdr[end_of_line] = new_node
		end_of_line = new_node
		if character == '\n' {
			break
		}
	}
	line = cdr[line]

	buffer2 = cons(NIL, NIL)
	end_of_buffer = buffer2
	word = NIL

	for line != NIL {
		character = car[line]
		line = cdr[line]
		if character == ' ' || character == '\n' || character == '(' || character == ')' {
			if word != NIL {
				new_node := cons(word, NIL)
				cdr[end_of_buffer] = new_node
				end_of_buffer = new_node
			}
			word = NIL
			if character != ' ' && character != '\n' {
				new_node := cons(cons(character, NIL), NIL)
				cdr[end_of_buffer] = new_node
				end_of_buffer = new_node
			}
		} else {
			if 32 < character && character < 127 {
				word = cons(character, word)
			}
		}
	}
	buffer2 = cdr[buffer2]
	return 0
}

func read_word() int {
	var word int
	if buffer2 == NIL {
		return right_paren
	}
	word = car[buffer2]
	buffer2 = cdr[buffer2]
	if only_digits(word) != 0 {
		word = mk_numb(remove_leading_zeros(word))
	} else {
		word = lookup_word(word)
	}
	return word
}

func read_expr(rparenokay int) int {
	var w, first, last, next int
	w = read_word()
	if w < 0 {
		return w
	}
	if w == right_paren {
		if rparenokay != 0 {
			return w
		} else {
			return NIL
		}
	}
	if w == left_paren {
		first = cons(NIL, NIL)
		last = first
		for {
			next = read_expr(1)
			if next == right_paren {
				break
			}
			if next < 0 {
				return next
			}
			new_node := cons(next, NIL)
			cdr[last] = new_node
			last = new_node
		}
		return cdr[first]
	}
	return w
}

func main() {
	reader = bufio.NewReader(os.Stdin)
	fmt.Printf("LISP Interpreter Run\n")
	initialize_atoms()

	for {
		var e, f, name, def int
		fmt.Printf("\n")
		e = in(1, 0)
		fmt.Printf("\n")
		f = car[e]
		name = car[cdr[e]]
		def = car[cdr[cdr[e]]]

		if f == wrd_define {
			if atom[name] == 0 {
				var_list := cdr[name]
				name = car[name]
				def = cons(wrd_lambda, cons(var_list, cons(def, NIL)))
			}
			out("define", name)
			out("value", def)
			car[vlst[name]] = def
			continue
		}
		e = out("expression", e)
		e = out("value", ev(e))
	}
}
