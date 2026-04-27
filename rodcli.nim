#!/usr/bin/env nimbang
#off:nimbang-args c -d:release
#nimbang-settings hideDebugInfo

import
  std/browsers,
  std/httpclient,
  std/json,
  std/os,
  std/osproc,
  std/rdstdin,
  std/sequtils,
  std/strformat,
  std/strutils,
  std/tables

import
  lib/jfs,
  lib/jstring

const
  VERSION = "0.2.4"
  REQUIRED_NIM_VERSION = "nim >= 2.2.0"    # goes in the .nimble file
  BASIC = "basic"
  EXIT_CODE_OK = 0
  EDITOR =
    if defined(windows):
      "notepad++"    # to use it, add Notepad++'s folder to the PATH
                     # I wanted to use "code" here, but Windows didn't want to launch it
    else:
      getEnv("EDITOR", "vim")
  HOME = getHomeDir().rstrip("/")
  PYKOT_DIR_LOCATION = &"{HOME}/Dropbox/nim/_projects/NimPyKot/src"
  VSCODE_NIM_SNIPPET = &"{HOME}/.config/Code/User/snippets/nim.json"
  PACKAGES_JSON = &"{HOME}/.nimble/packages_official.json"    # update with `nimble update`

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
""".format(BASIC, REQUIRED_NIM_VERSION).lstrip("\n")

const BASIC_NIM_SOURCE = """
proc main() =
  echo "hello world"

# ###########################################################################

when isMainModule:
  main()
""".lstrip("\n")

const HELP = """
RodCli, a Nim CLI Helper v$1
===============================
 option               what it does                                notes
--------    ----------------------------------    ----------------------------------------
init        bundles the indented 2 steps below    initialize a project folder ("rod init [name]")
  basic     create a basic source file            "rod basic [name]", where [name] is optional
  nimble    simplified nimble init                create a simple .nimble file
ed          edit .nimble                          edit the .nimble file
add         add dependency                        "rod add <pkg>" calls "nimble add <pkg>"
id          nimble install -d                     install dependencies (and nothing else)
                                                  (like `pip install -r requirements.txt`)
s                                                 compile, run, then delete the exe, i.e.
                                                  run it as if it were a script [alias: script]
ver         nim --version                         version info [aliases: v, version]
i                                                 interactive mode
h                                                 help

alap        create alap.nim                       "rod alap [name]", where [name] is optional
pykot       download pykot.nim                    a small Python/Kotlin -like library
make        create Makefile                       for easy compilation
gi          create .gitignore                     create the .gitignore file
config      create config.nims                    create the config.nims file
jabba       alap+pykot+nimble+make+gi             Jabba's bundle
""".format(VERSION).strip

const CONFIG_NIMS = """
switch("path", "lib")

# switch("define", "ssl")
# switch("passL", "-s")    # strip -s
""".strip

const MAKEFILE = """
cat:
\tcat Makefile

c:
\tnim c alap.nim

