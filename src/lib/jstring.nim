import std/strutils

func lstrip*(s: string, chars: string): string =
  # Strips leading chars from s and returns the resulting string.
  var bs: set[char] = {}
  for c in chars:
    bs = bs + {c}
  s.strip(leading=true, trailing=false, chars=bs)

func rstrip*(s: string, chars: string): string =
  # Strips trailing chars from s and returns the resulting string.
  var bs: set[char] = {}
  for c in chars:
    bs = bs + {c}
  s.strip(leading=false, trailing=true, chars=bs)
