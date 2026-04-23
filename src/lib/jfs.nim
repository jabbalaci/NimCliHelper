import std/os
import std/strutils

proc make_executable*(fname: string) =
  let perms = getFilePermissions(fname)
  setFilePermissions(fname, perms + {fpUserExec})

proc which*(fname: string): string =
  let
    sep = if defined(windows): ";" else: ":"
    dirs = getEnv("PATH").split(sep)

  for dir in dirs:
    let path = joinPath(dir, fname)
    if fileExists(path):
      return path
  #
  return ""    # not found
