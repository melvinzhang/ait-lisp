// Lisp Interpreter in Go, ported from Java (G J Chaitin, 27 Dec 99)
package main

import (
	"fmt"
	"math/big"
	"os"
	"strings"
)

type Sexp struct {
	hd, tl *Sexp
	at, nmb, err bool
	pname string
	nval *big.Int
	vstk []*Sexp
}

func (l *Lisp) NewSexp(h, t *Sexp) *Sexp {
	l.cons_count++
	return &Sexp{
		at:    false,
		nmb:   false,
		hd:    h,
		tl:    t,
		pname: "",
		nval:  big.NewInt(0),
	}
}

func (l *Lisp) NewSexpAtom(s string) *Sexp {
	l.cons_count++
	z := &Sexp{
		at:    true,
		nmb:   false,
		pname: s,
		nval:  big.NewInt(0),
	}
	z.hd = z
	z.tl = z
	z.vstk = append(z.vstk, z)
	return z
}

func (l *Lisp) NewSexpNum(n *big.Int) *Sexp {
	l.cons_count++
	z := &Sexp{
		at:    true,
		nmb:   true,
		nval:  new(big.Int).Set(n),
		pname: n.String(),
	}
	z.hd = z
	z.tl = z
	z.vstk = append(z.vstk, z)
	return z
}

func (s *Sexp) two() *Sexp   { return s.tl.hd }
func (s *Sexp) three() *Sexp { return s.tl.tl.hd }
func (s *Sexp) four() *Sexp  { return s.tl.tl.tl.hd }

func (s *Sexp) bad() bool {
	if s.at {
		return s.pname == ")"
	}
	return s.hd.bad() || s.tl.bad()
}

func (s *Sexp) toS() string {
	var sb strings.Builder
	s.toS2(&sb, s)
	return sb.String()
}

func (s *Sexp) toS2(sb *strings.Builder, x *Sexp) {
	if x.at && x.pname != "" {
		sb.WriteString(x.pname)
		return
	}
	sb.WriteByte('(')
	for !x.at {
		s.toS2(sb, x.hd)
		x = x.tl
		if !x.at {
			sb.WriteByte(' ')
		}
	}
	sb.WriteByte(')')
}

type Lisp struct {
	infinity           int64
	buffer             string
	pos                int
	obj_lst            *Sexp
	nil_, nil2, true2, false2, one, zero, quote, dbl_quote, if_then_else, lambda, rparen, lparen, time_err, data_err, out_of_time, out_of_data, let, car, cdr, cadr, caddr, atom, cons, equal, fappend, feval, ftry, debug, size, length, display, read_bit, read_exp, was_read, run_utm_on, bits, plus, times, minus, to_the_power, leq, geq, lt, gt, success, failure, no_time_limit, base10_to_2, base2_to_10, define *Sexp

	binary_data_stk   []*Sexp
	binary_data_lst   *Sexp
	was_read_stk      []*Sexp
	was_read_lst      *Sexp
	was_displayed_stk []*Sexp
	was_displayed_lst *Sexp
	echo              strings.Builder
	eval_count        int64
	cons_count        int64
}

