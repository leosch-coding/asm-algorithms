global _get_buffer

default rel

; -----------------------------------------
section .bss
    statbuf resb 144
; -----------------------------------------
section .data
    err1_msg: db "Error: openat failed", 0xA
    err1_len: equ $ - err1_msg

    err2_msg: db "Error: fstat failed", 0xA
    err2_len: equ $ - err2_msg

    err3_msg: db "Error: mmap failed", 0xA
    err3_len: equ $ - err3_msg

    no_input_msg: db "No input provided", 0xA
    no_input_msg_len: equ $ - no_input_msg
; -----------------------------------------
section .text
_get_buffer:

    cmp rdi, 0
    jne .get_specific_buf

    cmp [rsp+24], 0
    je .no_input_provided

    ; openat - find file descriptor
    mov rax, 257
    mov rdi, -100
    mov rsi, [rsp+24] ; pointer to arg1
    mov rdx, 0
    syscall

    ; check for error
    cmp rax, 0
    jl .err1

    mov r8, rax

    ; fstat - find the file metadata
    mov rdi, rax
    mov rax, 5
    mov rsi, statbuf
    syscall
    ; check for error
    cmp rax, 0
    jl .err2 ; TBA

    ; mmap - allocate memory for usage
    mov rax, 9
    mov rdi, 0
    mov rsi, [statbuf+48]
    mov rdx, 1 | 2
    mov r10, 0x02
    mov r9, 0
    syscall

    cmp rax, 0
    jl .err3

    mov rdi, rsi

    ; rax == pointer to buffer
    ; rdi == size of file

    ret

.get_specific_buf:
    mov rax, 9
    mov rsi, rdi ; this puts N * 16 into rsi
    mov rdi, 0
    mov rdx, 1 | 2
    mov r10, 0x02
    mov r9, 0
    syscall

    cmp rax, 0
    jl .err3

    mov rdi, rsi

    ret
; ------------------------------------------
    ; Error Handling
; ------------------------------------------
.err1:
    mov rax, 1
    mov rdi, 2
    mov rsi, err1_msg
    mov rdx, err1_len
    syscall
    mov rax, 60
    mov rdi, -1
    syscall

.err2:
    mov rax, 1
    mov rdi, 2
    mov rsi, err2_msg
    mov rdx, err2_len
    syscall
    mov rax, 60
    mov rdi, -1
    syscall

.err3:
    mov rax, 1
    mov rdi, 2
    mov rsi, err3_msg
    mov rdx, err3_len
    syscall
    mov rax, 60
    mov rdi, -1
    syscall

.no_input_provided:
    mov rax, 1
    mov rdi, 2
    mov rsi, no_input_msg
    mov rdx, no_input_msg_len
    syscall
    mov rax, 60
    mov rdi, -1
    syscall
