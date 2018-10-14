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
  VERSION = "0.1.4"
  EXIT_CODE_OK = 0
  EDITOR = "vim"
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
# bin           = @["alap"]


# Dependencies

requires "nim >= 0.19.0"
""".strip

const HELP = """
RodCli, a Nim CLI Helper v$1
===============================
 option               what it does                                notes
--------    ----------------------------------    ----------------------------------------
init        bundles the indented 3 steps below    initialize a project folder
  alap      create alap.nim                       create a skeleton source file
  pykot     copy pykot.nim .                      copy pykot.nim to the current dir.
  nimble    simplified nimble init                create a simple .nimble file
ad          edit .nimble                          add dependency
id          nimble install -d                     install dependencies (and nothing else)
                                                  (like `pip install -r requirements.txt`)
c           nim c                                 compile (debug)
cr          nim c -r                              compile and run
s                                                 compile, run, then delete the exe
                                                  i.e., run it as if it were a script
rel         nim c -d:release                      compile (release)
small1      nim c -d:release --opt:size           small EXE
small2      small1 + strip                        smaller EXE
small3      small2 + upx                          smallest EXE
ver         nim --version                         version info
""".format(VERSION).strip

proc help() =
    echo HELP

proc execute_command(cmd: string, debug = true, sep = false): int =
  # Execute a simple external command and return its exit status.
  if debug:
    echo &"# {cmd}"
  if sep:
    echo "-".repeat(78)
  execCmd(cmd)

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
  execute_command(cmd)

proc strip_exe(exe: string): int =
  execute_command(&"strip -s {exe}")

proc upx_exe(exe: string): int =
  execute_command(&"upx --best {exe}")

proc small1(args: seq[string]): int =
  compile(args, release=true, small=true)

func get_exe_name(sourceFileName: string): string =
  let (dir, exe, ext) = splitFile(sourceFileName)
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
    cmd = &"./{exe} {params}"
  #
  execute_command(cmd, sep=true)

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

proc create_alap_file(): int =
  let fname = "alap.nim"

  if existsFile(fname):
    echo &"# Warning: {fname} already exists"
    return 1
  # else, if alap.nim doest't exist
  if not existsFile(VSCODE_NIM_SNIPPET):
    result = execute_command(&"touch {fname}")
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
      result = execute_command(&"touch {fname}")
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

proc nimble(): int =
  let fname = "alap.nimble"
  if existsFile(fname):
      echo &"# Warning: {fname} already exists"
      return 1
  # else
  writeFile(fname, NIMBLE)
  echo &"# {fname} was created"
  EXIT_CODE_OK

proc add_dependency(): int =
  let files = toSeq(walkFiles("*.nimble"))
  if files.len != 1:
    echo "Error: one (and only one) .nimble file is required"
    return 1
  # else
  let nimble_file = files[0]
  execute_command(&"{EDITOR} {nimble_file}")

proc install_dependencies(): int =
  execute_command("nimble install -d")

proc process(args: seq[string]): int =
  let
    param = args[0]
    params = args[1 .. args.high].join(" ")
    
  var exit_code = 0

  if param == "ver":
    version_info()
  elif param == "alap":
    exit_code = create_alap_file()
  elif param == "pykot":
    exit_code = copy_pykot()
  elif param == "nimble":
    exit_code = nimble()
  elif param == "init":
    discard create_alap_file()
    discard copy_pykot()
    discard nimble()
  elif param == "ad":
    exit_code = add_dependency()
  elif param == "id":
    exit_code = install_dependencies()
  elif param == "c":
    exit_code = compile(args)
  elif param == "cr":
    exit_code = compile(args)
    if exit_code != EXIT_CODE_OK:
        return exit_code
    # else
    let exe = get_exe_name(args[1])
    exit_code = run_exe(exe, args[2 .. args.high])
  elif param == "rel":
    exit_code = compile(args, release=true)
  elif param == "small1":
    exit_code = small1(args)
  elif param == "small2":
    exit_code = small2(args)
  elif param == "small3":
    exit_code = small3(args)
  elif param == "s":
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
