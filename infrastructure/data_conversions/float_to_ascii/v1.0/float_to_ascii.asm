; -----------------------------------------------
    ; rax == dividend
    ; rbx == counter of how many times we shove stuff onto the stack
    ; rdx == remainder
    ; rcx == counter/size of output
    ; r8 == current variable holder
    ; r9 == scratchpad
    ; r10 == current exponent to the power of two of float
    ; r11 == current fractional value of float
    ; r12 == m/b state
    ; r13 == ascii character
    ; r14 == pointer to digit table
    ; r15 == negative yes or no
; -----------------------------------------------
section .rodata
    digits db "0123456789"
    ten db 10.0
; -----------------------------------------------
section .bss
global output_buffer
    output_buffer resb 40
; -----------------------------------------------
section .text
global _float_to_ascii_m
; -----------------------------------------------
    ; Initialize
; -----------------------------------------------
_float_to_ascii_m:
    xor rbx, rbx
    movq r8, xmm10
    jmp .find_value

_float_to_ascii_b:
    xor rbx, rbx
    movq r8, xmm1
    jmp .find_value
; -----------------------------------------------
    ; Handle edge cases
; -----------------------------------------------
.find_value:
    ; stores 10.0 for multiplication later
    mov xmm2, [ten]

    ; copy our current variable three times for isolating the different parts of the float
    mov r15, r8
    mov r10, r8
    mov r11, r8

    ; r9 holds what sign the float is
    shr r15, 63
    
    ; r10 holds what exponent to the power of two the float is
    shr r10, 52
    and r10, 0x7FF

    ; r11 holds the fractional part of the float
    and r11, 0x000FFFFFFFFFFFFF

    ; check for 0
    cmp r10, 0
    je .zero_or_subnormal

    ; check for infinity/nan
    cmp r10, 0x7FF
    je .inf_or_nan

    ; if neither of the two above, it's a finite digit
    jmp .split_int_and_decimal
; ----------------------------------------------
    ; isolate int and dec
; ----------------------------------------------
.split_int_and_decimal:
    
    ; stores our current float for safekeeping
    movsd xmm0, xmm10

    ; converts our float into an integer, zeroing out all decimals
    cvttsd2si r8, xmm0

    mov r9, r8 ; stores our int value for safekeeping

    ; convert our integer back into a float, but with no decimals
    cvtsi2sd xmm0, r8

    ; store the dec-less float 
    movsd xmm11, xmm0 

    ; finds our decimals
    subsd xmm10, xmm0

    mov rax, r9
    mov r9, 10
    jmp .find_isolated_int:
; ---------------------------------------------
    ; isolate n digit of int/dec
; ---------------------------------------------
.find_isolated_int:
    xor rdx, rdx
    div r9

    ; push to the stack
    push rdx

    inc rbx

    cmp rax, 0
    je .convert_int_to_ascii
    jmp .find_isolated_int
; ---------------------------------------------
.find_isolated_dec:
    ; stores our original decimal for safekeeping
    movsd xmm0, xmm10

    ; multiply the decimal by 10
    mulsd xmm0, [ten]
    cvttsd2si r8, xmm0

    mov r9, r8

    cvtsd2si r8, xmm0

    subsd xmm0, xmm10

    push r9

    cmp xmm10, 0.0
    je .convert_dec_to_ascii
    jmp .find_isolated_dec
; ---------------------------------------------
.convert_int_to_ascii:
    cmp r15, 1
    jne .negative
    cmp rbx, 0
    je .add_decimal_point
    lea r14 [rel digits]
    pop r9
    mov r13b, [r14+r9]
    mov [output_buffer+rcx], r13b
    inc rcx
    dec rbx
    jmp .convert_int_to_ascii

.convert_dec_to_ascii:
    cmp rbx, 0
    je .move_to_b
    lea 
    pop r9
    mov r13, [r14+r9]
    mov [output_buffer+rcx], r13
    inc rcx
    dec rbx
    jmp .convert_dec_to_ascii

.negative:
    mov [output_buffer+rcx], '-'
    inc rcx
    jmp .convert_int_to_ascii

.add_decimal_point:
    mov [output_buffer+rcx], '.'
    inc rcx
    xor rbx, rbx
    jmp .find_isolated_dec

.move_to_b:
    cmp r12, 1
    je .return
    mov r12, 1
    jmp _float_to_ascii_b

.return:
    ret 
; -----------------------------------------------
    ; * WIP *
; -----------------------------------------------
    ; Handling edge cases
; -----------------------------------------------
.zero_or_subnormal:
    test r11, r11
    jz .zero
    jmp .finite_digit
; -----------------------------------------------
.inf_or_nan:
    test r11, r11
    jz .infinity
    jmp .nan
; -----------------------------------------------
.infinity:
    mov r8, "infinity"
    cvtsi2sd xmm4, r8
    cmp r12, 1
    je .return
    jmp .
; -----------------------------------------------
.nan:
    mov r8, "nan"
    cvtsi2sd xmm4, r8
    cmp r12, 1
    je .return
    jmp .float_to_ascii_b
; -----------------------------------------------
.zero:
    mov r8, "0.0"
    cvtsi2sd xmm4, r8
    cmp r12, 1
    je .return
    jmp .float_to_ascii_b
; -----------------------------------------------
