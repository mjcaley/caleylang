import unicode

proc toRune*(s: string) : Rune =
  fastRuneAt(s, 0, result, doInc=false)
