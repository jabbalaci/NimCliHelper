#!/usr/bin/env python3

"""
Nim CLI Helper

Goal: facilitate Nim development in the command-line.

by Laszlo Szathmary (jabba.laci@gmail.com), 2018
"""

import json
from glob import glob
import os
import shlex
import shutil
import sys
from glob import glob
from pathlib import Path
from subprocess import PIPE, STDOUT, Popen

VERSION = "0.1.2"

EXIT_CODE_OK = 0

EDITOR = "vim"

CURRENT_DIR_NAME = Path(os.getcwd()).name

# pykot is my small Python / Kotlin library, see https://github.com/jabbalaci/nimpykot
PYKOT_LOCATION = "{home}/Dropbox/nim/NimPyKot/src/pykot.nim".format(home=os.path.expanduser("~"))

VSCODE_NIM_SNIPPET = "{home}/.config/Code/User/snippets/nim.json".format(home=os.path.expanduser("~"))

NIMBLE = """
# Package

version       = "0.1.0"
author        = "..."
description   = "..."
license       = "MIT"
# srcDir        = "src"
# bin           = @["alap"]


# Dependencies

requires "nim >= 0.19.0"
""".strip()


class MissingSourceFileException(Exception):
    pass


class ExistingFileException(Exception):
    pass



def usage():
    print("""
Nim CLI Helper v{ver}
=====================
option            what it does                          notes
------            ------------                          -----
init              bundles the indented 3 steps below    initialize a project folder
  alap            create alap.nim                       create a skeleton source file
  pykot           copy pykot.nim .                      copy pykot.nim to the current dir.
  nimble          simplified nimble init                create a simple .nimble file
ad                edit .nimble                          add dependency
id                nimble install -d                     install dependencies (and nothing else)
                                                        (like `pip install -r requirements.txt`)
c                 nim c                                 compile (debug)
cr                nim c -r                              compile and run
s                                                       compile, run, then delete the exe
                                                        i.e., run it as if it were a script
rel               nim c -d:release                      compile (release)
small1            nim c -d:release --opt:size           small EXE
small2            small1 + strip                        smaller EXE
small3            small2 + upx                          smallest EXE
ver               nim --version                         version info
""".strip().format(ver=VERSION))


def execute_command(cmd, debug=True, sep=False):
    """
    Execute a simple external command and return its exit status.
    """
    if debug:
        print('#', cmd)
    if sep:
        print("-" * 78)
    args = shlex.split(cmd)
    child = Popen(args)
    child.communicate()
    return child.returncode


def get_simple_cmd_output(cmd, stderr=STDOUT):
    """
    Execute a simple external command and get its output.

    The command contains no pipes. Error messages are
    redirected to the standard output by default.
    """
    args = shlex.split(cmd)
    return Popen(args, stdout=PIPE, stderr=stderr).communicate()[0].decode("utf8")


def get_version_info():
    return get_simple_cmd_output("nim --version").splitlines()[0]
    print(nim)


def version_info():
    print(get_version_info())


def create_alap_file():
    fname = "alap.nim"
    if os.path.isfile(fname):
        raise ExistingFileException("alap.nim exists")
    # else
    if not os.path.isfile(VSCODE_NIM_SNIPPET):
        execute_command(f"touch {fname}")
        print(f"# an empty {fname} was created")
    else:
        try:
            with open(VSCODE_NIM_SNIPPET) as f:
                doc = json.load(f)
            body = doc['alap']['body']
            with open(fname, "w") as to:
                for line in body:
                    line = line.replace("$0", "")
                    print(line, file=to)
            #
            print(f"# {fname} was created using your VS Code Nim snippet")
        except Exception as e:
            print(f"# Warning: couldn't process the file {VSCODE_NIM_SNIPPET}", file=sys.stderr)
            print("#", e, file=sys.stderr)
            execute_command(f"touch {fname}")
            print(f"# an empty {fname} was created")


def copy_pykot():
    if not os.path.isfile(PYKOT_LOCATION):
        print(f"# Warning: {PYKOT_LOCATION} was not found")
        return
    # else
    fname = "pykot.nim"
    if os.path.isfile(f"./{fname}"):
        print(f"# {fname} exists in the current folder, deleting it")
        os.remove(f"./{fname}")
    shutil.copy(PYKOT_LOCATION, ".")
    print(f"# {fname}'s latest version was copied to the current folder")


