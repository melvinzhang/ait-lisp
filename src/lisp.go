package main

import (
	"bufio"
	"fmt"
	"io"
	"math/big"
	"os"
)

// --- Constants ---

const (
	Size = 1000000
	Nil  = 0
)

const (
	PrimNone = iota
	PrimCar
	PrimCdr
	PrimCons
	PrimAtom
	PrimEq
	PrimDisplay
	PrimDebug
	PrimAppend
	PrimLength
	PrimLt
	PrimGt
	PrimLeq
	PrimGeq
	PrimPlus
	PrimTimes
	PrimPow
	PrimMinus
	Prim2To10
	Prim10To2
	PrimSize
	PrimReadBit
	PrimBits
	PrimReadExp
)

// --- Machine Definition ---

type SExp interface {
	isSExp()
}

type ConsNode struct {
	Car, Cdr int
}

func (n *ConsNode) isSExp() {}

type NumberNode struct {
	Value *big.Int
}

func (n *NumberNode) isSExp() {}

type AtomNode struct {
	Name, Value, PrimCode, PrimArgs int
}

func (n *AtomNode) isSExp() {}

type Machine struct {
	Nodes      []SExp
	ObjectList int

	SymNil, SymTrue, SymFalse, SymDefine, SymLet, SymLambda, SymQuote, SymIf int
	SymCar, SymCdr, SymCadr, SymCaddr, SymEval, SymTry                       int
	SymNoTimeLimit, SymOutOfTime, SymOutOfData, SymSuccess, SymFailure       int
	LeftBracket, RightBracket, LeftParen, RightParen, DoubleQuote            int
	SymZero, SymOne                                                          int
	SymReadExp, SymUtm                                                       int

	NextFree         int
	Col              int
	TimeEval         int
	Tapes            int
	DisplayEnabled   int
	CapturedDisplays int
	Q                int
	Buffer2          int
	InWordBuffer     int

	Reader *bufio.Reader
	Writer io.Writer
}

func NewMachine(r io.Reader, w io.Writer) *Machine {
	return &Machine{
		Nodes:        make([]SExp, Size),
		NextFree:     0,
		Col:          0,
		TimeEval:     0,
		Reader:       bufio.NewReader(r),
		Writer:       w,
		InWordBuffer: Nil,
	}
}

// --- Initialization & Allocation ---

func (m *Machine) Init() {
	if Nil != m.MkAtom(PrimNone, "()", 0) {
		fmt.Fprintf(m.Writer, "nil != 0\n")
		os.Exit(0)
	}
	m.SymNil = m.MkAtom(PrimNone, "nil", 0)
	m.SetCar(m.Value(m.SymNil), Nil)
	m.SymTrue = m.MkAtom(PrimNone, "true", 0)
	m.SymFalse = m.MkAtom(PrimNone, "false", 0)
	m.SymNoTimeLimit = m.MkAtom(PrimNone, "no-time-limit", 0)
	m.SymOutOfTime = m.MkAtom(PrimNone, "out-of-time", 0)
	m.SymOutOfData = m.MkAtom(PrimNone, "out-of-data", 0)
	m.SymSuccess = m.MkAtom(PrimNone, "success", 0)
	m.SymFailure = m.MkAtom(PrimNone, "failure", 0)
	m.SymDefine = m.MkAtom(PrimNone, "define", 3)
	m.SymLet = m.MkAtom(PrimNone, "let", 4)
	m.SymLambda = m.MkAtom(PrimNone, "lambda", 3)
	m.SymCadr = m.MkAtom(PrimNone, "cadr", 2)
	m.SymCaddr = m.MkAtom(PrimNone, "caddr", 2)
	m.SymUtm = m.MkAtom(PrimNone, "run-utm-on", 2)
	m.SymQuote = m.MkAtom(PrimNone, "'", 2)
	m.SymIf = m.MkAtom(PrimNone, "if", 4)
	m.SymCar = m.MkAtom(PrimCar, "car", 2)
	m.SymCdr = m.MkAtom(PrimCdr, "cdr", 2)
	m.MkAtom(PrimCons, "cons", 3)
	m.MkAtom(PrimAtom, "atom", 2)
	m.MkAtom(PrimEq, "=", 3)
	m.MkAtom(PrimDisplay, "display", 2)
	m.MkAtom(PrimDebug, "debug", 2)
	m.MkAtom(PrimAppend, "append", 3)
	m.MkAtom(PrimLength, "length", 2)
	m.MkAtom(PrimLt, "<", 3)
	m.MkAtom(PrimGt, ">", 3)
	m.MkAtom(PrimLeq, "<=", 3)
	m.MkAtom(PrimGeq, ">=", 3)
	m.MkAtom(PrimPlus, "+", 3)
	m.MkAtom(PrimTimes, "*", 3)
	m.MkAtom(PrimPow, "^", 3)
	m.MkAtom(PrimMinus, "-", 3)
	m.MkAtom(Prim2To10, "base2-to-10", 2)
	m.MkAtom(Prim10To2, "base10-to-2", 2)
	m.MkAtom(PrimSize, "size", 2)
	m.MkAtom(PrimReadBit, "read-bit", 1)
	m.MkAtom(PrimBits, "bits", 2)
	m.SymReadExp = m.MkAtom(PrimReadExp, "read-exp", 1)
	m.SymEval = m.MkAtom(PrimNone, "eval", 2)
	m.SymTry = m.MkAtom(PrimNone, "try", 4)
	m.LeftBracket = m.MkAtom(PrimNone, "[", 0)
	m.RightBracket = m.MkAtom(PrimNone, "]", 0)
	m.LeftParen = m.MkAtom(PrimNone, "(", 0)
	m.RightParen = m.MkAtom(PrimNone, ")", 0)
	m.DoubleQuote = m.MkAtom(PrimNone, "\"", 0)
	m.SymZero = m.MkNum(big.NewInt(0))
	m.SymOne = m.MkNum(big.NewInt(1))
}

