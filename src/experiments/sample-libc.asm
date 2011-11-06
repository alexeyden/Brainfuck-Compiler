BITS 32

global _start
section .data
data:
	db 'cd'

section .text
_start:
;	;write 'c'
;	mov eax,1

;	push eax
;	mov ebx,1
;	mov ecx,data
;	add ecx,eax
;	mov edx,1  ;data size
;	mov eax,4
;	int 0x80
;	pop eax

	;read 1 byte
	push eax
	mov eax,1
	mov ebx,0
	mov ecx,data
	add ecx,eax
	mov edx,1
	mov eax,3
	int 0x80
	pop eax

	;exit 0
	mov ebx,0
	mov eax,1
	int 0x80
