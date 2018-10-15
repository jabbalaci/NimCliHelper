import strutils
import strformat
import sequtils
import os
import osproc
import json

func rstrip(s: string, chars: string): string =
  # Strips trailing chars from s and returns the resulting string.
  var bs: set[char] = {}
  for c in chars:
    bs = bs + {c}
  s.strip(leading=false, trailing=true, chars=bs)

const
  VERSION = "0.1.5"
  REQUIRED_NIM_VERSION = "nim >= 0.19.0"    # goes in the .nimble file
  BASIC = "basic"
  EXIT_CODE_OK = 0
  EDITOR =
    if defined(windows):
      "notepad++"    # to use it, add Notepad++'s folder to the PATH
                     # I wanted to use "code" here, but Windows didn't want to launch it
    else:
      "vim"
  HOME = getHomeDir().rstrip("/")
  PYKOT_LOCATION = &"{HOME}/Dropbox/nim/NimPyKot/src/pykot.nim"
  VSCODE_NIM_SNIPPET = &"{HOME}/.config/Code/User/snippets/nim.json"

const NIMBLE = """
# Package

version       = "0.1.0"
author        = "..."
description   = "..."
license       = "MIT"
# srcDir        = "src"
# bin           = @["$1"]


# Dependencies

requires "$2"
""".format(BASIC, REQUIRED_NIM_VERSION).strip

const HELP = """
RodCli, a Nim CLI Helper v$1
===============================
 option               what it does                                notes
--------    ----------------------------------    ----------------------------------------
init        bundles the indented 2 steps below    initialize a project folder
  basic     create basic.nim                      create a basic skeleton source file
  nimble    simplified nimble init                create a simple basic.nimble file
ad          edit .nimble                          add dependency
id          nimble install -d                     install dependencies (and nothing else)
                                                  (like `pip install -r requirements.txt`)
c           nim c                                 compile (debug) [alias: compile]
cr          nim c -r                              compile and run
s                                                 compile, run, then delete the exe, i.e.
                                                  run it as if it were a script [alias: script]
rel         nim c -d:release                      compile (release) [alias: release]
s1          nim c -d:release --opt:size           small EXE [alias: small1]
s2          small1 + strip                        smaller EXE [alias: small2]
s3          small2 + upx                          smallest EXE [alias: small3]
ver         nim --version                         version info [aliases: v, version]
""".format(VERSION).strip

# hide it, don't force my own library on the others :)
# pykot       copy pykot.nim .                      copy pykot.nim to the current dir.

proc help() =
    echo HELP

proc which(fname: string): string =
  let
    sep = if defined(windows): ";" else: ":"
    dirs = getEnv("PATH").split(sep)

  for dir in dirs:
    let path = joinPath(dir, fname)
    if existsFile(path):
      return path
  #
  return ""    # not found

proc execute_command(cmd: seq[string], verify = false, debug = true, sep = false): int =
  # Execute a simple external command and return its exit status.
  var cmd = cmd    # shadowing

  if defined(windows):
    if not cmd[0].endsWith(".exe"):
      cmd[0] &= ".exe"

  let
    prg = cmd[0]
    cmdString = cmd.join(" ")

  if verify:
    let path = which(prg)
    echo &"path: {path}"
    if path == "":
      echo &"# Warning: the command {prg} was not found. Maybe not installed?"
      return 1
    
  if debug:
    echo &"# {cmdString}"
  if sep:
    echo "-".repeat(78)

  execCmd(cmdString)

proc get_simple_cmd_output(cmd: string): string =
  # Execute a simple external command and get its output.
  execProcess(cmd)

proc compile(args: seq[string], output = true, release = false, small = false): int =
  var
    options = ""
    src: string
    cmd: string

  if not output:
      options = "--hints:off --verbosity:0"
  try:
      src = args[1]
  except:
      stderr.writeLine "Error: provide the source file too!"
      stderr.writeLine "Tip: rod c <input.nim>"
      return 1
  # else
  cmd = &"nim {options} c {src}"
  if release:
      cmd = &"nim {options} c -d:release {src}"
  if small:
      cmd = &"nim {options} c -d:release --opt:size {src}"
  #
  execute_command(cmd.split)

proc strip_exe(exe: string): int =
  let cmd = &"strip -s {exe}"
  execute_command(cmd.split, verify=true)

proc upx_exe(exe: string): int =
  let cmd = &"upx --best {exe}"
  execute_command(cmd.split, verify=true)

proc small1(args: seq[string]): int =
  compile(args, release=true, small=true)

func get_exe_name(sourceFileName: string): string =
  let (dir, exe, ext) = splitFile(sourceFileName)
  if defined(windows):
    &"{exe}.exe"
  else:
    exe

proc small2(args: seq[string]): int =
  discard small1(args)
  let exe = get_exe_name(args[1])
  strip_exe(exe)

proc small3(args: seq[string]): int =
  discard small2(args)
  let exe = get_exe_name(args[1])
  upx_exe(exe)

