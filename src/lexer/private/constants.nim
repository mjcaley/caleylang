const IndentChars* = @[" ", "\t"]

const WhitespaceChars* = @[
  "\v", "\f",

  "\u0085", "\u00a0", "\u1680", "\u2000", "\u2001", "\u2002",
  "\u2003", "\u2004", "\u2005", "\u2006", "\u2007", "\u2008",
  "\u2009", "\u200a", "\u2028", "\u2029", "\u202f", "\u205f",
  "\u3000", "\u180e", "\u200b", "\u200c", "\u200d", "\u2060",
  "\ufeff"
] & IndentChars

const NewlineChars* = @["\n", "\r"]

const ArithmeticChars* = @["+", "-", "*", "/", "%"]

const BracketChars* = @["(", ")", "[", "]", "{", "}"]

const ReservedChars* = 
  @["!", "=", "<", ">", ".", ":", ","] & 
  IndentChars &
  WhiteSpaceChars &
  NewlineChars &
  ArithmeticChars &
  BracketChars

const DigitChars* = @["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]

const BinaryChars* = @["0", "1"]

const HexChars* = @["0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
                    "a", "b", "c", "d", "e", "f",
                    "A", "B", "C", "D", "E", "F"]

const OctChars* = ["0", "1", "2", "3", "4", "5", "6", "7"]
