.data
	data: .int $0x0
.text
	.global _start
	_start:
		movl $0xDEAD,(data)
		movl $1,%eax
		movl $0,%ebx
		int $0x80
