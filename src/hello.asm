bits 64
org 0x08048000

    [map]
section .rodata align=0x1000
ehdr:                           ; Elf64_Ehdr
    db 0x7F, "ELF", 2, 1, 1, 0  ; e_ident
    times 8 db 0
    dw 2                        ; e_type
    dw 62                       ; e_machine
    dd 1                        ; e_version
    dq _start                   ; e_entry
    dq text_phdr - $$           ; e_phoff
    dq 0                        ; e_shoff
    dd 0                        ; e_flags
    dw ehdr_size                ; e_ehsize
    dw text_phdr_size           ; e_phentsize
    dw 3                        ; e_phnum
    dw 0                        ; e_shentsize
    dw 0                        ; e_shnum
    dw 0                        ; e_shstrndx

    ehdr_size equ $ - ehdr

rodata_phdr:
    dd 1
    dd 4
    dq 0
    dq $$
    dq $$
    dq rodata_size
    dq rodata_size
    dq 0x1000
    

text_phdr:                      ; Elf64_Phdr
    dd 1                        ; p_type
    dd 5                        ; p_flags
    dq section..text.start - $$                        ; p_offset
    dq section..text.start                       ; p_vaddr
    dq section..text.start                       ; p_paddr
    dq text_size                ; p_filesz
    dq text_size                ; p_memsz
    dq 0x1000                   ; p_align

    text_phdr_size equ $ - text_phdr

data_phdr:
    dd 1
    dd 6
    dq section..data.start - $$
    dq section..data.start
    dq section..data.start
    dq data_size
    dq data_size + bss_size
    dq 0x1000

    rodata_size equ $ - $$

section .text align=0x1000 follows=.rodata
_start:
    mov eax, 1
    mov edi, 1
    mov rsi, string
    mov edx, string.len
    syscall

    mov eax, 60
    xor edi, edi
    syscall

    text_size equ $ - $$

section .data align=0x1000 follows=.text
    
string: db "Hello, world!", 0x0A
.len: equ $ - string
    data_size equ $ - $$
    
section .bss follows=.data
    bss_size equ $ - $$
