section .data
    ; Error 1 - sys_read fail
    err1 db "Error: Sys_read failed", 10
    len_err1 equ $ - err1

    err2 db "Error: Sys_mmap failed", 10
    len_err2 equ $ - err2
; ------------------------------------------
section .text
global _get_buffer_size
; ------------------------------------------
    ; Starting function
; ------------------------------------------
_get_buffer_size:
    sub rsp, 4096
    mov rsi, rsp
    xor r14, r14
    xor r15, r15
    ; -----
.find_input_length:
    mov rax, 0
    mov rdi, 0
    mov rdx, 4096
    syscall
    cmp rax, 0
    jl .handle_error1
    je .calc_buffer_size
    cmp rax, 4096
    je .reset_intake
    jl .partial_read
    ; -----
.reset_intake:
    xor rax, rax
    inc r15
    jmp .find_input_length
    ; -----
.partial_read:
    add r14, rax
    xor rax, rax
    jmp .find_input_length
; -------------------------------------------
    ; Error handling
; -------------------------------------------
.handle_error1: ; **local function. Idk why it's colored orange in my nvim**
    mov rsi, err1
    mov rdx, len_err1
    mov rdi, -1
    jmp .bad_exit

.handle_error2:
    mov rsi, err2
    mov rdx, len_err2
    mov rdi, -1
    jmp .bad_exit

.bad_exit:
    add rsp, 4096
    mov r12, rdi
    mov rax, 1
    mov rdi, 2
    syscall
    mov rax, 60
    mov rdi, r12
    syscall
; -------------------------------------------
    ; Build the array
; -------------------------------------------
.calc_buffer_size:
    add rsp, 4096
    imul r15, 4096 ; calculate buffer size
    add r15, r14 ; this gonna be the size of our buffer, dynamically allocated
    mov rax, 9
    mov rdi, 0
    mov rsi, r15
    mov rdx, 1 | 2
    mov r10, 0x20 | 0x02
    mov r8, -1
    mov r9, 0
    syscall
    cmp rax, 0
    jl .handle_error2
    ret
