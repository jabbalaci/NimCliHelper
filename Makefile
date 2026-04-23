fname := rodcli.nim

cat:
	cat Makefile

setup:
	nimble setup

c: setup
	nim c ${fname}

rel: setup
	nim c -d:release ${fname}

small: setup
	nim c -d:release --opt:size --passL:-s ${fname}

install:
	nimble install

clean:
	rm -f ./rodcli
	rm -f ./rodcli.exe
