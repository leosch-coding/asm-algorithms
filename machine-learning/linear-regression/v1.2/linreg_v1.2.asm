section .data
    err1_msg: db "Error: rsi reached negative value", 0xA
    err1_len: equ $ - err1_msg

    err2_msg: db "Error: Divide by zero", 0xA
    err2_len: equ $ - err2_msg

section .text
global _process_values
; -------------------------------------------------------------------------------------
_process_values:
    xorpd xmm0, xmm0
    xorpd xmm1, xmm1
    xorpd xmm2, xmm2
    xorpd xmm3, xmm3
    xorpd xmm8, xmm8
    xor r14, r14
    xor r15, r15
    ; rdi == pointer to buffer
    ; rcx == number of loops to do
    ; FLOATS
    ; xmm0 == acc. of x
    ; xmm1 == acc. of y
    ; xmm2 == acc. of xy
    ; xmm3 == acc. of x^2
    ; xmm4 == x
    ; xmm5 == y
    ; r15 == counter
; -------------------------------------------------------------------------------------
.loop:
    cmp rcx, 0  ; check if there's anything else and if it errored
    je .simplify ; there's no more data, simplfy the accumulations
    jl .err1 ; Got to -1 somehow, there's an error

    movsd xmm4, [rdi+r14] ; moving current x value into FP register as scalar double precision
    movsd xmm5, [rdi+r14+8] ; moving y value into FP register as a scalar double precision

    ; Accumulate x and y
    addsd xmm0, xmm4
    addsd xmm1, xmm5

    ; Accumulate xy
    mulsd xmm5, xmm4
    addsd xmm2, xmm5

    ; Accumulate x^2
    mulsd xmm4, xmm4
    addsd xmm3, xmm4

    ; decrement counter
    sub rcx, 16

    ; add 16 to our offset
    add r14, 16

    inc r15

    jmp .loop
; --------------------------------------------------------------------------------------
.simplify:

    movsd xmm6, xmm0 ; saves acc of x
    mulsd xmm6, xmm6 ; gets (acc of x)^2

    cvtsi2sd xmm15, r15 ; converts counter to double precision float
    mulsd xmm3, xmm15 ; gets n(acc of x^2)

    subsd xmm3, xmm6

    ; check for DbZ 
    ucomisd xmm3, xmm8
    je .err2

    ; xmm3 == D
    
    movsd xmm6, xmm0 ; saves acc of x
    movsd xmm7, xmm1 ; saves acc of y
    mulsd xmm6, xmm7 ; gets (acc of x)(acc of y)
    mulsd xmm2, xmm15 ; gets n(acc of xy)

    subsd xmm2, xmm6

    ; xmm2 == N

    ; prep for division
    movsd xmm6, xmm2
    movsd xmm7, xmm3

    divsd xmm6, xmm7

    movsd xmm10, xmm6

    ; m == xmm10 as of current

    mulsd xmm0, xmm10 ; gets n(acc of x)
    subsd xmm1, xmm0 ; gets (acc of y) - m(acc of x)

    divsd xmm1, xmm15

    ; b == xmm1
    ; m == xmm0
    movsd xmm0, xmm10

    ret 
; ------------------------------------------------------------------------------------
    ; Error handling
; ------------------------------------------------------------------------------------
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
; ------------------------------------------------------------------------------------