func NewLisp() *Lisp {
	l := &Lisp{
		infinity: 999999999999999999,
	}
	l.nil_ = l.mk_atom("")
	l.nil2 = l.mk_atom("nil")
	l.true2 = l.mk_atom("true")
	l.false2 = l.mk_atom("false")
	l.one = l.NewSexpNum(big.NewInt(1))
	l.zero = l.NewSexpNum(big.NewInt(0))
	l.quote = l.mk_atom("'")
	l.dbl_quote = l.mk_atom("\"")
	l.if_then_else = l.mk_atom("if")
	l.lambda = l.mk_atom("lambda")
	l.rparen = l.mk_atom(")")
	l.lparen = l.mk_atom("(")
	l.time_err = l.mk_atom("impossible atom 1")
	l.data_err = l.mk_atom("impossible atom 2")
	l.out_of_time = l.mk_atom("out-of-time")
	l.out_of_data = l.mk_atom("out-of-data")
	l.let = l.mk_atom("let")
	l.car = l.mk_atom("car")
	l.cdr = l.mk_atom("cdr")
	l.cadr = l.mk_atom("cadr")
	l.caddr = l.mk_atom("caddr")
	l.atom = l.mk_atom("atom")
	l.cons = l.mk_atom("cons")
	l.equal = l.mk_atom("=")
	l.fappend = l.mk_atom("append")
	l.feval = l.mk_atom("eval")
	l.ftry = l.mk_atom("try")
	l.debug = l.mk_atom("debug")
	l.size = l.mk_atom("size")
	l.length = l.mk_atom("length")
	l.display = l.mk_atom("display")
	l.read_bit = l.mk_atom("read-bit")
	l.read_exp = l.mk_atom("read-exp")
	l.was_read = l.mk_atom("was-read")
	l.run_utm_on = l.mk_atom("run-utm-on")
	l.bits = l.mk_atom("bits")
	l.plus = l.mk_atom("+")
	l.times = l.mk_atom("*")
	l.minus = l.mk_atom("-")
	l.to_the_power = l.mk_atom("^")
	l.leq = l.mk_atom("<=")
	l.geq = l.mk_atom(">=")
	l.lt = l.mk_atom("<")
	l.gt = l.mk_atom(">")
	l.success = l.mk_atom("success")
	l.failure = l.mk_atom("failure")
	l.no_time_limit = l.mk_atom("no-time-limit")
	l.base10_to_2 = l.mk_atom("base10-to-2")
	l.base2_to_10 = l.mk_atom("base2-to-10")
	l.define = l.mk_atom("define")

	l.time_err.err = true
	l.data_err.err = true

	l.nil2.vstk = l.nil2.vstk[:len(l.nil2.vstk)-1]
	l.nil2.vstk = append(l.nil2.vstk, l.nil_)

	l.binary_data_lst = l.nil_
	l.was_read_lst = l.nil_
	l.was_displayed_lst = l.nil_

	return l
}

func (l *Lisp) jn(x, y *Sexp) *Sexp {
	if y.at && y != l.nil_ {
		return x
	}
	return l.NewSexp(x, y)
}

func (l *Lisp) mk_atom(x string) *Sexp {
	o := l.obj_lst
	for o != nil {
		if o.hd.pname == x {
			return o.hd
		}
		o = o.tl
	}
	z := l.NewSexpAtom(x)
	l.obj_lst = l.NewSexp(z, l.obj_lst)
	return z
}

func (l *Lisp) append(x, y *Sexp) *Sexp {
	if x.at {
		return y
	}
	if y.at {
		return x
	}
	x = l.reverse(x)
	for !x.at {
		y = l.jn(x.hd, y)
		x = x.tl
	}
	return y
}

func (l *Lisp) evalst(x *Sexp, d int64) *Sexp {
	if x.at {
		return l.nil_
	}
	v := l.eval(x.hd, d)
	if v.err {
		return v
	}
	w := l.evalst(x.tl, d)
	if w.err {
		return w
	}
	return l.jn(v, w)
}

func (l *Lisp) push_env() {
	o := l.obj_lst
	for o != nil {
		o.hd.vstk = append(o.hd.vstk, o.hd)
		o = o.tl
	}
	l.nil2.vstk = l.nil2.vstk[:len(l.nil2.vstk)-1]
	l.nil2.vstk = append(l.nil2.vstk, l.nil_)
}

func (l *Lisp) pop_env() {
	o := l.obj_lst
	for o != nil {
		l.pop_vstk(o.hd)
		if len(o.hd.vstk) == 0 {
			o.hd.vstk = append(o.hd.vstk, o.hd)
		}
		o = o.tl
	}
}

func (l *Lisp) pop_vstk(s *Sexp) {
	if len(s.vstk) > 0 {
		s.vstk = s.vstk[:len(s.vstk)-1]
	}
}

func (l *Lisp) peek_vstk(s *Sexp) *Sexp {
	if len(s.vstk) == 0 {
		return s
	}
	return s.vstk[len(s.vstk)-1]
}

