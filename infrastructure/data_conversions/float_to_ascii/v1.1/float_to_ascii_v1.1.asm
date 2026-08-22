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

    ; xmm0 == original m value
    ; xmm1 == original b value
    ; xmm10 current value to work with
; -----------------------------------------------
default rel 
; -----------------------------------------------
section .rodata
    digits db "0123456789"
    ten db 10.0
; -----------------------------------------------
section .bss
global output_buffer
    output_buffer resb 60
; -----------------------------------------------
section .text
global _float_to_ascii_m
; -----------------------------------------------
    ; Initialize
; -----------------------------------------------
_float_to_ascii_m:
    xor rbx, rbx
    movq r8, xmm0
    movsd xmm10, xmm0
    jmp .find_value

.float_to_ascii_b:
    xor rbx, rbx
    movq r8, xmm1
    movsd xmm10, xmm1
    jmp .find_value
; -----------------------------------------------
    ; Handle edge cases
; -----------------------------------------------
.find_value:
    ; stores 10.0 for multiplication later
    movsd xmm2, [ten]

    ; copy our current variable three times for isolating the different parts of the float
    mov r15, r8
    mov r10, r8
    mov r11, r8

    ; r15 holds what sign the float is
    shr r15, 63
    
    ; r10 holds what exponent to the power of two the float is
    shr r10, 52
    and r10, 0x7FF

    mov r9, 0x000FFFFFFFFFFFFF

    ; r11 holds the fractional part of the float
    and r11, r9

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
    movsd xmm3, xmm10

    ; converts our float into an integer, zeroing out all decimals
    cvttsd2si r8, xmm3

    ; stores our int value for division
    mov rax, r8

    ; convert our integer back into a float, but with no decimals
    cvtsi2sd xmm3, r8

    ; finds our decimals
    subsd xmm10, xmm3

    ; stores 10 into r9, the divisor
    mov r9, 10
    jmp .find_isolated_int
; ---------------------------------------------
    ; isolate n digit of int/dec
; ---------------------------------------------
.find_isolated_int:
    xor rdx, rdx

    ; divide by 10
    div r9

    ; pushes our remainder to the stack, aka, the last number in the int
    push rdx

    ; keep track of how many pushes we've made
    inc rbx

    ; check if our quotient is 0
    cmp rax, 0
    je .convert_int_to_ascii
    jmp .find_isolated_int
; ---------------------------------------------
.find_isolated_dec:
    ; stores our original decimal for safekeeping
    movsd xmm3, xmm10

    ; multiply the decimal by 10
    mulsd xmm3, [ten]

    ; stores decimal value for later
    movsd xmm10, xmm3

    ; converts decimal float value into an int, zeroing out all decimal places
    cvttsd2si r8, xmm3

    ; stores decimal int value in order to push it to the stack safely
    mov r9, r8
    push r9
    
    ; increment our counter of how many pushes we've made
    inc rbx

    ; converts int decimal value into a float again
    cvtsi2sd xmm8, r8

    ; subtracts the integer part of the float by the integer part of the float that is zeroed out, removing the decimal place for the next loop
    subsd xmm10, xmm3

    ; converts xmm7 to 0 for comparison
    xorpd xmm7, xmm7

    ; checks if xmm0 is 0 yet, if so, jump to ascii conversion
    ucomisd xmm10, xmm7
    je .convert_dec_to_ascii
    jmp .find_isolated_dec
; ---------------------------------------------
.convert_int_to_ascii:

    ; checks if we're dealing with a negative number, if so, add a '-' infront 
    test r15, r15
    jnz .negative

    ; checks if we have finished poping all our values off the stack, if so, add a decimal point
    cmp rbx, 0
    je .add_decimal_point

    ; load the effective address of 'digits' into r14
    lea r14, [digits]

    ; pop r9 off the stack, as the stack pops in reverse order it's pushed, we use this to output ascii chars to the correct order
    pop r9

    ; index r14 with r9 to find the corresponding ascii digit, move that into r13b
    mov r13b, [r14+r9]

    ; store the value in r13b (our ascii digit) into the output buffer, with the offset of our counter, rcx
    mov [output_buffer+rcx], r13b

    ; increments our offset-measurer
    inc rcx

    ; decrements our counter of how many pops we have left to go before moving on
    dec rbx

    ; loops
    jmp .convert_int_to_ascii
; ----------------------------------------------
.convert_dec_to_ascii:
    
    cmp rbx, 0
    je .move_to_b 

    ; Same thing as previous
    lea r14, [digits]
    pop r9
    mov r13b, [r14+r9]
    mov [output_buffer+rcx], r13b
    inc rcx
    dec rbx

    ; loops
    jmp .convert_dec_to_ascii

.negative:
    ; if our number is negative, we add a negative sign 
    mov [output_buffer+rcx], '-'

    ; reset negative state

    mov r15, 0

    ; account for the offset
    inc rcx
    jmp .convert_int_to_ascii

.add_decimal_point:
    ; if we have outputted all integers of our value, add a decimal point
    mov [output_buffer+rcx], '.'

    ; account for the offset
    inc rcx

    jmp .find_isolated_dec

.move_to_b:

    ; compares our m/b state, if we just outputted the b value, then we're done
    cmp r12, 1
    je .return

    ; adds a comma between m and b
    mov [output_buffer+rcx], ','

    ; accounts for the offset
    inc rcx

    ; compares our m/b state, if we just outputted the b value, then we are finished
    cmp r12, 1
    je .return

    ; otherwise, move onto b
    mov r12, 1
    jmp .float_to_ascii_b

.return:
    mov [output_buffer+rcx], 0x0a
    inc rcx
    ret 
; -----------------------------------------------
    ; Handling edge cases
; -----------------------------------------------
.zero_or_subnormal:
    test r11, r11
    jz .zero
    jmp .split_int_and_decimal
; -----------------------------------------------
.inf_or_nan:
    test r11, r11
    jz .infinity
    jmp .nan
; -----------------------------------------------
.infinity:
    mov [output_buffer+rcx], 'i'
    inc rcx
    mov [output_buffer+rcx], 'n'
    inc rcx
    mov [output_buffer+rcx], 'f'
    inc rcx
    cmp r12, 1
    je .return
    jmp .move_to_b
; -----------------------------------------------
.nan:
    mov [output_buffer+rcx], 'n'
    inc rcx
    mov [output_buffer+rcx], 'a'
    inc rcx
    mov [output_buffer+rcx], 'n'
    inc rcx
    cmp r12, 1
    je .return
    jmp .move_to_b
; -----------------------------------------------
.zero:
    mov [output_buffer+rcx], '0'
    inc rcx
    mov [output_buffer+rcx], '.'
    inc rcx
    mov [output_buffer+rcx], '0'
    inc rcx
    cmp r12, 1
    je .return
    jmp .move_to_b
; -----------------------------------------------