func (m *Machine) alloc() int {
	if m.NextFree >= Size {
		fmt.Fprintf(m.Writer, "Storage overflow!\n")
		os.Exit(0)
	}
	a := m.NextFree
	m.NextFree++
	return a
}

func (m *Machine) MkAtom(number int, name string, args int) int {
	a := m.alloc()
	m.Nodes[a] = &AtomNode{
		Name:     m.MkString(name),
		PrimCode: number,
		PrimArgs: args,
	}
	m.SetValue(a, m.Cons(a, Nil))
	m.ObjectList = m.Cons(a, m.ObjectList)
	return a
}

func (m *Machine) MkNum(value *big.Int) int {
	a := m.alloc()
	m.Nodes[a] = &NumberNode{
		Value: new(big.Int).Set(value),
	}
	return a
}

func (m *Machine) ToBigInt(x int) *big.Int {
	if x == Nil {
		return big.NewInt(0)
	}
	if n, ok := m.Nodes[x].(*NumberNode); ok {
		return new(big.Int).Set(n.Value)
	}
	return big.NewInt(0)
}

func (m *Machine) ParseDecimal(x int) *big.Int {
	res := big.NewInt(0)
	p := x
	multiplier := big.NewInt(1)
	base := big.NewInt(10)
	for !m.IsAtom(p) {
		digit := int64(m.Car(p) - '0')
		term := new(big.Int).Mul(big.NewInt(digit), multiplier)
		res.Add(res, term)
		multiplier.Mul(multiplier, base)
		p = m.Cdr(p)
	}
	return res
}

func (m *Machine) MkString(p string) int {
	v := Nil
	for i := 0; i < len(p); i++ {
		v = m.Cons(int(p[i]), v)
	}
	return v
}

func (m *Machine) Cons(x, y int) int {
	if y != Nil && m.IsAtom(y) {
		return x
	}
	z := m.alloc()
	m.Nodes[z] = &ConsNode{
		Car: x,
		Cdr: y,
	}
	return z
}

// --- Accessors ---

func (m *Machine) Car(x int) int {
	switch n := m.Nodes[x].(type) {
	case *ConsNode:
		return n.Car
	default:
		return x
	}
}

func (m *Machine) Cdr(x int) int {
	switch n := m.Nodes[x].(type) {
	case *ConsNode:
		return n.Cdr
	default:
		return x
	}
}

