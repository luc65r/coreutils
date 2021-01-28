	.globl _start
	.text
_start:
	movq $60, %rax
	movq $1, %rdi
	syscall
