	.globl _start
	.text
_start:
	movq $60, %rax
	xorq %rdi, %rdi
	syscall