func (l *Lisp) eval(e *Sexp, d int64) *Sexp {
	l.eval_count++
	if e.at {
		return l.peek_vstk(e)
	}
	f := l.eval(e.hd, d)
	if f.err {
		return f
	}
	if f == l.quote {
		return e.two()
	}
	if f == l.if_then_else {
		p := l.eval(e.two(), d)
		if p.err {
			return p
		}
		if p == l.false2 {
			return l.eval(e.four(), d)
		}
		return l.eval(e.three(), d)
	}

	args := l.evalst(e.tl, d)
	if args.err {
		return args
	}
	x := args.hd
	y := args.two()
	z := args.three()
	var v *Sexp

	if f == l.debug {
		l.out("debug", x.toS())
		return x
	}

	if f == l.size {
		return l.NewSexpNum(big.NewInt(int64(len(x.toS()))))
	}

	if f == l.length {
		return l.NewSexpNum(big.NewInt(l.count(x)))
	}

	if f == l.display {
		if len(l.was_displayed_stk) == 0 {
			l.out("display", x.toS())
		} else {
			l.was_displayed_lst = l.jn(x, l.was_displayed_lst)
		}
		return x
	}

	if f == l.read_bit {
		return l.get_bit()
	}

	if f == l.read_exp {
		if l.new_line2() {
			return l.data_err
		}
		v = l.get_exp("()")
		if v == l.rparen {
			v = l.nil_
		}
		return v
	}

	if f == l.was_read {
		return l.reverse(l.was_read_lst)
	}

	if f == l.bits {
		return l.to_bits(x)
	}

	if f == l.atom {
		if x.at {
			return l.true2
		}
		return l.false2
	}

	if f == l.car {
		return x.hd
	}

	if f == l.cdr {
		return x.tl
	}

	if f == l.cons {
		return l.jn(x, y)
	}

	if f == l.equal {
		if l.eq(x, y) {
			return l.true2
		}
		return l.false2
	}

	if f == l.fappend {
		return l.append(x, y)
	}

	if f == l.plus {
		return l.NewSexpNum(new(big.Int).Add(x.nval, y.nval))
	}

	if f == l.minus {
		res := new(big.Int).Sub(x.nval, y.nval)
		if res.Sign() < 0 {
			res.SetInt64(0)
		}
		return l.NewSexpNum(res)
	}

	if f == l.times {
		return l.NewSexpNum(new(big.Int).Mul(x.nval, y.nval))
	}

	if f == l.leq {
		if x.nval.Cmp(y.nval) <= 0 {
			return l.true2
		}
		return l.false2
	}

	if f == l.lt {
		if x.nval.Cmp(y.nval) < 0 {
			return l.true2
		}
		return l.false2
	}

	if f == l.geq {
		if x.nval.Cmp(y.nval) >= 0 {
			return l.true2
		}
		return l.false2
	}

	if f == l.gt {
		if x.nval.Cmp(y.nval) > 0 {
			return l.true2
		}
		return l.false2
	}

	if f == l.to_the_power {
		return l.NewSexpNum(new(big.Int).Exp(x.nval, y.nval, nil))
	}

	if f == l.base10_to_2 {
		return l.to_base2(x.nval)
	}

	if f == l.base2_to_10 {
		return l.NewSexpNum(l.to_base10(x))
	}

	if d == 0 {
		return l.time_err
	}
	d = d - 1

	if f == l.feval {
		l.push_env()
		v = l.eval(x, d)
		l.pop_env()
		return v
	}

	if f == l.ftry {
		l.binary_data_stk = append(l.binary_data_stk, l.binary_data_lst)
		l.binary_data_lst = z
		l.was_read_stk = append(l.was_read_stk, l.was_read_lst)
		l.was_read_lst = l.nil_
		l.was_displayed_stk = append(l.was_displayed_stk, l.was_displayed_lst)
		l.was_displayed_lst = l.nil_

		xx := x.nval.Int64()
		if x.nval.Cmp(big.NewInt(l.infinity)) > 0 {
			xx = l.infinity
		}
		if x == l.no_time_limit {
			xx = l.infinity
		}

		l.push_env()
		if xx < d {
			v = l.eval(y, xx)
		} else {
			v = l.eval(y, d)
		}
		l.pop_env()

		displayed := l.reverse(l.was_displayed_lst)
		l.binary_data_lst = l.binary_data_stk[len(l.binary_data_stk)-1]
		l.binary_data_stk = l.binary_data_stk[:len(l.binary_data_stk)-1]
		l.was_read_lst = l.was_read_stk[len(l.was_read_stk)-1]
		l.was_read_stk = l.was_read_stk[:len(l.was_read_stk)-1]
		l.was_displayed_lst = l.was_displayed_stk[len(l.was_displayed_stk)-1]
		l.was_displayed_stk = l.was_displayed_stk[:len(l.was_displayed_stk)-1]

		if v == l.data_err {
			return l.jn(l.failure, l.jn(l.out_of_data, l.jn(displayed, l.nil_)))
		}
		if v != l.time_err {
			return l.jn(l.success, l.jn(v, l.jn(displayed, l.nil_)))
		}
		if xx < d {
			return l.jn(l.failure, l.jn(l.out_of_time, l.jn(displayed, l.nil_)))
		} else {
			return l.time_err
		}
	}

	vars := f.two()
	body := f.three()
	l.bind(vars, args)
	v = l.eval(body, d)
	l.unbind(vars)
	return v
}

