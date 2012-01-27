DC=dmd

EXE_BFC=bfc
SRC_BFC=main.d compiler.d interpreter.d parser.d file_format.d codegen.d eval_loop.d

BIN_PATH=../bin
OBJ_PATH=../bin/obj

all: compiler

compiler: $(SRC_BFC)
	$(DC) -of$(BIN_PATH)/$(EXE_BFC) -od$(OBJ_PATH) $(SRC_BFC)

clean:
	rm -Rf $(OBJ_PATH)/*.o
