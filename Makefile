cat:
	cat Makefile

setup:
	nimble setup

c: setup
	nim c rodcli.nim

rel: setup
	nim c -d:release -d:quick --opt:size rodcli.nim
	strip -s rodcli

install:
	nimble install

clean:
	rm -f ./rodcli
	rm -f ./rodcli.exe
