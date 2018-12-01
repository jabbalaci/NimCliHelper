import
  algorithm,
  browsers,
  httpclient,
  json,
  os,
  osproc,
  rdstdin,
  sequtils,
  strformat,
  strutils,
  tables

func lstrip(s: string, chars: string): string =
  # Strips leading chars from s and returns the resulting string.
  var bs: set[char] = {}
  for c in chars:
    bs = bs + {c}
  s.strip(leading=true, trailing=false, chars=bs)

func rstrip(s: string, chars: string): string =
  # Strips trailing chars from s and returns the resulting string.
  var bs: set[char] = {}
  for c in chars:
    bs = bs + {c}
  s.strip(leading=false, trailing=true, chars=bs)

const
  VERSION = "0.1.9"
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
  PYKOT_DIR_LOCATION = &"{HOME}/Dropbox/nim/NimPyKot/src"
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
rel         nim c -d:release                      compile [alias: release]
sm1         nim c -d:release --opt:size           small EXE [alias: small1]
sm2         sm1 + strip                           smaller EXE [alias: small2]
sm3         sm2 + upx                             smallest EXE [alias: small3]
ver         nim --version                         version info [aliases: v, version]
i                                                 interactive mode
h           help                                  more detailed help [alias: -h]
""".format(VERSION).strip

const FULL_HELP = """
alap        create alap.nim                       like basic.nim but with a different name
pykot       download pykot.nim                    a small Python / Kotlin -like library
jabba       alap + pykot + nimble                 bundles 3 steps
""".strip

const CONFIG_NIMS = """
switch("path", "lib")

# switch("define", "ssl")
# switch("passL", "-s")    # strip -s
""".strip

proc help() =
    echo HELP

proc full_help() =
  echo HELP
  echo ""
  echo FULL_HELP

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

proc compile(args: seq[string], output = true, release = false,
             small = false, strip = false): int =
  var
    options = ""
    src: string
    cmd: string

  if not output:
    options = "--hints:off --verbosity:0"
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
  execute_command(cmd.split)

# proc strip_exe(exe: string): int =
  # let cmd = &"strip -s {exe}"
  # execute_command(cmd.split, verify=true)

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
  compile(args, release=true, small=true, strip=true)
  # discard small1(args)
  # let exe = get_exe_name(args[1])
  # strip_exe(exe)

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

proc get_3rd_party_module_url(module_name: string): string =
  if not os.existsFile(PACKAGES_JSON):
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

proc create_basic_file(name=BASIC): int =
  let fname = &"{name}.nim"

  if existsFile(fname):
    echo &"# Warning: {fname} already exists"
    return 1
  # else, if basic.nim doest't exist
  if not existsFile(VSCODE_NIM_SNIPPET):
    writeFile(fname, BASIC_NIM_SOURCE)
    echo &"# a basic {fname} was created"
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
      writeFile(fname, BASIC_NIM_SOURCE)
      echo &"# a basic {fname} was created"
  
proc copy_pykot(): int =
  if existsDir(PYKOT_DIR_LOCATION):
    copyDir(PYKOT_DIR_LOCATION, "lib/")
    writeFile("config.nims", CONFIG_NIMS)
    echo "# the pykot lib. was copied to the current folder"
    result = EXIT_CODE_OK
  else:
    result = 1

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
    commands = sorted(toSeq(d.keys()), cmp[string])

  proc print_help() =
    for k, v in d:
      echo &"{k:12}->    {v}"
    echo "h, help     ->    help"
    echo "q           ->    quit"
    echo "m <module>  ->    open the stable docs of the given stdlib module"
    echo "m2 <module> ->    open the devel docs of the given stdlib module"
    echo "p <module> ->     open 3rd-party module using your local packages.json"

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
    params = args[1 .. args.high].join(" ")
    
  var exit_code = 0

  case param:
    of "ver", "v", "version":
      version_info()
    of "h", "-h":
      full_help()
    of "basic", "alap":
      exit_code = create_basic_file(name=param)
    of "pykot":    # visible only in fullhelp
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
    of "sm1", "small1":
      exit_code = small1(args)
    of "sm2", "small2":
      exit_code = small2(args)
    of "sm3", "small3":
      exit_code = small3(args)
    of "s", "script":
      exit_code = compile_run_delete_exe(args)
    of "i":
      interactive()
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
