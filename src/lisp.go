package main

import (
	"bufio"
	"fmt"
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

// --- Structs ---

type Node struct {
	Car, Cdr int
	IsAtom   bool
	IsNumb   bool
	Value    int
	Name     int
	PrimCode int
	PrimArgs int
}

type Machine struct {
	Nodes []Node

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
}

func NewMachine() *Machine {
	return &Machine{
		Nodes:        make([]Node, Size),
		NextFree:     0,
		Col:          0,
		TimeEval:     0,
		Reader:       bufio.NewReader(os.Stdin),
		InWordBuffer: Nil,
	}
}

// --- Initialization & Allocation ---

func (m *Machine) Init() {
	if Nil != m.MkAtom(PrimNone, "()", 0) {
		fmt.Println("nil != 0")
		os.Exit(0)
	}
	m.SymNil = m.MkAtom(PrimNone, "nil", 0)
	m.Nodes[m.Nodes[m.SymNil].Value].Car = Nil
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
	m.SymZero = m.MkNum(Nil)
	m.SymOne = m.MkNum(m.Cons('1', Nil))
}

func (m *Machine) MkAtom(number int, name string, args int) int {
	a := m.Cons(Nil, Nil)
	m.Nodes[a].Car = a
	m.Nodes[a].Cdr = a
	m.Nodes[a].IsAtom = true
	m.Nodes[a].IsNumb = false
	m.Nodes[a].Name = m.MkString(name)
	m.Nodes[a].PrimCode = number
	m.Nodes[a].PrimArgs = args
	m.Nodes[a].Value = m.Cons(a, Nil)
	m.ObjectList = m.Cons(a, m.ObjectList)
	return a
}

func (m *Machine) MkNum(value int) int {
	a := m.Cons(Nil, Nil)
	m.Nodes[a].Car = a
	m.Nodes[a].Cdr = a
	m.Nodes[a].IsAtom = true
	m.Nodes[a].IsNumb = true
	m.Nodes[a].Name = value
	m.Nodes[a].PrimCode = PrimNone
	m.Nodes[a].PrimArgs = 0
	m.Nodes[a].Value = 0
	return a
}

func (m *Machine) MkString(p string) int {
	v := Nil
	for i := 0; i < len(p); i++ {
		v = m.Cons(int(p[i]), v)
	}
	return v
}

func (m *Machine) Cons(x, y int) int {
	if y != Nil && m.Nodes[y].IsAtom {
		return x
	}
	if m.NextFree >= Size {
		fmt.Println("Storage overflow!")
		os.Exit(0)
	}
	z := m.NextFree
	m.NextFree++
	m.Nodes[z] = Node{
		Car: x,
		Cdr: y,
	}
	return z
}

// --- Output ---

func (m *Machine) Print(label string, x int) int {
	fmt.Printf("%-12s", label)
	m.Col = 0
	m.PrintList(x)
	fmt.Printf("\n")
	return x
}

func (m *Machine) PrintList(x int) {
	if m.Nodes[x].IsNumb && m.Nodes[x].Name == Nil {
		m.PrintChar('0')
		return
	}
	if m.Nodes[x].IsAtom {
		m.PrintAtomName(m.Nodes[x].Name)
		return
	}
	m.PrintChar('(')
	for !m.Nodes[x].IsAtom {
		m.PrintList(m.Nodes[x].Car)
		x = m.Nodes[x].Cdr
		if !m.Nodes[x].IsAtom {
			m.PrintChar(' ')
		}
	}
	m.PrintChar(')')
}

func (m *Machine) PrintAtomName(x int) {
	if x == Nil {
		return
	}
	m.PrintAtomName(m.Nodes[x].Cdr)
	m.PrintChar(m.Nodes[x].Car)
}

func (m *Machine) PrintChar(x int) {
	if m.Col == 50 {
		fmt.Printf("\n%-12s", " ")
		m.Col = 1
	} else {
		m.Col++
	}
	fmt.Printf("%c", x)
}

// --- Utils ---

func (m *Machine) EqWord(x, y int) bool {
	if x == Nil {
		return y == Nil
	}
	if y == Nil {
		return false
	}
	if m.Nodes[x].Car != m.Nodes[y].Car {
		return false
	}
	return m.EqWord(m.Nodes[x].Cdr, m.Nodes[y].Cdr)
}

func (m *Machine) LookupWord(x int) int {
	i := m.ObjectList
	for !m.Nodes[i].IsAtom {
		if m.EqWord(m.Nodes[m.Nodes[i].Car].Name, x) {
			return m.Nodes[i].Car
		}
		i = m.Nodes[i].Cdr
	}
	i = m.MkAtom(PrimNone, "", 0)
	m.Nodes[i].Name = x
	return i
}

// --- IO Wrapper ---

func (m *Machine) GetChar() int {
	b, err := m.Reader.ReadByte()
	if err != nil {
		fmt.Printf("End of LISP Run\n\nCalls to eval = %d\nCalls to cons = %d\n", m.TimeEval, m.NextFree)
		os.Exit(0)
	}
	return int(b)
}

// --- Parser ---

func (m *Machine) InWord2() int {
	var character, word, line, endOfLine, endOfBuffer int
	for m.InWordBuffer == Nil {
		line = m.Cons(Nil, Nil)
		endOfLine = line
		for {
			character = m.GetChar()
			fmt.Printf("%c", character)
			newNode := m.Cons(character, Nil)
			m.Nodes[endOfLine].Cdr = newNode
			endOfLine = newNode
			if character == '\n' {
				break
			}
		}
		line = m.Nodes[line].Cdr

		m.InWordBuffer = m.Cons(Nil, Nil)
		endOfBuffer = m.InWordBuffer
		word = Nil

		for line != Nil {
			character = m.Nodes[line].Car
			line = m.Nodes[line].Cdr
			if character == ' ' || character == '\n' || character == '(' ||
				character == ')' || character == '[' || character == ']' ||
				character == '\'' || character == '"' {
				if word != Nil {
					newNode := m.Cons(word, Nil)
					m.Nodes[endOfBuffer].Cdr = newNode
					endOfBuffer = newNode
				}
				word = Nil
				if character != ' ' && character != '\n' {
					newNode := m.Cons(m.Cons(character, Nil), Nil)
					m.Nodes[endOfBuffer].Cdr = newNode
					endOfBuffer = newNode
				}
			} else {
				if 32 < character && character < 127 {
					word = m.Cons(character, word)
				}
			}
		}
		m.InWordBuffer = m.Nodes[m.InWordBuffer].Cdr
	}
	word = m.Nodes[m.InWordBuffer].Car
	m.InWordBuffer = m.Nodes[m.InWordBuffer].Cdr
	if m.OnlyDigits(word) {
		word = m.MkNum(m.RemoveLeadingZeros(word))
	} else {
		word = m.LookupWord(word)
	}
	return word
}

func (m *Machine) OnlyDigits(x int) bool {
	for x != Nil {
		digit := m.Nodes[x].Car
		if digit < '0' || digit > '9' {
			return false
		}
		x = m.Nodes[x].Cdr
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
			m.Nodes[last].Cdr = newNode
			last = newNode
		}
		return m.Nodes[first].Cdr
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
		if !m.Nodes[name].IsAtom {
			varLst = m.Nodes[name].Cdr
			name = m.Nodes[name].Car
			def = m.Cons(m.SymQuote, m.Cons(m.Cons(m.SymLambda, m.Cons(varLst, m.Cons(def, Nil))), Nil))
		}
		return m.Cons(m.Cons(m.SymQuote, m.Cons(m.Cons(m.SymLambda, m.Cons(m.Cons(name, Nil), m.Cons(body, Nil))), Nil)), m.Cons(def, Nil))
	}
	i = m.Nodes[w].PrimArgs
	if i == 0 {
		return w
	}
	first = m.Cons(w, Nil)
	last = first
	i--
	for i > 0 {
		newNode := m.Cons(m.Read(true, false), Nil)
		m.Nodes[last].Cdr = newNode
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

	if m.Nodes[e].IsNumb {
		return e
	}
	if m.Nodes[e].IsAtom {
		return m.Nodes[m.Nodes[e].Value].Car
	}
	if m.Nodes[e].Car == m.SymLambda {
		return e
	}

	f = m.Eval(m.Nodes[e].Car, d)
	e = m.Nodes[e].Cdr
	if f < 0 {
		return f
	}

	if f == m.SymQuote {
		return m.Nodes[e].Car
	}

	if f == m.SymIf {
		v = m.Eval(m.Nodes[e].Car, d)
		e = m.Nodes[e].Cdr
		if v < 0 {
			return v
		}
		if v == m.SymFalse {
			e = m.Nodes[e].Cdr
		}
		return m.Eval(m.Nodes[e].Car, d)
	}

	args = m.EvalSt(e, d)
	if args < 0 {
		return args
	}

	x = m.Nodes[args].Car
	y = m.Nodes[m.Nodes[args].Cdr].Car
	z = m.Nodes[m.Nodes[m.Nodes[args].Cdr].Cdr].Car

	switch m.Nodes[f].PrimCode {
	case PrimCar:
		return m.Nodes[x].Car
	case PrimCdr:
		return m.Nodes[x].Cdr
	case PrimCons:
		return m.Cons(x, y)
	case PrimAtom:
		if m.Nodes[x].IsAtom {
			return m.SymTrue
		}
		return m.SymFalse
	case PrimEq:
		if m.Eq(x, y) {
			return m.SymTrue
		}
		return m.SymFalse
	case PrimDisplay:
		if m.Nodes[m.DisplayEnabled].Car != 0 {
			return m.Print("display", x)
		}
		stub := m.Nodes[m.CapturedDisplays].Car
		oldEnd := m.Nodes[stub].Car
		newEnd := m.Cons(x, Nil)
		m.Nodes[oldEnd].Cdr = newEnd
		m.Nodes[stub].Car = newEnd
		return x
	case PrimDebug:
		return m.Print("debug", x)
	case PrimAppend:
		pX, pY := x, y
		if m.Nodes[x].IsAtom {
			pX = Nil
		}
		if m.Nodes[y].IsAtom {
			pY = Nil
		}
		return m.AppendList(pX, pY)
	case PrimLength:
		return m.MkNum(m.Length(x))
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
		if m.Compare(m.ToNum(x), m.ToNum(y)) != '>' {
			return m.SymTrue
		}
		return m.SymFalse
	case PrimGeq:
		if m.Compare(m.ToNum(x), m.ToNum(y)) != '<' {
			return m.SymTrue
		}
		return m.SymFalse
	case PrimPlus:
		return m.MkNum(m.Addition(m.ToNum(x), m.ToNum(y), 0))
	case PrimTimes:
		return m.MkNum(m.Multiplication(m.ToNum(x), m.ToNum(y)))
	case PrimPow:
		return m.MkNum(m.Exponentiation(m.ToNum(x), m.ToNum(y)))
	case PrimMinus:
		if m.Compare(m.ToNum(x), m.ToNum(y)) != '>' {
			return m.MkNum(Nil)
		}
		return m.MkNum(m.RemoveLeadingZeros(m.Subtraction(m.ToNum(x), m.ToNum(y), 0)))
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
		return m.Nodes[v].Cdr
	case PrimReadExp:
		v = m.ReadRecord()
		if v < 0 {
			return v
		}
		return m.ReadExpr(false)
	}

	if d != m.SymNoTimeLimit {
		if d == Nil {
			return -m.SymOutOfTime
		}
		d = m.Sub1(d)
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
		m.Nodes[stub].Car = stub
		m.CapturedDisplays = m.Cons(stub, m.CapturedDisplays)
		m.CleanEnv()
		v = m.Eval(y, x)
		m.RestoreEnv()
		m.Tapes = m.Nodes[m.Tapes].Cdr
		m.DisplayEnabled = m.Nodes[m.DisplayEnabled].Cdr
		stubIdx := m.Nodes[m.CapturedDisplays].Car
		m.CapturedDisplays = m.Nodes[m.CapturedDisplays].Cdr
		stub = m.Nodes[stubIdx].Cdr

		if isSmallLimit && v == -m.SymOutOfTime {
			return v
		}
		if v < 0 {
			return m.Cons(m.SymFailure, m.Cons(-v, m.Cons(stub, Nil)))
		}
		return m.Cons(m.SymSuccess, m.Cons(v, m.Cons(stub, Nil)))
	}

	if m.Nodes[f].Car == m.SymLambda {
		f = m.Nodes[f].Cdr
		vars := m.Nodes[f].Car
		f = m.Nodes[f].Cdr
		body := m.Nodes[f].Car

		m.Bind(vars, args)
		v = m.Eval(body, d)

		for !m.Nodes[vars].IsAtom {
			v_ := m.Nodes[vars].Car
			if m.Nodes[v_].IsAtom {
				m.Nodes[v_].Value = m.Nodes[m.Nodes[v_].Value].Cdr
			}
			vars = m.Nodes[vars].Cdr
		}
		return v
	}

	return f
}

func (m *Machine) CleanEnv() {
	o := m.ObjectList
	for o != Nil {
		v_ := m.Nodes[o].Car
		m.Nodes[v_].Value = m.Cons(v_, m.Nodes[v_].Value)
		o = m.Nodes[o].Cdr
	}
	m.Nodes[m.Nodes[m.SymNil].Value].Car = Nil
}

func (m *Machine) RestoreEnv() {
	o := m.ObjectList
	for o != Nil {
		v_ := m.Nodes[o].Car
		if m.Nodes[m.Nodes[v_].Value].Cdr != Nil {
			m.Nodes[v_].Value = m.Nodes[m.Nodes[v_].Value].Cdr
		}
		o = m.Nodes[o].Cdr
	}
}

func (m *Machine) Bind(vars, args int) {
	if m.Nodes[vars].IsAtom {
		return
	}
	m.Bind(m.Nodes[vars].Cdr, m.Nodes[args].Cdr)
	v_ := m.Nodes[vars].Car
	if m.Nodes[v_].IsAtom {
		m.Nodes[v_].Value = m.Cons(m.Nodes[args].Car, m.Nodes[v_].Value)
	}
}

func (m *Machine) EvalSt(e, d int) int {
	if e == Nil {
		return Nil
	}
	x := m.Eval(m.Nodes[e].Car, d)
	if x < 0 {
		return x
	}
	y := m.EvalSt(m.Nodes[e].Cdr, d)
	if y < 0 {
		return y
	}
	return m.Cons(x, y)
}

func (m *Machine) AppendList(x, y int) int {
	if x == Nil {
		return y
	}
	return m.Cons(m.Nodes[x].Car, m.AppendList(m.Nodes[x].Cdr, y))
}

func (m *Machine) Eq(x, y int) bool {
	if x == y {
		return true
	}
	if m.Nodes[x].IsNumb && m.Nodes[y].IsNumb {
		return m.EqWord(m.Nodes[x].Name, m.Nodes[y].Name)
	}
	if m.Nodes[x].IsNumb || m.Nodes[y].IsNumb {
		return false
	}
	if m.Nodes[x].IsAtom || m.Nodes[y].IsAtom {
		return false
	}
	if m.Eq(m.Nodes[x].Car, m.Nodes[y].Car) {
		return m.Eq(m.Nodes[x].Cdr, m.Nodes[y].Cdr)
	}
	return false
}

func (m *Machine) Length(x int) int {
	if m.Nodes[x].IsAtom {
		return Nil
	}
	return m.Add1(m.Length(m.Nodes[x].Cdr))
}

func (m *Machine) Compare(x, y int) int {
	if x == Nil && y == Nil {
		return '='
	}
	if x == Nil && y != Nil {
		return '<'
	}
	if x != Nil && y == Nil {
		return '>'
	}
	already := m.Compare(m.Nodes[x].Cdr, m.Nodes[y].Cdr)
	if already != '=' {
		return already
	}
	d1, d2 := m.Nodes[x].Car, m.Nodes[y].Car
	if d1 < d2 {
		return '<'
	}
	if d1 > d2 {
		return '>'
	}
	return '='
}

func (m *Machine) Add1(x int) int {
	if x == Nil {
		return m.Cons('1', Nil)
	}
	digit := m.Nodes[x].Car
	if digit != '9' {
		return m.Cons(digit+1, m.Nodes[x].Cdr)
	}
	return m.Cons('0', m.Add1(m.Nodes[x].Cdr))
}

func (m *Machine) Sub1(x int) int {
	if x == Nil {
		return x
	}
	digit := m.Nodes[x].Car
	if digit == '1' && m.Nodes[x].Cdr == Nil {
		return Nil
	}
	if digit != '0' {
		return m.Cons(digit-1, m.Nodes[x].Cdr)
	}
	return m.Cons('9', m.Sub1(m.Nodes[x].Cdr))
}

func (m *Machine) ToNum(x int) int {
	if m.Nodes[x].IsNumb {
		return m.Nodes[x].Name
	}
	return Nil
}

func (m *Machine) RemoveLeadingZeros(x int) int {
	if x == Nil {
		return Nil
	}
	digit := m.Nodes[x].Car
	rest := m.RemoveLeadingZeros(m.Nodes[x].Cdr)
	if rest == Nil && digit == '0' {
		return Nil
	}
	return m.Cons(digit, rest)
}

func (m *Machine) Addition(x, y, carry int) int {
	if x == Nil && carry == 0 {
		return y
	}
	if y == Nil && carry == 0 {
		return x
	}
	d1, r1 := int('0'), Nil
	if x != Nil {
		d1, r1 = m.Nodes[x].Car, m.Nodes[x].Cdr
	}
	d2, r2 := int('0'), Nil
	if y != Nil {
		d2, r2 = m.Nodes[y].Car, m.Nodes[y].Cdr
	}
	sum := d1 + d2 + carry - int('0')
	if sum <= int('9') {
		return m.Cons(sum, m.Addition(r1, r2, 0))
	}
	return m.Cons(sum-10, m.Addition(r1, r2, 1))
}

func (m *Machine) Subtraction(x, y, borrow int) int {
	if y == Nil && borrow == 0 {
		return x
	}
	d1, r1 := int('0'), Nil
	if x != Nil {
		d1, r1 = m.Nodes[x].Car, m.Nodes[x].Cdr
	}
	d2, r2 := int('0'), Nil
	if y != Nil {
		d2, r2 = m.Nodes[y].Car, m.Nodes[y].Cdr
	}
	diff := d1 - d2 - borrow + int('0')
	if diff >= int('0') {
		return m.Cons(diff, m.Subtraction(r1, r2, 0))
	}
	return m.Cons(diff+10, m.Subtraction(r1, r2, 1))
}

func (m *Machine) Multiplication(x, y int) int {
	sum := Nil
	if y == Nil {
		return Nil
	}
	for x != Nil {
		digit := m.Nodes[x].Car
		for digit > '0' {
			sum = m.Addition(sum, y, 0)
			digit--
		}
		y = m.Cons('0', y)
		x = m.Nodes[x].Cdr
	}
	return sum
}

func (m *Machine) Exponentiation(base, exp int) int {
	prod := m.Cons('1', Nil)
	for exp != Nil {
		prod = m.Multiplication(base, prod)
		exp = m.Sub1(exp)
	}
	return prod
}

// --- Tape & Main ---

func (m *Machine) Base2To10(x int) int {
	res := Nil
	for !m.Nodes[x].IsAtom {
		bit := m.Nodes[x].Car
		v := 1
		if m.Nodes[bit].IsNumb && m.Nodes[bit].Name == Nil {
			v = 0
		}
		res = m.Addition(res, res, v)
		x = m.Nodes[x].Cdr
	}
	return res
}

func (m *Machine) Halve(x int) int {
	if x == Nil {
		return x
	}
	digit := m.Nodes[x].Car - '0'
	rest := m.Halve(m.Nodes[x].Cdr)
	next := 0
	if m.Nodes[x].Cdr != Nil {
		next = m.Nodes[m.Nodes[x].Cdr].Car - '0'
	}
	val := '0' + (digit / 2) + (5 * (next % 2))
	if val != '0' || rest != Nil {
		return m.Cons(val, rest)
	}
	return Nil
}

func (m *Machine) Base10To2(x int) int {
	bits := Nil
	for x != Nil {
		bit := m.SymZero
		if (m.Nodes[x].Car-'0')%2 != 0 {
			bit = m.SymOne
		}
		bits = m.Cons(bit, bits)
		x = m.Halve(x)
	}
	return bits
}

func (m *Machine) Size(x int) int {
	if m.Nodes[x].IsNumb && m.Nodes[x].Name == Nil {
		return m.Add1(Nil)
	}
	if m.Nodes[x].IsAtom {
		return m.Length(m.Nodes[x].Name)
	}
	sum := Nil
	for !m.Nodes[x].IsAtom {
		sum = m.Addition(sum, m.Size(m.Nodes[x].Car), 0)
		x = m.Nodes[x].Cdr
		if !m.Nodes[x].IsAtom {
			sum = m.Add1(sum)
		}
	}
	return m.Add1(m.Add1(sum))
}

func (m *Machine) ReadBit() int {
	t := m.Nodes[m.Tapes].Car
	if m.Nodes[t].IsAtom {
		return -m.SymOutOfData
	}
	bit := m.Nodes[t].Car
	m.Nodes[m.Tapes].Car = m.Nodes[t].Cdr
	if m.Nodes[bit].IsNumb && m.Nodes[bit].Name == Nil {
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
		m.Nodes[m.Q].Cdr = node
		m.Q = node
	}
}

func (m *Machine) WriteLisp(x int) {
	if m.Nodes[x].IsNumb && m.Nodes[x].Name == Nil {
		m.WriteChar('0')
		return
	}
	if m.Nodes[x].IsAtom {
		m.WriteAtomName(m.Nodes[x].Name)
		return
	}
	m.WriteChar('(')
	for !m.Nodes[x].IsAtom {
		m.WriteLisp(m.Nodes[x].Car)
		x = m.Nodes[x].Cdr
		if !m.Nodes[x].IsAtom {
			m.WriteChar(' ')
		}
	}
	m.WriteChar(')')
}

func (m *Machine) WriteAtomName(x int) {
	if x == Nil {
		return
	}
	m.WriteAtomName(m.Nodes[x].Cdr)
	m.WriteChar(m.Nodes[x].Car)
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
	line := m.Cons(Nil, Nil)
	end := line
	for {
		c := m.ReadChar()
		if c < 0 {
			return c
		}
		node := m.Cons(c, Nil)
		m.Nodes[end].Cdr = node
		end = node
		if c == '\n' {
			break
		}
	}
	line = m.Nodes[line].Cdr

	m.Buffer2 = m.Cons(Nil, Nil)
	bufEnd := m.Buffer2
	word := Nil
	for line != Nil {
		c := m.Nodes[line].Car
		line = m.Nodes[line].Cdr
		if c == ' ' || c == '\n' || c == '(' || c == ')' {
			if word != Nil {
				node := m.Cons(word, Nil)
				m.Nodes[bufEnd].Cdr = node
				bufEnd = node
			}
			word = Nil
			if c != ' ' && c != '\n' {
				node := m.Cons(m.Cons(c, Nil), Nil)
				m.Nodes[bufEnd].Cdr = node
				bufEnd = node
			}
		} else if 32 < c && c < 127 {
			word = m.Cons(c, word)
		}
	}
	m.Buffer2 = m.Nodes[m.Buffer2].Cdr
	return 0
}

func (m *Machine) ReadWord() int {
	if m.Buffer2 == Nil {
		return m.RightParen
	}
	word := m.Nodes[m.Buffer2].Car
	m.Buffer2 = m.Nodes[m.Buffer2].Cdr
	if m.OnlyDigits(word) {
		word = m.MkNum(m.RemoveLeadingZeros(word))
	} else {
		word = m.LookupWord(word)
	}
	return word
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
			m.Nodes[last].Cdr = node
			last = node
		}
		return m.Nodes[first].Cdr
	}
	return w
}

func main() {
	m := NewMachine()
	fmt.Printf("LISP Interpreter Run\n")
	m.Init()

	for {
		fmt.Printf("\n")
		e := m.Read(true, false)
		fmt.Printf("\n")

		f := m.Nodes[e].Car
		name := m.Nodes[m.Nodes[e].Cdr].Car
		def := m.Nodes[m.Nodes[m.Nodes[e].Cdr].Cdr].Car

		if f == m.SymDefine {
			if !m.Nodes[name].IsAtom {
				varList := m.Nodes[name].Cdr
				name = m.Nodes[name].Car
				def = m.Cons(m.SymLambda, m.Cons(varList, m.Cons(def, Nil)))
			}
			m.Print("define", name)
			m.Print("value", def)
			m.Nodes[m.Nodes[name].Value].Car = def
			continue
		}
		e = m.Print("expression", e)
		e = m.Print("value", m.Ev(e))
	}
}