func (m *Machine) SetCar(x, y int) {
	if n, ok := m.Nodes[x].(*ConsNode); ok {
		n.Car = y
	}
}

func (m *Machine) SetCdr(x, y int) {
	if n, ok := m.Nodes[x].(*ConsNode); ok {
		n.Cdr = y
	}
}

func (m *Machine) Value(x int) int {
	if n, ok := m.Nodes[x].(*AtomNode); ok {
		return n.Value
	}
	return Nil
}

func (m *Machine) SetValue(x, y int) {
	if n, ok := m.Nodes[x].(*AtomNode); ok {
		n.Value = y
	}
}

func (m *Machine) Name(x int) int {
	switch n := m.Nodes[x].(type) {
	case *NumberNode:
		return Nil
	case *AtomNode:
		return n.Name
	default:
		return Nil
	}
}

func (m *Machine) SetName(x, y int) {
	if n, ok := m.Nodes[x].(*AtomNode); ok {
		n.Name = y
	}
}

func (m *Machine) PrimCode(x int) int {
	if n, ok := m.Nodes[x].(*AtomNode); ok {
		return n.PrimCode
	}
	return PrimNone
}

func (m *Machine) PrimArgs(x int) int {
	if n, ok := m.Nodes[x].(*AtomNode); ok {
		return n.PrimArgs
	}
	return 0
}

func (m *Machine) IsAtom(x int) bool {
	switch m.Nodes[x].(type) {
	case *ConsNode:
		return false
	default:
		return true // Atoms and Numbers are both "atoms" in S-exp parlance
	}
}

func (m *Machine) IsNumber(x int) bool {
	switch m.Nodes[x].(type) {
	case *NumberNode:
		return true
	default:
		return false
	}
}

// --- Output ---

func (m *Machine) Print(label string, x int) int {
	fmt.Fprintf(m.Writer, "%-12s", label)
	m.Col = 0
	m.PrintList(x)
	fmt.Fprintf(m.Writer, "\n")
	return x
}

func (m *Machine) serialize(x int, out func(int)) {
	if m.IsNumber(x) {
		val := m.ToBigInt(x)
		if val.Sign() == 0 {
			out('0')
			return
		}
		s := val.String()
		for i := 0; i < len(s); i++ {
			out(int(s[i]))
		}
		return
	}
	if m.IsAtom(x) {
		m.serializeName(m.Name(x), out)
		return
	}
	out('(')
	for !m.IsAtom(x) {
		m.serialize(m.Car(x), out)
		x = m.Cdr(x)
		if !m.IsAtom(x) {
			out(' ')
		}
	}
	out(')')
}

func (m *Machine) serializeName(x int, out func(int)) {
	if x == Nil {
		return
	}
	m.serializeName(m.Cdr(x), out)
	out(m.Car(x))
}

func (m *Machine) PrintList(x int) {
	m.serialize(x, m.PrintChar)
}

func (m *Machine) WriteLisp(x int) {
	m.serialize(x, m.WriteChar)
}

func (m *Machine) PrintChar(x int) {
	if m.Col == 50 {
		fmt.Fprintf(m.Writer, "\n%-12s", " ")
		m.Col = 1
	} else {
		m.Col++
	}
	fmt.Fprintf(m.Writer, "%c", x)
}

// --- Utils ---

func (m *Machine) EqWord(x, y int) bool {
	if x == Nil {
		return y == Nil
	}
	if y == Nil {
		return false
	}
	if m.Car(x) != m.Car(y) {
		return false
	}
	return m.EqWord(m.Cdr(x), m.Cdr(y))
}

func (m *Machine) LookupWord(x int) int {
	i := m.ObjectList
	for !m.IsAtom(i) {
		if m.EqWord(m.Name(m.Car(i)), x) {
			return m.Car(i)
		}
		i = m.Cdr(i)
	}
	i = m.MkAtom(PrimNone, "", 0)
	m.SetName(i, x)
	return i
}

// --- IO Wrapper ---

func (m *Machine) GetChar() int {
	b, err := m.Reader.ReadByte()
	if err != nil {
		fmt.Fprintf(m.Writer, "End of LISP Run\n\nCalls to eval = %d\nCalls to cons = %d\n", m.TimeEval, m.NextFree)
		os.Exit(0)
	}
	return int(b)
}

