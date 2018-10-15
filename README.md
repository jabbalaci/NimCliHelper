RodCli: a Nim CLI Helper
========================

Goal: make Nim development easier in the command-line

Help
----

```
$ rodcli
RodCli, a Nim CLI Helper v0.1.5
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
```

Usage
-----

Create a new project folder and initialize it:

```
$ rodcli init
```

It creates two files:
* an empty `basic.nim` for your source code
* a simplified `basic.nimble`

Then, I usually open the current folder in Visual Studio Code with `code .`, open `basic.nim`, and
using a [code snippet](https://github.com/jabbalaci/dotfiles/blob/master/.config/Code/User/snippets/nim.json),
I insert some Nim code that creates a basic skeleton that is compilable.

Compile and run:

```
$ rodcli cr basic.nim
```

Notes
-----

Currently it was only tested under Linux. I want to add Windows support too.
