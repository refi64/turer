# turer.mk

BF interpreter in (mostly) pure GNU makefile. We have to shell out for printing and reading
sadly, but everything else is 100% make.

## Usage

Call `make -f turer.mk FILE=some-file.b`, e.g. `make -f turer.mk FILE=../examples/hello.b`.
