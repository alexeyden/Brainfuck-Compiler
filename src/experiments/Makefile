output:
	nasm -f elf sample-libc.asm
	ld sample-libc.o -o sample-libc-asm

sample:
	nasm -f elf sample-code.asm
	ld sample-code.o -o sample-code


clean:
	rm *.o