// --- Parser ---

func (m *Machine) tokenizeLine(getChar func() int, isSeparator func(int) bool) int {
	line := m.Cons(Nil, Nil)
	endOfLine := line
	for {
		character := getChar()
		if character < 0 {
			return character
		}
		newNode := m.Cons(character, Nil)
		m.SetCdr(endOfLine, newNode)
		endOfLine = newNode
		if character == '\n' {
			break
		}
	}
	line = m.Cdr(line)

	tokens := m.Cons(Nil, Nil)
	endOfTokens := tokens
	word := Nil

	for line != Nil {
		character := m.Car(line)
		line = m.Cdr(line)
		if isSeparator(character) {
			if word != Nil {
				newNode := m.Cons(word, Nil)
				m.SetCdr(endOfTokens, newNode)
				endOfTokens = newNode
			}
			word = Nil
			if character != ' ' && character != '\n' {
				newNode := m.Cons(m.Cons(character, Nil), Nil)
				m.SetCdr(endOfTokens, newNode)
				endOfTokens = newNode
			}
		} else {
			if 32 < character && character < 127 {
				word = m.Cons(character, word)
			}
		}
	}
	return m.Cdr(tokens)
}

func (m *Machine) tokenToExpr(token int) int {
	if m.OnlyDigits(token) {
		return m.MkNum(m.ParseDecimal(token))
	}
	return m.LookupWord(token)
}

func (m *Machine) InWord2() int {
	for m.InWordBuffer == Nil {
		m.InWordBuffer = m.tokenizeLine(func() int {
			character := m.GetChar()
			fmt.Fprintf(m.Writer, "%c", character)
			return character
		}, func(character int) bool {
			return character == ' ' || character == '\n' || character == '(' ||
				character == ')' || character == '[' || character == ']' ||
				character == '\'' || character == '"'
		})
	}
	word := m.Car(m.InWordBuffer)
	m.InWordBuffer = m.Cdr(m.InWordBuffer)
	return m.tokenToExpr(word)
}

func (m *Machine) OnlyDigits(x int) bool {
	for x != Nil {
		digit := m.Car(x)
		if digit < '0' || digit > '9' {
			return false
		}
		x = m.Cdr(x)
	}
	return true
}

func (m *Machine) InWord() int {
	var w int
	for {
		w = m.InWord2()
		if w != m.LeftBracket {
			return w
		}
		for m.InWord() != m.RightBracket {
		}
	}
}

func (m *Machine) Read(mexp bool, rparenokay bool) int {
	var w, first, last, next, name, def, body, varLst, i int
	w = m.InWord()
	if w == m.RightParen {
		if rparenokay {
			return w
		}
		return Nil
	}
	if w == m.LeftParen {
		first = m.Cons(Nil, Nil)
		last = first
		for {
			next = m.Read(mexp, true)
			if next == m.RightParen {
				break
			}
			newNode := m.Cons(next, Nil)
			m.SetCdr(last, newNode)
			last = newNode
		}
		return m.Cdr(first)
	}
	if !mexp {
		return w
	}
	if w == m.DoubleQuote {
		return m.Read(false, false)
	}
	if w == m.SymCadr {
		sexp := m.Read(true, false)
		sexp = m.Cons(m.SymCdr, m.Cons(sexp, Nil))
		return m.Cons(m.SymCar, m.Cons(sexp, Nil))
	}
	if w == m.SymCaddr {
		sexp := m.Read(true, false)
		sexp = m.Cons(m.SymCdr, m.Cons(sexp, Nil))
		sexp = m.Cons(m.SymCdr, m.Cons(sexp, Nil))
		return m.Cons(m.SymCar, m.Cons(sexp, Nil))
	}
	if w == m.SymUtm {
		sexp := m.Read(true, false)
		sexp = m.Cons(sexp, Nil)
		sexp = m.Cons(m.Cons(m.SymQuote, m.Cons(m.Cons(m.SymEval, m.Cons(m.Cons(m.SymReadExp, Nil), Nil)), Nil)), sexp)
		sexp = m.Cons(m.SymTry, m.Cons(m.SymNoTimeLimit, sexp))
		sexp = m.Cons(m.SymCdr, m.Cons(sexp, Nil))
		sexp = m.Cons(m.SymCar, m.Cons(sexp, Nil))
		return sexp
	}
	if w == m.SymLet {
		name = m.Read(true, false)
		def = m.Read(true, false)
		body = m.Read(true, false)
		if !m.IsAtom(name) {
			varLst = m.Cdr(name)
			name = m.Car(name)
			def = m.Cons(m.SymQuote, m.Cons(m.Cons(m.SymLambda, m.Cons(varLst, m.Cons(def, Nil))), Nil))
		}
		return m.Cons(m.Cons(m.SymQuote, m.Cons(m.Cons(m.SymLambda, m.Cons(m.Cons(name, Nil), m.Cons(body, Nil))), Nil)), m.Cons(def, Nil))
	}
	i = m.PrimArgs(w)
	if i == 0 {
		return w
	}
	first = m.Cons(w, Nil)
	last = first
	i--
	for i > 0 {
		newNode := m.Cons(m.Read(true, false), Nil)
		m.SetCdr(last, newNode)
		last = newNode
		i--
	}
	return first
}

