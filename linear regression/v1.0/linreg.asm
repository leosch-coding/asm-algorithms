section .text
global _start
; -------------------------------------------------------------------------------------
_start:
    xor r15, r15
  ; FLOATS
    ; xmm0 == acc. of x
    ; xmm1 == acc. of y
    ; xmm2 == acc. of xy
    ; xmm3 == acc. of x^2
    ; xmm4 == x
    ; xmm5 == y

    ; r15 == counter
; -------------------------------------------------------------------------------------
loop:
    sub rsp, 16 ; reserves 16 bytes for our float input
    mov rsi, rsp ; points the buffer pointer to the stack, ensuring when we take data, it gets set to the stack instantly

    ; [rsp] == x
    ; [rsp+8] == y
    mov rdx, 16 ; sets the max amount of bytes allowed to be processed at once
    mov rdi, 0 ; default

    ; sys_read
    mov rax, 0 
    syscall
    xor rcx, rcx
    cmp rax, 0  ; check if there's anything else and if it errored
    je simplify ; there's no more data, simplfy the accumulations
    jl error ; syscall returned -1, there's an error

    cmp rax, 16 ; check if read has recieved a partial value
    je accumulate ; there's still data remaining, accumulate the new values
    jl simplify ; read has recieved a partial value. Skip the accumulation as to not get corrupted
; -------------------------------------------------------------------------------------
accumulate:
    
    xorpd xmm4, xmm4
    xorpd xmm5, xmm5

    movsd xmm4, [rsi] ; moving current x value into FP register as scalar double precision
    movsd xmm5, [rsi+8] ; moving y value into FP register as a scalar double precision

    ; Accumulate x and y
    addsd xmm0, xmm4
    addsd xmm1, xmm5

    ; Accumulate xy
    mulsd xmm5, xmm4
    addsd xmm2, xmm5

    ; Accumulate x^2
    mulsd xmm4, xmm4
    addsd xmm3, xmm4

    ; restore stack
    add rsp, 16

    ; increment counter
    inc r15

    jmp loop
; --------------------------------------------------------------------------------------
simplify:
    
    xorpd xmm8, xmm8
    ucomisd xmm2, xmm8 ; *********
    je error
    jl error

    ; restore stack
    add rsp, 16

    movsd xmm6, xmm0 ; saves acc of x
    mulsd xmm6, xmm6 ; gets (acc of x)^2

    cvtsi2sd xmm15, r15 ; converts counter to double precision float
    mulsd xmm3, xmm15 ; gets n(acc of x^2)

    subsd xmm3, xmm6

    ; check for DbZ 
    ucomisd xmm3, xmm8 ; **********
    je error

    ; xmm3 == D
    
    xorpd xmm6, xmm6
    movsd xmm6, xmm0 ; saves acc of x
    movsd xmm7, xmm1 ; saves acc of y
    mulsd xmm6, xmm7 ; gets (acc of x)(acc of y)
    mulsd xmm2, xmm15 ; gets n(acc of xy)

    subsd xmm2, xmm6

    ; xmm2 == N

    xorpd xmm6, xmm6
    xorpd xmm7, xmm7
    movsd xmm6, xmm0 ; saves acc of x
    movsd xmm7, xmm1 ; saves acc of y

    ; prep for division
    movsd xmm0, xmm2
    movsd xmm1, xmm3

    divsd xmm0, xmm1

    movsd xmm10, xmm0

    ; m == xmm10

    mulsd xmm6, xmm10 ; gets n(acc of x)
    subsd xmm7, xmm6 ; gets (acc of y) - m(acc of x)

    xorpd xmm0, xmm0
    xorpd xmm1, xmm1
    movsd xmm0, xmm7
    movsd xmm1, xmm15
    divsd xmm0, xmm1

    movsd xmm11, xmm0

    ; b == xmm11

    jmp exit
; ------------------------------------------------------------------------------------
error:
    mov rax, 60
    mov rdi, -1
    syscall
; ------------------------------------------------------------------------------------
exit:
     sub rsp, 16
     mov rsi, rsp
     movsd [rsp], xmm10
     movsd [rsp+8], xmm11
     mov rdx, 16
     mov rdi, 1
     mov rax, 1
     syscall
     add rsp, 16
     mov rax, 60
     mov rdi, 0
     syscall
; -------------------------------------------------------------------------------------
