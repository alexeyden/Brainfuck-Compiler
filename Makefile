DC=dmd
EXE_BFC=bfc
SRC_BFC=src/main.d src/compiler.d src/interpreter.d src/parser.d src/file_format.d src/codegen.d

all: compiler

compiler: $(SRC_BFC)
	$(DC) -ofbin/$(EXE_BFC) -odbin/obj $(SRC_BFC)

clean:
	rm -Rf bin/obj/*.o