// --- Evaluator ---

func (m *Machine) Ev(e int) int {
	m.Tapes = m.Cons(Nil, Nil)
	m.DisplayEnabled = m.Cons(1, Nil)
	m.CapturedDisplays = m.Cons(Nil, Nil)
	v := m.Eval(e, m.SymNoTimeLimit)
	if v < 0 {
		return -v
	}
	return v
}

func (m *Machine) Eval(e, d int) int {
	var f, v, args, x, y, z int

	m.TimeEval++

	if m.IsNumber(e) {
		return e
	}
	if m.IsAtom(e) {
		return m.Car(m.Value(e))
	}
	if m.Car(e) == m.SymLambda {
		return e
	}

	f = m.Eval(m.Car(e), d)
	e = m.Cdr(e)
	if f < 0 {
		return f
	}

	if f == m.SymQuote {
		return m.Car(e)
	}

	if f == m.SymIf {
		v = m.Eval(m.Car(e), d)
		e = m.Cdr(e)
		if v < 0 {
			return v
		}
		if v == m.SymFalse {
			e = m.Cdr(e)
		}
		return m.Eval(m.Car(e), d)
	}

	args = m.EvalSt(e, d)
	if args < 0 {
		return args
	}

	x = m.Car(args)
	y = m.Car(m.Cdr(args))
	z = m.Car(m.Cdr(m.Cdr(args)))

	switch m.PrimCode(f) {
	case PrimCar:
		return m.Car(x)
	case PrimCdr:
		return m.Cdr(x)
	case PrimCons:
		return m.Cons(x, y)
	case PrimAtom:
		if m.IsAtom(x) {
			return m.SymTrue
		}
		return m.SymFalse
	case PrimEq:
		if m.Eq(x, y) {
			return m.SymTrue
		}
		return m.SymFalse
	case PrimDisplay:
		if m.Car(m.DisplayEnabled) != 0 {
			return m.Print("display", x)
		}
		stubIdx := m.Car(m.CapturedDisplays)
		oldEnd := m.Car(stubIdx)
		newEnd := m.Cons(x, Nil)
		m.SetCdr(oldEnd, newEnd)
		m.SetCar(stubIdx, newEnd)
		return x
	case PrimDebug:
		return m.Print("debug", x)
	case PrimAppend:
		pX, pY := x, y
		if m.IsAtom(x) {
			pX = Nil
		}
		if m.IsAtom(y) {
			pY = Nil
		}
		return m.AppendList(pX, pY)
	case PrimLength:
		return m.Length(x)
	case PrimLt:
		if m.Compare(m.ToNum(x), m.ToNum(y)) == '<' {
			return m.SymTrue
		}
		return m.SymFalse
	case PrimGt:
		if m.Compare(m.ToNum(x), m.ToNum(y)) == '>' {
			return m.SymTrue
		}
		return m.SymFalse
	case PrimLeq:
		cmp := m.Compare(m.ToNum(x), m.ToNum(y))
		if cmp == '<' || cmp == '=' {
			return m.SymTrue
		}
		return m.SymFalse
	case PrimGeq:
		cmp := m.Compare(m.ToNum(x), m.ToNum(y))
		if cmp == '>' || cmp == '=' {
			return m.SymTrue
		}
		return m.SymFalse
	case PrimPlus:
		return m.MkNum(m.Addition(m.ToNum(x), m.ToNum(y)))
	case PrimTimes:
		return m.MkNum(m.Multiplication(m.ToNum(x), m.ToNum(y)))
	case PrimPow:
		return m.MkNum(m.Exponentiation(m.ToNum(x), m.ToNum(y)))
	case PrimMinus:
		if m.Compare(m.ToNum(x), m.ToNum(y)) != '>' {
			return m.MkNum(big.NewInt(0))
		}
		return m.MkNum(m.Subtraction(m.ToNum(x), m.ToNum(y)))
	case Prim2To10:
		return m.MkNum(m.Base2To10(x))
	case Prim10To2:
		return m.Base10To2(m.ToNum(x))
	case PrimSize:
		return m.MkNum(m.Size(x))
	case PrimReadBit:
		return m.ReadBit()
	case PrimBits:
		v = m.Cons(Nil, Nil)
		m.Q = v
		m.WriteLisp(x)
		m.WriteChar('\n')
		return m.Cdr(v)
	case PrimReadExp:
		v = m.ReadRecord()
		if v < 0 {
			return v
		}
		return m.ReadExpr(false)
	}

	if d != m.SymNoTimeLimit {
		if m.ToBigInt(d).Sign() == 0 {
			return -m.SymOutOfTime
		}
		d = m.MkNum(m.Sub1(d))
	}

	if f == m.SymEval {
		m.CleanEnv()
		v = m.Eval(x, d)
		m.RestoreEnv()
		return v
	}

	if f == m.SymTry {
		var stub int
		isSmallLimit := false
		if x != m.SymNoTimeLimit {
			x = m.ToNum(x)
		}
		if x == m.SymNoTimeLimit || (d != m.SymNoTimeLimit && m.Compare(x, d) != '<') {
			isSmallLimit = true
			x = d
		}
		m.Tapes = m.Cons(z, m.Tapes)
		m.DisplayEnabled = m.Cons(0, m.DisplayEnabled)
		stub = m.Cons(0, Nil)
		m.SetCar(stub, stub)
		m.CapturedDisplays = m.Cons(stub, m.CapturedDisplays)
		m.CleanEnv()
		v = m.Eval(y, x)
		m.RestoreEnv()
		m.Tapes = m.Cdr(m.Tapes)
		m.DisplayEnabled = m.Cdr(m.DisplayEnabled)
		stubIdx := m.Car(m.CapturedDisplays)
		m.CapturedDisplays = m.Cdr(m.CapturedDisplays)
		stub = m.Cdr(stubIdx)

		if isSmallLimit && v == -m.SymOutOfTime {
			return v
		}
		if v < 0 {
			return m.Cons(m.SymFailure, m.Cons(-v, m.Cons(stub, Nil)))
		}
		return m.Cons(m.SymSuccess, m.Cons(v, m.Cons(stub, Nil)))
	}

	if m.Car(f) == m.SymLambda {
		f = m.Cdr(f)
		vars := m.Car(f)
		f = m.Cdr(f)
		body := m.Car(f)

		m.Bind(vars, args)
		v = m.Eval(body, d)

		for !m.IsAtom(vars) {
			v_ := m.Car(vars)
			if m.IsAtom(v_) {
				m.SetValue(v_, m.Cdr(m.Value(v_)))
			}
			vars = m.Cdr(vars)
		}
		return v
	}

	return f
}

