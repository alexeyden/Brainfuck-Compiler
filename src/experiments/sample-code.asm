BITS 32

global _start

section .data
	data: dd 01 ;4 
		  dd 00 ;8
		  dd 00 ;12
		  dd 00 ;16
		  
section .text
_start:
	xor eax,eax
	cmp eax,0
	je near gogo
	nop
	nop
	nop
	gogo:
	mov eax,1
	mov ebx,0
	int 0x80
