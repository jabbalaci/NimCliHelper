Nim CLI Helper
==============

Goal: facilitate Nim development in the command-line.

Help
----

```
$ rod
Nim CLI Helper v0.1.0
=====================
option            what it does                         notes
------            ------------                         -----
init              bundles the indented steps below     initialize a project folder
  alap            touch alap.nim                       create an empty source file
  pykot           copy pykot.nim .                     copy pykot.nim to the current dir.
  nim_ver         nim --version > nim_version.txt      stage Nim's version in a file
c                 nim c                                compile
cr                nim c -r                             compile and run
s                                                      compile, run, then delete the exe
                                                       i.e., run it as if it were a script
ver               nim --version                        version info
```

Usage
-----

Create a new project folder and initialize it:

```
$ rod init
```

It'll create an empty source file called `alap.nim`; it copies my small
[pykot library](https://github.com/jabbalaci/nimpykot) to the project folder
(as I use it in almost all my Nim projects); and Nim's version is staged in a text file,
which can be useful if your project doesn't compile with a future version of Nim.

Then, I usually open the current folder in Visual Studio Code with `code .`, open `alap.nim`, and
using a [code snippet](https://github.com/jabbalaci/dotfiles/blob/master/.config/Code/User/snippets/nim.json),
I insert some Nim code that creates a basic skeleton that is compilable.

Compile and run:

```
$ rod cr alap.nim
```

Notes
-----

The word "alap" means "basic" in Hungarian. So if you want, you can rename `alap.nim` to `basic.nim`.