func (m *Machine) CleanEnv() {
	o := m.ObjectList
	for o != Nil {
		v_ := m.Car(o)
		m.SetValue(v_, m.Cons(v_, m.Value(v_)))
		o = m.Cdr(o)
	}
	m.SetCar(m.Value(m.SymNil), Nil)
}

func (m *Machine) RestoreEnv() {
	o := m.ObjectList
	for o != Nil {
		v_ := m.Car(o)
		if m.Cdr(m.Value(v_)) != Nil {
			m.SetValue(v_, m.Cdr(m.Value(v_)))
		}
		o = m.Cdr(o)
	}
}

func (m *Machine) Bind(vars, args int) {
	if m.IsAtom(vars) {
		return
	}
	m.Bind(m.Cdr(vars), m.Cdr(args))
	v_ := m.Car(vars)
	if m.IsAtom(v_) {
		m.SetValue(v_, m.Cons(m.Car(args), m.Value(v_)))
	}
}

func (m *Machine) EvalSt(e, d int) int {
	if e == Nil {
		return Nil
	}
	x := m.Eval(m.Car(e), d)
	if x < 0 {
		return x
	}
	y := m.EvalSt(m.Cdr(e), d)
	if y < 0 {
		return y
	}
	return m.Cons(x, y)
}