proc version_info() =
  echo get_simple_cmd_output("nim --version").splitlines()[0]

proc run_exe(exe: string, params: seq[string]): int =
  let
    params = params.join()
    cmd =
      if defined(windows):
        &"{exe} {params}"
      else:
        &"./{exe} {params}"
  #
  execute_command(cmd.split, sep=true)

proc delete_exe(exe: string): bool =
  # Return true if deleting the file was successful.
  # Return false otherwise.
  let ext = splitFile(exe).ext
  if existsFile(exe) and ext != ".nim":
      # echo &"# remove {exe}"
      removeFile(exe)
  return not existsFile(exe)

proc compile_run_delete_exe(args: seq[string]): int =
  var exit_code = compile(args, output=false)
  if exit_code != EXIT_CODE_OK:
      return exit_code
  # else
  let exe = get_exe_name(args[1])
  discard run_exe(exe, args[2 .. args.high])
  if delete_exe(exe):    # deleting the file was successful
    return EXIT_CODE_OK
  # else
  return 1

proc create_basic_file(name=BASIC): int =
  let fname = &"{name}.nim"

  if existsFile(fname):
    echo &"# Warning: {fname} already exists"
    return 1
  # else, if basic.nim doest't exist
  if not existsFile(VSCODE_NIM_SNIPPET):
    let cmd = &"touch {fname}"
    result = execute_command(cmd.split)
    echo &"# an empty {fname} was created"
  else:
    try:
      let
        parsed = parseFile(VSCODE_NIM_SNIPPET)
        snippet = parsed["alap"]["body"].mapIt(it.str).join("\n").replace("$0", "")

      writeFile(fname, snippet)
      echo &"# {fname} was created using your VS Code Nim snippet"
      result = EXIT_CODE_OK
    except:
      echo &"# Warning: couldn't process the file {VSCODE_NIM_SNIPPET}"
      let cmd = &"touch {fname}"
      result = execute_command(cmd.split)
      echo &"# an empty {fname} was created"

proc copy_pykot(): int =
  if not existsFile(PYKOT_LOCATION):
    echo &"# Warning: {PYKOT_LOCATION} was not found"
    return 1
  # else
  let fname = "pykot.nim"
  if existsFile(fname):
      echo &"# {fname} exists in the current folder, deleting it"
      removeFile &"./{fname}"
  copyFile(PYKOT_LOCATION, &"./{fname}")
  echo &"# {fname}'s latest version was copied to the current folder"
  EXIT_CODE_OK

proc nimble(name=BASIC): int =
  let fname = &"{name}.nimble"

  if existsFile(fname):
    echo &"# Warning: {fname} already exists"
    return 1
  
  # else, the .nimble file doesn't exist
  var text = NIMBLE
  if name != BASIC:
    text = text.replace(BASIC, name)
  
  writeFile(fname, text)
  echo &"# {fname} was created"
  EXIT_CODE_OK

proc add_dependency(): int =
  let files = toSeq(walkFiles("*.nimble"))
  if files.len != 1:
    echo "Error: one (and only one) .nimble file is required"
    return 1
  # else
  let
    nimble_file = files[0]
    cmd = &"{EDITOR} {nimble_file}"
  execute_command(cmd.split, verify=true)

proc install_dependencies(): int =
  execute_command("nimble install -d".split)

proc process(args: seq[string]): int =
  let
    param = args[0]
    params = args[1 .. args.high].join(" ")
    
  var exit_code = 0

  case param:
    of "ver", "v", "version":
      version_info()
    of "basic", "alap":
      exit_code = create_basic_file(name=param)
    of "pykot":
      exit_code = copy_pykot()
    of "nimble":
      exit_code = nimble()
    of "init":
      discard create_basic_file()
      discard nimble()
    of "jabba":    # an undocumented option for the author of the package :)
      discard create_basic_file(name="alap")
      discard copy_pykot()
      discard nimble(name="alap")
    of "ad":
      exit_code = add_dependency()
    of "id":
      exit_code = install_dependencies()
    of "c", "compile":
      exit_code = compile(args)
    of "cr":
      exit_code = compile(args)
      if exit_code != EXIT_CODE_OK:
          return exit_code
      # else
      let exe = get_exe_name(args[1])
      exit_code = run_exe(exe, args[2 .. args.high])
    of "rel", "release":
      exit_code = compile(args, release=true)
    of "s1", "small1":
      exit_code = small1(args)
    of "s2", "small2":
      exit_code = small2(args)
    of "s3", "small3":
      exit_code = small3(args)
    of "s", "script":
      exit_code = compile_run_delete_exe(args)
    else:
      echo "Error: unknown parameter"
      exit_code = 1

  exit_code

proc main(): int =
  if paramCount() == 0:
    help()
    return 0
  # else
  process((1 .. paramCount()).mapIt(paramStr(it)))

# ############################################################################

when isMainModule:
  quit(main())
