extern _get_buffer
extern _process_values
extern _float_to_ascii_m
extern output_buffer

default rel

section .text
global _start
; -----------------------------------------------
    ; rax == holds the pointer to the output buffer 
    ; rbx == size of output buffer N * 16
    ; rcx == our offset to the output buffer
    ; rdi == holds the size of the input buffer
    ; rsi == holds the pointer to the input buffer
    ; r8 == Current byte
    ; r9 == Whole number accumulation
    ; r10 == Keeps how many decimals there are (Increases for every decimal added, so that we can divide the total number of it by however many times there's a decimal)
    ; r11 == Keeps conversion to float state (if 0, number has been converted, if 1, the number is still an int)
    ; r12 == Keeps negative state (if 0, number is positive, if 1, number is negative)
    ; r13 == Keeps coordinate state (if 0, number is an x-coordinate, if 1, number is a y-coordinate)
    ; r14 == Keeps decimal state (if 0, number is before the decimal point, if 1, number is after the decimal point)
    ; r15 == Our counter of what byte we're working with
; -----------------------------------------------
_start:
    call _get_buffer

    ; store pointer to file for safekeeping
    mov r13, rax

    ; store file size for safekeeping
    mov r12, rdi

    ; finds N * 16
    imul rdi, 16

    xor rdx, rdx
    ; call mem alloc again to find memory needed for output into algorithm

    call _get_buffer

    ; moves N * 16 size into rbx
    mov rbx, rdi

    ; rsi holds the pointer to the input file
    mov rsi, r13

    ; rdi holds the size of the input file
    mov rdi, r12

    ; rax already holds the pointer to the output file, so no moves necessary
    xor rdx, rdx 
    xor rcx, rcx
    xor r10, r10
    xor r11, r11
    xor r12, r12
    xor r13, r13
    xor r14, r14
    xor r15, r15
; -----------------------------------------------
    ; Loops
; -----------------------------------------------
.loop:
    ; check if we're done
    cmp rdi, r15
    je .exit

    ; takes a byte
    xor r8, r8
    mov r8b, [rsi+r15]

    ; check if it's a number
    cmp r8, '0'       
    jl .not_a_digit    
    cmp r8, '9'       
    jg .not_a_digit    

    sub r8, '0'
    ; add it to the accumulation of the numbers * 10 in order to 'push' the new digit to the lowest place
    imul r9, 10
    add r9, r8

    ; increments our counter to move to the next byte
    inc r15

    ; checks if our number is past the decimal point
    cmp r14, 1
    jne .loop

    ; if it's past the decimal point, we increment the counter of how many times to divide it by ten
    inc r10
    jmp .loop
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
    ; moves our current number into xmm register
    cvtsi2sd xmm0, r9

    ; checks if negative state is true
    cmp r12, 0 
    jne .negate
    
    ; we temporarily repurpose r12 into something able to be multiplied by ten for the decimal-conversion process
    mov r12, 1 

    ; check if float state is true
    cmp r11, 1 
    jne .prepare_divisor

    ; checks if y is true
    cmp r13, 0 
    jne .stream_coords ; then jmp to streaming the coord pair

    mov r13, 1 ; else x, store it
    jmp .store_x
; --------------------------------------------------
    ; Negative handling
; --------------------------------------------------
.negative_true:
    ; increment our counter to account for the '-'
    inc r15
    
    ; update our negative state to true
    mov r12, 1
    jmp .loop
; --------------------------------------------------
.negate:
    movsd xmm1, xmm0
    addsd xmm1, xmm1
    subsd xmm0, xmm1
    xor r12, r12
    jmp .end_of_number_true
;---------------------------------------------------
    ; Decimal handling
; --------------------------------------------------
.decimal_true:
    ; increment our counter to account for the '.'
    inc r15

    ; updates our decimal state to true
    mov r14, 1

    jmp .loop
; --------------------------------------------------
.prepare_divisor:
    ; multiply r12 (which should be 1) by 10 repeatedly, as it will become our divisor to find the actual float value
    imul r12, 10

    ; decrement r10, which should hold the number of decimals there should be
    dec r10
    cmp r10, 0

    ; if r10 isn't 0 yet, loop until it is.
    jne .prepare_divisor
    jmp .calculate_decimal
; --------------------------------------------------
.calculate_decimal:
    cvtsi2sd xmm2, r12
    divsd xmm0, xmm2
    mov r11, 1
    xor r9, r9
    xor r12, r12
    xor r14, r14

     ; checks if y is true
    cmp r13, 0 
    jne .stream_coords ; then jmp to streaming the coord pair

    mov r13, 1 ; else x, store it
    jmp .store_x
; --------------------------------------------------
    ; Storage
; --------------------------------------------------
.store_x:
    xor r9, r9
    xor r11, r11
    xor r12, r12
    xor r14, r14
    movsd xmm10, xmm0
    inc r15
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
    inc r15
    ; passes on our data to the processor
    movsd [rax+rcx], xmm10 ; our x
    movsd [rax+rcx+8], xmm0 ; our y
    add rcx, 16
    jmp .loop
; -------------------------------------------------
.exit:
    xor r8, r8

    ; sets our output buffer as the 1st parameter
    mov rdi, rax 

    ; sets our output buffer size as the 2nd parameter
    mov rsi, rbx

    ; calls our linreg function
    call _process_values

    xor rcx, rcx
    xor r14, r14


    call _float_to_ascii_m

.final_output:
    mov rax, 1
    mov rdi, 1
    mov rsi, output_buffer
    mov rdx, rcx
    syscall

.end_of_program:
    mov rax, 60
    mov rdi, 0
    syscall