func (m *Machine) AppendList(x, y int) int {
	if x == Nil {
		return y
	}
	return m.Cons(m.Car(x), m.AppendList(m.Cdr(x), y))
}

func (m *Machine) Eq(x, y int) bool {
	if x == y {
		return true
	}
	if m.IsNumber(x) && m.IsNumber(y) {
		return m.Compare(x, y) == '='
	}
	if m.IsNumber(x) || m.IsNumber(y) {
		return false
	}
	if m.IsAtom(x) || m.IsAtom(y) {
		return false
	}
	if m.Eq(m.Car(x), m.Car(y)) {
		return m.Eq(m.Cdr(x), m.Cdr(y))
	}
	return false
}

func (m *Machine) Length(x int) int {
	return m.MkNum(m.BigLength(x))
}

func (m *Machine) Compare(x, y int) int {
	nx := m.ToBigInt(x)
	ny := m.ToBigInt(y)
	cmp := nx.Cmp(ny)
	if cmp < 0 {
		return '<'
	} else if cmp > 0 {
		return '>'
	}
	return '='
}

func (m *Machine) Add1(x int) *big.Int {
	nx := m.ToBigInt(x)
	nx.Add(nx, big.NewInt(1))
	return nx
}

func (m *Machine) Sub1(x int) *big.Int {
	nx := m.ToBigInt(x)
	if nx.Sign() <= 0 {
		return big.NewInt(0)
	}
	nx.Sub(nx, big.NewInt(1))
	return nx
}

func (m *Machine) ToNum(x int) int {
	if m.IsNumber(x) {
		return x
	}
	return Nil
}

func (m *Machine) Addition(x, y int) *big.Int {
	return new(big.Int).Add(m.ToBigInt(x), m.ToBigInt(y))
}

func (m *Machine) Subtraction(x, y int) *big.Int {
	return new(big.Int).Sub(m.ToBigInt(x), m.ToBigInt(y))
}

func (m *Machine) Multiplication(x, y int) *big.Int {
	return new(big.Int).Mul(m.ToBigInt(x), m.ToBigInt(y))
}

func (m *Machine) Exponentiation(base, exp int) *big.Int {
	return new(big.Int).Exp(m.ToBigInt(base), m.ToBigInt(exp), nil)
}

// --- Tape & Main ---

func (m *Machine) Base2To10(x int) *big.Int {
	res := big.NewInt(0)
	p := x
	for !m.IsAtom(p) {
		bit := m.Car(p)
		v := int64(1)
		if m.IsNumber(bit) && m.ToBigInt(bit).Sign() == 0 {
			v = 0
		}
		res.Mul(res, big.NewInt(2))
		res.Add(res, big.NewInt(v))
		p = m.Cdr(p)
	}
	return res
}

func (m *Machine) Base10To2(x int) int {
	nx := m.ToBigInt(x)
	if nx.Sign() == 0 {
		return Nil
	}
	bits := Nil
	temp := new(big.Int).Set(nx)
	for temp.Sign() > 0 {
		bit := m.SymZero
		if temp.Bit(0) == 1 {
			bit = m.SymOne
		}
		bits = m.Cons(bit, bits)
		temp.Rsh(temp, 1)
	}
	return bits
}