def nimble():
    fname = "alap.nimble"
    if os.path.isfile(f"{fname}"):
        print(f"# Warning: {fname} already exists")
        return
    # else
    with open(fname, "w") as f:
        print(NIMBLE, file=f)
    #
    print(f"# {fname} was created")


def compile(args, output=True, release=False, small=False):
    options = ""
    if not output:
        options = "--hints:off --verbosity:0"
    try:
        src = args[1]
    except:
        print("Error: provide the source file too!", file=sys.stderr)
        print(f"Tip: rod c <input.nim>", file=sys.stderr)
        return 1
    # else
    cmd = f'nim {options} c {src}'
    if release:
        cmd = f'nim {options} c -d:release {src}'
    if small:
        cmd = f'nim {options} c -d:release --opt:size {src}'
    exit_code = execute_command(cmd)
    return exit_code


def get_exe_name(p):
    # under Linux
    return str(Path(p.stem))


def run_exe(exe, params):
    params = " ".join(params)
    cmd = f"./{exe} {params}"
    exit_code = execute_command(cmd, sep=True)
    return exit_code


def strip_exe(exe):
    return execute_command(f"strip {exe}")


def upx_exe(exe):
    return execute_command(f"upx {exe}")


def delete_exe(exe):
    p = Path(exe)
    if p.exists() and p.is_file() and p.suffix != ".nim":
        # print(f"# remove {str(p)}")
        p.unlink()
    return not p.exists()


def small1(args):
    return compile(args, release=True, small=True)


def small2(args):
    small1(args)
    p = Path(args[1])
    exe = get_exe_name(p)
    strip_exe(exe)


def small3(args):
    small2(args)
    p = Path(args[1])
    exe = get_exe_name(p)
    upx_exe(exe)


def find_nimble_file():
    found = glob("*.nimble")
    if len(found) == 1:
        return found[0]
    # else
    return None


def add_dependency():
    nimble_file = find_nimble_file()
    if nimble_file is None:
        print("# Error: no .nimble file was found", file=sys.stderr)
        return
    # else
    execute_command(f"{EDITOR} {nimble_file}")


def install_dependencies():
    execute_command("nimble install -d")


def process(args):
    param = args[0]
    params = " ".join(args[1:])
    exit_code = 0
    #
    if param == "init":
        try:
            create_alap_file()
            copy_pykot()
            nimble()
        except Exception as e:
            print("Error:", e)
    elif param == 'alap':
        try:
            create_alap_file()
        except Exception as e:
            print("Error:", e)
    elif param == 'pykot':
        copy_pykot()
    elif param == "nimble":
        nimble()
    elif param == "ad":
        add_dependency()
    elif param == "id":
        install_dependencies()
    elif param == 'c':
        exit_code = compile(args)
    elif param == 'rel':
        exit_code = compile(args, release=True)
    elif param == 'small1':
        exit_code = small1(args)
    elif param == 'small2':
        exit_code = small2(args)
    elif param == 'small3':
        exit_code = small3(args)
    elif param == 'cr':
        exit_code = compile(args)
        if exit_code != EXIT_CODE_OK:
            return exit_code
        # else
        p = Path(args[1])
        exe = get_exe_name(p)
        exit_code = run_exe(exe, args[2:])
    elif param == 's':
        try:
            p = Path(args[1])
            if p.suffix != ".nim":
                raise MissingSourceFileException
        except:
            print("Error: provide a source file!", file=sys.stderr)
            print(f"Tip: rod s <input.nim>", file=sys.stderr)
            return 1
        exit_code = compile(args, output=False)
        if exit_code != EXIT_CODE_OK:
            return exit_code
        # else
        p = Path(args[1])
        exe = get_exe_name(p)
        try:
            run_exe(exe, args[2:])
        finally:
            exit_code = delete_exe(exe)
    elif param == 'ver':
        version_info()
    else:
        print("Error: unknown parameter")
    #
    return exit_code


def main():
    if len(sys.argv) == 1:
        usage()
        return 0
    # else
    return process(sys.argv[1:])

##############################################################################

if __name__ == "__main__":
    exit(main())
