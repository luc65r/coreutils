	.set	BUF_LEN, 8192

	.bss
char_buf:
	.fill	BUF_LEN


	.globl	_start
	.text
_start:
	movq	(%rsp), %r12 # argc
	cmpq	$1, %r12
	je	no_args

	xorq	%r15, %r15
	leaq	8(%rsp), %r13 # argv
arg_loop:
	addq	$8, %r13
	decq	%r12
	jz	exit

	movq	(%r13), %rdi # filename

	test	%r15, %r15
	jnz	bypass_options

	cmpb	$'-', (%rdi)
	je	option_or_stdin

bypass_options:
	movq	$2, %rax # sys_open
	xorq	%rsi, %rsi # flags
	xorq	%rdx, %rdx # mode
	syscall

	cmpq	$0, %rax
	jl	arg_loop
	movq	%rax, %rdi # fd
	movq	%rax, %rbx
	call	cat

	movq	$3, %rax # sys_close
	movq	%rbx, %rdi # fd
	syscall

	jmp	arg_loop


option_or_stdin:
	cmpb	$'-', 1(%rdi)
	sete	%r15b
	cmpb	$0, 1(%rdi)
	je	stdin
	jmp	arg_loop
stdin:
	xorq	%rdi, %rdi
	call	cat
	jmp	arg_loop


no_args:
	xorq	%rdi, %rdi
	call	cat

exit:
	movq	$60, %rax
	xorq	%rdi, %rdi
	syscall


	/* Reads from fd and writes to stdout until EOF or error.

	   %rdi: fd
	*/
cat:
	/* We use %r12 to store the fd */
	pushq	%r12
	movq	%rdi, %r12

cat_read:
	xorq	%rax, %rax # sys_read
	movq	%r12, %rdi # fd
	movq	$char_buf, %rsi # buf
	movq	$BUF_LEN, %rdx # count
	syscall

	cmpq	$0, %rax
	jle	cat_end

	movq	%rax, %rdx # count
	movq	$1, %rax # sys_write
	movq	$1, %rdi # fd
	movq	$char_buf, %rsi # buf
	syscall

	jmp	cat_read

cat_end:
	popq	%r12
	ret