func (l *Lisp) bind(vars, args *Sexp) {
	if vars.at {
		return
	}
	l.bind(vars.tl, args.tl)
	if vars.hd.at && !vars.hd.nmb {
		vars.hd.vstk = append(vars.hd.vstk, args.hd)
	}
}

func (l *Lisp) unbind(vars *Sexp) {
	if vars.at {
		return
	}
	if vars.hd.at && !vars.hd.nmb {
		l.pop_vstk(vars.hd)
	}
	l.unbind(vars.tl)
}

func (l *Lisp) count(x *Sexp) int64 {
	var k int64 = 0
	for !x.at {
		k++
		x = x.tl
	}
	return k
}

func (l *Lisp) reverse(list *Sexp) *Sexp {
	v := l.nil_
	for !list.at {
		v = l.jn(list.hd, v)
		list = list.tl
	}
	return v
}

func (l *Lisp) eq(x, y *Sexp) bool {
	if x.nmb && y.nmb {
		return x.nval.Cmp(y.nval) == 0
	}
	if x.nmb || y.nmb {
		return false
	}
	if x.at && y.at {
		return x == y
	}
	if x.at || y.at {
		return false
	}
	return l.eq(x.hd, y.hd) && l.eq(x.tl, y.tl)
}

func (l *Lisp) get_lst() *Sexp {
	v := l.get()
	if v == l.rparen {
		return l.nil_
	}
	w := l.get_lst()
	return l.jn(v, w)
}

func (l *Lisp) next_token2(delimiters string) string {
	for {
		t := l.next_token(delimiters)
		if !strings.Contains(delimiters, "[") {
			return t
		}
		if t != "[" {
			return t
		}
		for {
			t = l.next_token2(delimiters)
			if t == "]" {
				break
			}
			if l.pos == len(l.buffer) && t == ")" {
				return t
			}
		}
	}
}

