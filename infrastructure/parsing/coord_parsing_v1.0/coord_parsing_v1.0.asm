extern _get_buffer_size

section .text
global _start
; -----------------------------------------------
    ; rax == output pointer
    ; rsi == input pointer
    ; r8 == Current byte
    ; r9 == Whole number accumulation
    ; r10 == Keeps how many decimals there are (Increases for every decimal added, so that we can divide the total number of it by however many times there's a decimal)
    ; r11 == Keeps conversion to float state (if 0, number has been converted, if 1, the number is still an int)
    ; r12 == Keeps negative state (if 0, number is positive, if 1, number is negative)
    ; r13 == Keeps coordinate state (if 0, number is an x-coordinate, if 1, number is a y-coordinate)
    ; r14 == Keeps decimal state (if 0, number is before the decimal point, if 1, number is after the decimal point)
    ; r15 == Our counter of what byte we're working with
    ; xmm0 == Final y output
    ; xmm10 == Final x output

; -----------------------------------------------
_start:
    call _get_buffer_size
    xor r15, r15
    mov rbx, rsi
    mov rsi, rax ; rsi points to our allocated input buffer
    ; sys_read
    mov rax, 0
    mov rdi, 0
    syscall
    mov rax, r8
    xor rcx, rcx
    xor r11, r11
; -----------------------------------------------
    ; Loops
; -----------------------------------------------
.loop:
    cmp r15, rbx
    je exit
    xor r8, r8
    ; takes a byte
    mov r8b, [rsi+r15]

    ; check if it's a number
    cmp r8, '0'       
    jl not_a_digit    
    cmp r8, '9'       
    jg not_a_digit    

    sub r8, '0'
    ; add it to the accumulation of the numbers * 10 in order to 'push' the new digit to the lowest place
    imul r9, 10
    add r9, r8

    ; increments our counter to move to the next byte
    inc r15

    ; checks if our number is decimal
    cmp r14, 1
    ; if its not, then loop
    jne loop

    ; if it is, increment r10 to later use in division to turn our number into a decimal
    inc r10
    jmp loop
; --------------------------------------------------
    ; Check non-numerical byte
; --------------------------------------------------
.not_a_digit:
    ; checks if the current byte is a comma, if so, jump to check_if_new_coords, as a comma will seperate numbers from eachother
    cmp r8, ','
    je .end_of_number_true
    ; checks if the current byte is a dot, if so, jump to decimal_true, as a dot will seperate integer from decimal
    cmp r8, '.'
    je .decimal_true
    ; checks if the current byte is a negative sign, if so, jump to increment_offset_negative, as we will need to confirm the number as negative as well as accounting for it in our byte count
    cmp r8, '-'
    je .negative_true
; --------------------------------------------------
    ; End of number handling
; --------------------------------------------------
.end_of_number_true:
    cvtsi2sd xmm0, r9
    cmp r12, 0 ; if negative_state == True?
    jne .negate ; then negate the number to make it negative
    mov r12, 1 
    cmp r11, 1 ; check if float?
    jne .prepare_divisor ; then divide to make it a proper float
    cmp r13, 0 ; if y == true
    jne .stream_coords ; then jmp to streaming the coord pair
    mov r13, 1 ; else x | else negative_state(x) == False
    jmp .store ; store x
; --------------------------------------------------
    ; Negative handling
; --------------------------------------------------
.negative_true:
    inc r15
    mov r12, 1
    jmp .loop
; --------------------------------------------------
.negate:
    mov xmm1, xmm0
    mulsd xmm1, 2
    subsd xmm0, xmm1
    mov r12, 0
    jmp .end_of_number_true
;---------------------------------------------------
    ; Decimal handling
; --------------------------------------------------
.decimal_true:
    mov r14, 1
    jmp loop
; --------------------------------------------------
.prepare_divisor:
    imul r12, 10
    dec r10
    cmp r10, 0
    jne .prepare_divisor
    jmp .calculate_decimal
; --------------------------------------------------
.calculate_decimal:
    movsd xmm2, r12
    divsd xmm0, xmm2
    mov r11, 1
    xor r9, r9
    xor r12, r12
    jmp end_of_number_true
; --------------------------------------------------
    ; Storage
; --------------------------------------------------
.store_x:
    xor r9, r9
    xor r11, r11
    xor r12, r12
    xor r14, r14
    movsd xmm10, xmm0
    jmp .loop
; --------------------------------------------------
.stream_coords:
    ; clear out all state for the next loop
    xor r9, r9
    xor r10, r10
    xor r11, r11
    xor r12, r12
    xor r13, r13
    xor r14, r14
    
    ; passes on our data to the processor
    movsd [rax+rcx], xmm10 ; our x
    movsd [rax+rcx+8], xmm0 ; our y
    add rcx, 16
    jmp .loop
; -------------------------------------------------
.exit:
    shr rcx, 4 ; basically just dividing it by 16 by bit shifting
    call _process_values

    ; ******  WIP, going to add in an intepreter tomorrow *******

    mov rax, 60
    mov rdi, 0
    syscall


    

    