func (m *Machine) Size(x int) *big.Int {
	if m.IsNumber(x) {
		val := m.ToBigInt(x)
		s := val.String()
		return big.NewInt(int64(len(s)))
	}
	if m.IsAtom(x) {
		return m.BigLength(m.Name(x))
	}
	sum := big.NewInt(0)
	p := x
	for !m.IsAtom(p) {
		sum.Add(sum, m.Size(m.Car(p)))
		p = m.Cdr(p)
		if !m.IsAtom(p) {
			sum.Add(sum, big.NewInt(1))
		}
	}
	sum.Add(sum, big.NewInt(2))
	return sum
}

func (m *Machine) BigLength(x int) *big.Int {
	if m.IsAtom(x) {
		return big.NewInt(0)
	}
	res := big.NewInt(0)
	p := x
	for !m.IsAtom(p) {
		res.Add(res, big.NewInt(1))
		p = m.Cdr(p)
	}
	return res
}

func (m *Machine) ReadBit() int {
	t := m.Car(m.Tapes)
	if m.IsAtom(t) {
		return -m.SymOutOfData
	}
	bit := m.Car(t)
	m.SetCar(m.Tapes, m.Cdr(t))
	if m.IsNumber(bit) && m.ToBigInt(bit).Sign() == 0 {
		return m.SymZero
	}
	return m.SymOne
}

func (m *Machine) WriteChar(x int) {
	bits := [8]int{}
	for i := 0; i < 8; i++ {
		bits[7-i] = (x >> i) & 1
	}
	for _, b := range bits {
		v := m.SymZero
		if b == 1 {
			v = m.SymOne
		}
		node := m.Cons(v, Nil)
		m.SetCdr(m.Q, node)
		m.Q = node
	}
}

func (m *Machine) ReadChar() int {
	c := 0
	for i := 0; i < 8; i++ {
		b := m.ReadBit()
		if b < 0 {
			return b
		}
		v := 0
		if b != m.SymZero {
			v = 1
		}
		c = (c << 1) | v
	}
	return c
}

func (m *Machine) ReadRecord() int {
	tokens := m.tokenizeLine(m.ReadChar, func(c int) bool {
		return c == ' ' || c == '\n' || c == '(' || c == ')'
	})
	if tokens < 0 {
		return tokens
	}
	m.Buffer2 = tokens
	return 0
}

func (m *Machine) ReadWord() int {
	if m.Buffer2 == Nil {
		return m.RightParen
	}
	word := m.Car(m.Buffer2)
	m.Buffer2 = m.Cdr(m.Buffer2)
	return m.tokenToExpr(word)
}

func (m *Machine) ReadExpr(rparen bool) int {
	w := m.ReadWord()
	if w < 0 {
		return w
	}
	if w == m.RightParen {
		if rparen {
			return w
		}
		return Nil
	}
	if w == m.LeftParen {
		first := m.Cons(Nil, Nil)
		last := first
		for {
			next := m.ReadExpr(true)
			if next == m.RightParen {
				break
			}
			if next < 0 {
				return next
			}
			node := m.Cons(next, Nil)
			m.SetCdr(last, node)
			last = node
		}
		return m.Cdr(first)
	}
	return w
}

func (m *Machine) Run() {
	fmt.Fprintf(m.Writer, "LISP Interpreter Run\n")
	m.Init()

	for {
		fmt.Fprintf(m.Writer, "\n")
		e := m.Read(true, false)
		fmt.Fprintf(m.Writer, "\n")

		f := m.Car(e)
		if f == m.SymDefine {
			args := m.Cdr(e)
			name := m.Car(args)
			def := m.Car(m.Cdr(args))

			if !m.IsAtom(name) {
				varList := m.Cdr(name)
				sName := m.Car(name)
				newDef := m.Cons(m.SymLambda, m.Cons(varList, m.Cons(def, Nil)))
				m.Print("define", sName)
				m.Print("value", newDef)
				// define was setting the Value of the symbol.
				m.SetCar(m.Value(sName), newDef)
			} else {
				m.Print("define", name)
				m.Print("value", def)
				m.SetCar(m.Value(name), def)
			}
			continue
		}
		m.Print("expression", e)
		m.Print("value", m.Ev(e))
	}
}

func main() {
	m := NewMachine(os.Stdin, os.Stdout)
	m.Run()
}