func (l *Lisp) get() *Sexp {
	t := l.next_token2("()[]'\"")
	var a *Sexp
	if !l.is_nval(t) {
		a = l.mk_atom(t)
	} else {
		n := new(big.Int)
		n.SetString(t, 10)
		a = l.NewSexpNum(n)
	}

	if a == l.lparen {
		return l.get_lst()
	}

	if a == l.read_bit || a == l.read_exp || a == l.was_read {
		return l.jn(a, l.nil_)
	}

	if a == l.dbl_quote {
		return l.get_exp("()[]'\"")
	}

	if a == l.quote || a == l.atom || a == l.car || a == l.cdr || a == l.display || a == l.debug || a == l.size || a == l.length || a == l.base10_to_2 || a == l.base2_to_10 || a == l.feval || a == l.bits {
		return l.jn(a, l.jn(l.get(), l.nil_))
	}

	if a == l.cons || a == l.equal || a == l.plus || a == l.minus || a == l.times || a == l.to_the_power || a == l.leq || a == l.geq || a == l.lt || a == l.gt || a == l.define || a == l.fappend || a == l.lambda {
		return l.jn(a, l.jn(l.get(), l.jn(l.get(), l.nil_)))
	}

	if a == l.if_then_else || a == l.ftry {
		return l.jn(a, l.jn(l.get(), l.jn(l.get(), l.jn(l.get(), l.nil_))))
	}

	if a == l.run_utm_on {
		v := l.get()
		v = l.jn(l.ftry,
			l.jn(l.no_time_limit,
				l.jn(l.jn(l.quote,
					l.jn(l.jn(l.feval,
						l.jn(l.jn(l.read_exp, l.nil_),
							l.nil_)),
						l.nil_)),
				l.jn(v,
						l.nil_))))
		v = l.jn(l.cdr, l.jn(v, l.nil_))
		v = l.jn(l.car, l.jn(v, l.nil_))
		return v
	}

	if a == l.cadr {
		v := l.get()
		v = l.jn(l.cdr, l.jn(v, l.nil_))
		v = l.jn(l.car, l.jn(v, l.nil_))
		return v
	}

	if a == l.caddr {
		v := l.get()
		v = l.jn(l.cdr, l.jn(v, l.nil_))
		v = l.jn(l.cdr, l.jn(v, l.nil_))
		v = l.jn(l.car, l.jn(v, l.nil_))
		return v
	}

	if a == l.let {
		x := l.get()
		v := l.get()
		e := l.get()
		if !x.at {
			v = l.jn(l.quote,
				l.jn(l.jn(l.lambda,
					l.jn(x.tl,
						l.jn(v, l.nil_))), l.nil_))
			x = x.hd
		}
		return l.jn(l.jn(l.quote,
			l.jn(l.jn(l.lambda,
					l.jn(l.jn(x, l.nil_),
						l.jn(e, l.nil_))), l.nil_)),
			l.jn(v, l.nil_))
	}

	return a
}

func (l *Lisp) is_nval(s string) bool {
	if s == "" {
		return false
	}
	for i := 0; i < len(s); i++ {
		d := s[i]
		if d < '0' || d > '9' {
			return false
		}
	}
	return true
}

func (l *Lisp) to_base10(s *Sexp) *big.Int {
	n := big.NewInt(0)
	for !s.at {
		n.Lsh(n, 1)
		if s.hd.pname != "0" {
			n.SetBit(n, 0, 1)
		}
		s = s.tl
	}
	return n
}

func (l *Lisp) to_base2(n *big.Int) *Sexp {
	s := l.nil_
	n2 := new(big.Int).Set(n)
	for n2.Sign() != 0 {
		if n2.Bit(0) != 0 {
			s = l.jn(l.one, s)
		} else {
			s = l.jn(l.zero, s)
		}
		n2.Rsh(n2, 1)
	}
	return s
}

func (l *Lisp) new_line2() bool {
	var str strings.Builder
	for {
		i := l.get_char()
		if i == -1 {
			return true
		}
		ch := byte(i)
		str.WriteByte(ch)
		if ch == '\n' {
			break
		}
	}
	l.buffer = str.String()
	l.pos = 0
	return false
}

func (l *Lisp) next_token(delimiters string) string {
	var token strings.Builder
	for {
		var ch byte
		if l.pos == len(l.buffer) {
			ch = ')'
		} else {
			ch = l.buffer[l.pos]
			l.pos++
		}
		l.echo.WriteByte(ch)
		if ch != 10 && (ch < 32 || ch >= 127) {
			continue
		}
		is_delimiter := strings.ContainsRune(delimiters, rune(ch))
		is_white_space := (ch == ' ' || ch == '\n')
		is_white_space_or_delimiter := (is_white_space || is_delimiter)
		if token.Len() == 0 {
			if is_white_space {
				continue
			}
			token.WriteByte(ch)
			if is_delimiter {
				break
			}
		} else {
			if !is_white_space_or_delimiter {
				token.WriteByte(ch)
			}
			if is_delimiter {
				l.pos--
				s := l.echo.String()
				l.echo.Reset()
				l.echo.WriteString(s[:len(s)-1])
			}
			if is_white_space_or_delimiter {
				break
			}
		}
	}
	return token.String()
}

