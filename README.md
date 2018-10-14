RodCli: a Nim CLI Helper
========================

Goal: facilitate Nim development in the command-line

Help
----

```
$ rodcli
RodCli, a Nim CLI Helper v0.1.4
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
```

Usage
-----

Create a new project folder and initialize it:

```
$ rodcli init
```

It'll create a skeleton source file called `alap.nim`, it copies my small
[pykot library](https://github.com/jabbalaci/nimpykot) to the project folder
(as I use it in almost all my Nim projects), and a simplified `.nimble` file
is also created.

Then, I usually open the current folder in Visual Studio Code with `code .`, open `alap.nim`, and
using a [code snippet](https://github.com/jabbalaci/dotfiles/blob/master/.config/Code/User/snippets/nim.json),
I insert some Nim code that creates a basic skeleton that is compilable.

Compile and run:

```
$ rodcli cr alap.nim
```

Notes
-----

Currently it was only tested under Linux. I want to add Windows support too.

The word "alap" means "basic" in Hungarian. So if you want, you can rename `alap.nim` to `basic.nim`.
