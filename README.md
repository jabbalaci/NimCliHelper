RodCli: a Nim CLI Helper
========================

Goal: make Nim development easier in the command-line

Help
----

```
$ rodcli
RodCli, a Nim CLI Helper v0.1.6
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
h           help                                  more detailed help [alias: -h]
```

Usage
-----

Create a new project folder and initialize it:

```
$ rodcli init
```

It creates two files:
* a simple skeleton for your source code called `basic.nim`
* a simplified `basic.nimble`

Compile and run:

```
$ rodcli cr basic.nim
```

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

Windows is a first-class citizen, thus RodCli works under Windows too.

For editing a file, Notepad++ is used. If you need this feature, then add the
folder of Notepad++ to the PATH.

For shrinking the size of the EXE, `strip` and `upx` are used.
* If you install Nim from the official home page and run `finish.exe`
(see the [docs](https://nim-lang.org/install_windows.html)), then you'll
be asked if you want to install MingW, a C compiler. Say yes. On my
system `strip.exe` was installed here: `C:\nim\dist\mingw64\bin\strip.exe`.
I had to add the folder `C:\nim\dist\mingw64\bin` to my PATH.
* You can download UPX from [here](https://github.com/upx/upx/releases). Put `upx.exe`
somewhere in your PATH.