func (l *Lisp) run(input string) {
	fmt.Println("LISP Interpreter Run")
	fmt.Println()
	l.buffer = input + "\n"
	l.pos = 0
	mexp_count := 0
	for {
		l.echo.Reset()
		s := l.get()

		if s == l.rparen && l.pos == len(l.buffer) {
			fmt.Printf("\nEnd of LISP Run\n\n")
			fmt.Printf("Calls to eval = %d\n", l.eval_count)
			fmt.Printf("Calls to cons = %d\n", l.cons_count)
			return
		}
		if mexp_count > 0 {
			fmt.Print("\n\n")
		}
		mexp_count++

		xxx := l.echo.String()
		for strings.HasPrefix(xxx, "\n") {
			xxx = xxx[1:]
		}
		for strings.HasSuffix(xxx, "\n") {
			xxx = xxx[:len(xxx)-1]
		}
		fmt.Println(xxx + "\n")

		if s.bad() {
			l.out("expression", s.toS())
			l.out("value", "syntax error!")
			continue
		}

		if s.hd == l.define {
			x := s.two()
			v := s.three()
			if !x.at {
				v = l.jn(l.lambda, l.jn(x.tl, l.jn(v, l.nil_)))
				x = x.hd
			}
			l.out("define", x.toS())
			l.out("value", v.toS())
			if x.at && !x.nmb {
				l.pop_vstk(x)
				x.vstk = append(x.vstk, v)
			}
			continue
		}

		l.out("expression", s.toS())
		save_buffer := l.buffer
		save_pos := l.pos
		v := l.eval(s, l.infinity)
		l.buffer = save_buffer
		l.pos = save_pos
		if v == l.data_err {
			l.out("value", "out of data!")
		} else {
			l.out("value", v.toS())
		}
	}
}

func (l *Lisp) get_bit() *Sexp {
	if l.binary_data_lst.at {
		return l.data_err
	}
	v := l.binary_data_lst.hd
	l.binary_data_lst = l.binary_data_lst.tl
	if v.pname != "0" {
		v = l.one
	}
	l.was_read_lst = l.jn(v, l.was_read_lst)
	return v
}

func (l *Lisp) to_bits(x *Sexp) *Sexp {
	str := x.toS() + "\n"
	v := l.nil_
	for i := len(str) - 1; i >= 0; i-- {
		j := int(str[i])
		for k := 0; k < 8; k++ {
			if (j % 2) != 0 {
				v = l.jn(l.one, v)
			} else {
				v = l.jn(l.zero, v)
			}
			j = j >> 1
		}
	}
	return v
}

func (l *Lisp) get_char() int {
	v := 0
	for k := 0; k < 8; k++ {
		b := l.get_bit()
		if b.err {
			return -1
		}
		v = v << 1
		if b == l.one {
			v = v + 1
		}
	}
	return v
}

func (l *Lisp) get_list(delimiters string) *Sexp {
	v := l.get_exp(delimiters)
	if v == l.rparen {
		return l.nil_
	}
	w := l.get_list(delimiters)
	return l.jn(v, w)
}

func (l *Lisp) get_exp(delimiters string) *Sexp {
	t := l.next_token2(delimiters)
	var a *Sexp
	if !l.is_nval(t) {
		a = l.mk_atom(t)
	} else {
		n := new(big.Int)
		n.SetString(t, 10)
		a = l.NewSexpNum(n)
	}
	if a == l.lparen {
		return l.get_list(delimiters)
	}
	return a
}

func (l *Lisp) out(xx, yy string) {
	x := xx
	y := yy
	for len(y) > 0 {
		left := fmt.Sprintf("%-" + "12s", x)
		right := ""
		if len(y) <= 50 {
			right = y
			y = ""
		} else {
			right = y[:50]
			y = y[50:]
		}
		fmt.Printf("%s%s\n", left, right)
		x = ""
	}
}

func main() {
	l := NewLisp()
	// Read from stdin if no arguments, or from file
	var input []byte
	var err error
	if len(os.Args) > 1 {
		input, err = os.ReadFile(os.Args[1])
	} else {
		// Simple REPL or wait for input
		// For line-by-line port equivalence, we'll just read all stdin
		// but typically we'd read line by line.
		// Chaitin's lisp.java expects a buffer of M-exps.
		input, err = os.ReadFile("/dev/stdin")
	}
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		return
	}
	l.run(string(input))
}
