cat:
	cat Makefile

setup:
	nimble setup

c: setup
	nim c rodcli.nim

rel: setup
	nim c -d:release rodcli.nim

install:
	nimble install

clean:
	rm -f ./rodcli
	rm -f ./rodcli.exe
