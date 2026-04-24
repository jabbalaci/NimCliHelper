RodCli: a Nim CLI Helper
========================

Goal: make Nim development easier in the command-line

Help
----

```
$ rod
RodCli, a Nim CLI Helper v0.2.3
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
jabba       alap+pykot+nimble+make+gi             Jabba's bundle
```

I suggest putting an alias on the binary `rodcli`. I use the alias `rod`.

Usage
-----

Create a new project folder and initialize it:

```
$ rodcli init
```

It creates two files:
* a simple skeleton for your source code called `basic.nim`
* a simplified `basic.nimble`

Installation
------------

```bash
$ nimble install rodcli
```

To install the latest development version, issue the following command:

```bash
$ nimble install "https://github.com/jabbalaci/NimCliHelper@#head"
```

With `nimble uninstall rodcli` you can remove the package.

Supported platforms
-------------------

RodCli was tested under Linux and Windows. It might also run on Mac OS;
I couldn't try it.

Windows support
---------------

RodCli works under Windows too.

For editing a file, Notepad++ is used. If you need this feature, then add the folder of Notepad++ to the PATH.