rel:
\tnim c -d:release alap.nim
""".lstrip("\n").replace(r"\t", "\t")

const GITIGNORE = """
backup/
nimble.paths
nimbledeps
""".strip

proc help() =
  echo HELP

proc inputExtra(prompt: string = ""): string =
  var line: string = ""
  let val = readLineFromStdin(prompt, line)    # line is modified
  if not val:
    raise newException(EOFError, "abort")
  line

proc http_return_code(url: string): int =
  try:
    let
      client = newHttpClient()
      r = request(client, url, HttpHead)

    int(code(r))
  except:
    -1

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
    if path == "":
      echo &"# Warning: the command {prg} was not found"
      echo "# Tip: make sure it's installed and it's in your PATH"
      return 1

  if debug:
    echo &"# {cmdString}"
  if sep:
    echo "-".repeat(78)

  execCmd(cmdString)

proc get_simple_cmd_output(cmd: string): string =
  # Execute a simple external command and get its output.
  execProcess(cmd)

proc version_info() =
  echo get_simple_cmd_output("nim --version").splitlines()[0]

proc compile(args: seq[string], output = true, release = false,
             small = false, strip = false): int =
  var
    options = ""
    src: string
    cmd: string

  if not output:
    options = "--hints:off --warnings:off"
  try:
    src = args[1]    # We need boundChecks for this! (added to config.nims)
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
  if strip:
    cmd = &"nim {options} c -d:release --opt:size --passL:-s {src}"
  #
  execute_command(cmd.split, debug=false)

func get_exe_name(sourceFileName: string): string =
  let (_, exe, _) = splitFile(sourceFileName)
  if defined(windows):
    &"{exe}.exe"
  else:
    exe

proc run_exe(exe: string, params: seq[string]): int =
  let
    params = params.join()
    cmd =
      if defined(windows):
        &"{exe} {params}"
      else:
        &"./{exe} {params}"
  #
  execute_command(cmd.split, debug=false, sep=false)

proc delete_exe(exe: string): bool =
  # Return true if deleting the file was successful.
  # Return false otherwise.
  let ext = splitFile(exe).ext
  if fileExists(exe) and ext != ".nim":
      # echo &"# remove {exe}"
      removeFile(exe)
  return not fileExists(exe)

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

proc get_3rd_party_module_url(module_name: string): string =
  if not os.fileExists(PACKAGES_JSON):
    echo &"# Warning: the file {PACKAGES_JSON} doesn't exist"
    return ""
  # else, the file exists
  try:
    let parsed = parseFile(PACKAGES_JSON)

    for d in parsed:
      if d["name"].str == module_name:
        return d["url"].str.strip
  except:
    echo &"# Warning: couldn't process the file {PACKAGES_JSON}"
    return ""

proc create_basic_file(name=BASIC, executable=false): int =
  let fname = &"{name}.nim"

  if fileExists(fname):
    echo &"# Warning: {fname} already exists"
    return 1
  # else, if basic.nim doest't exist
  if not fileExists(VSCODE_NIM_SNIPPET):
    writeFile(fname, BASIC_NIM_SOURCE)
    if executable:
      make_executable(fname)
    echo &"# a basic {fname} was created"
  else:
    try:
      let
        parsed = parseFile(VSCODE_NIM_SNIPPET)
        snippet = parsed["alap"]["body"].mapIt(it.str).join("\n").replace("$0", "")

      writeFile(fname, snippet)
      if executable:
        make_executable(fname)
      echo &"# {fname} was created using your VS Code Nim snippet"
      result = EXIT_CODE_OK
    except:
      echo &"# Warning: couldn't process the file {VSCODE_NIM_SNIPPET}"
      writeFile(fname, BASIC_NIM_SOURCE)
      if executable:
        make_executable(fname)
      echo &"# a basic {fname} was created"

proc create_makefile(): int =
  let fname = "Makefile"

  if fileExists(fname):
    echo &"# Warning: {fname} already exists"
    return 1
  # else, if Makefile doesn't exist
  writeFile(fname, MAKEFILE)
  echo "# Makefile was created"
  result = EXIT_CODE_OK

proc create_gitignore(): int =
  let fname = ".gitignore"

  if fileExists(fname):
    echo &"# Warning: {fname} already exists"
    return 1
  # else, if .gitignore doesn't exist
  writeFile(fname, GITIGNORE)
  echo "# .gitignore was created"
  result = EXIT_CODE_OK

proc create_config(): int =
  let fname = "config.nims"

  if fileExists(fname):
    echo &"# Warning: {fname} already exists"
    return 1
  # else, if config.nims doesn't exist
  writeFile(fname, CONFIG_NIMS)
  echo "# config.nims was created"
  result = EXIT_CODE_OK

proc copy_pykot(): int =
  if dirExists(PYKOT_DIR_LOCATION):
    copyDir(PYKOT_DIR_LOCATION, "lib/")
    writeFile("config.nims", CONFIG_NIMS)
    echo "# the pykot lib. was copied to the current folder"
    result = EXIT_CODE_OK
  else:
    result = 1

proc nimble(name=BASIC): int =
  let fname = &"{name}.nimble"

  if fileExists(fname):
    echo &"# Warning: {fname} already exists"
    return 1

  # else, the .nimble file doesn't exist
  var text = NIMBLE
  if name != BASIC:
    text = text.replace(BASIC, name)

  writeFile(fname, text)
  echo &"# {fname} was created"
  EXIT_CODE_OK

proc edit_nimble_file(): int =
  let files = walkFiles("*.nimble").toSeq
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

proc add_dependency(pkg_name: string): int =
  let cmd = &"nimble add {pkg_name}"
  execute_command(cmd.split)

proc interactive() =
  let
    d = {
      "nim": "https://nim-lang.org/",
      "hq": "https://nim-lang.org/",
      "blog": "https://nim-lang.org/blog.html",
      "forum": "https://forum.nim-lang.org/",
      "github": "https://github.com/nim-lang/nim",
      "doc": "https://nim-lang.org/documentation.html",
      "docs": "https://nim-lang.org/documentation.html",
      "lib": "https://nim-lang.org/docs/lib.html",
      "stdlib": "https://nim-lang.org/docs/lib.html",
      "lib2": "https://nim-lang.github.io/Nim/lib.html",    # latest docs from the devel branch
      "index": "https://nim-lang.org/docs/theindex.html"
    }.toTable
    # commands = sorted(toSeq(d.keys()), cmp[string])

  proc print_help() =
    for k, v in d:
      echo &"{k:12}->    {v}"
    echo "h, help     ->    help"
    echo "q           ->    quit"
    echo "m <module>  ->    open the stable docs of the given stdlib module"
    echo "m2 <module> ->    open the devel docs of the given stdlib module"
    echo "p <module>  ->    open 3rd-party module using your local packages.json"

  func is_module_call(s: string): bool =
    let words = s.splitWhitespace
    (words.len == 2) and (words[0] in ["m", "m2"])

  func is_3rd_party_package_call(s: string): bool =
    let words = s.splitWhitespace
    (words.len == 2) and (words[0] == "p")

  echo "interactive mode (press Ctrl+D to quit)"
  echo ""
  print_help()

  while true:
    echo ""
    try:
      let inp = inputExtra(">>> ").strip
      if inp in d:
        let url = d[inp]
        echo &"# {url}"
        openDefaultBrowser(url)
      elif inp in ["h", "help"]:
        print_help()
      elif inp == "q":
        break
      elif is_3rd_party_package_call(inp):
        let
          words = inp.splitWhitespace
          module = words[1]
          url = get_3rd_party_module_url(module)

        if url.len == 0:
          echo "# warning: the module is not found"
          echo "# tip: run `nimble update` to update your local packages database"
        else:
          echo &"# opening {url}"
          openDefaultBrowser(url)
      elif is_module_call(inp):
        const
          stable = "https://nim-lang.org/docs/$1.html"
          devel = "https://nim-lang.github.io/Nim/$1.html"
        let
          words = inp.splitWhitespace
          which = words[0]
          module = words[1]
          url_template = if which == "m": stable else: devel
          url = url_template.format(module)
          code = http_return_code(url)

        if code == 200:
          echo "# $1 docs".format(if which == "m": "stable" else: "devel")
          openDefaultBrowser(url)
        else:
          echo "# HTTP return code: $1".format(code)
          echo "# Maybe there is a typo? Or, in the worst case, such a module doesn't exist."
      else:
        echo "What?"
    except EOFError:
      break

proc process(args: seq[string]): int =
  let
    param = args[0]
    # params = args[1 .. args.high].join(" ")

  var exit_code = 0

  case param:
    of "ver", "v", "version":
      version_info()
    of "basic", "alap":
      let name = if args.len == 2: args[1] else: param
      exit_code = create_basic_file(name=name, executable=true)
    of "pykot":
      exit_code = copy_pykot()
    of "nimble":
      let name = block:
        let files = walkFiles("*.nim").toSeq
        if files.len != 1:
          "basic"
        else:
          files[0].changeFileExt("")
      exit_code = nimble(name=name)
    of "init":
      let name = if args.len == 2: args[1] else: "basic"
      discard create_basic_file(name=name, executable=true)
      discard nimble(name=name)
    of "make":
      discard create_makefile()
    of "gi":
      discard create_gitignore()
    of "config":
      discard create_config()
    of "jabba":    # for the author of the package :)
      discard create_basic_file(name="alap", executable=true)
      discard copy_pykot()
      discard nimble(name="alap")
      discard create_makefile()
      discard create_gitignore()
    of "ed":
      exit_code = edit_nimble_file()
    of "add":
      if args.len != 2:
        stderr.writeLine "Error: provide a single package name"
        return 1
      # else:
      let pkg_name = args[1]
      exit_code = add_dependency(pkg_name)
    of "id":
      exit_code = install_dependencies()
    of "s", "script":
      exit_code = compile_run_delete_exe(args)
    of "i":
      interactive()
    of "h":
      help()
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
