global _start
default rel

; Our parameters
extern num_rows
extern num_features
extern num_classes
extern one
extern file_size
extern class_values
extern x_values
extern y_values
extern z_values

; the big boy
extern _classify

section .text
; ------------------------------------------------
_start:
    ; sys_read
    mov rax, 0
    mov rdi, 2
    mov rsi, file_size
    mov rdx, file_size
    syscall

    movsd xmm5, one
    xor rdi, rdi
    xor rcx, rcx
    xor r11, r11
 ; ----------------------------------------------
    ; Loops
; -----------------------------------------------
.parse_loop:
    ; check if we're done
    cmp rdx, r15
    je .classify_loop

    ; takes a byte
    xor r8, r8
    mov r8b, [rsi+r15]

    ; check if it's a number
    cmp r8, '0'       
    jl .check_for_char  
    cmp r8, '9'       
    jg .check_for_char    

    sub r8, '0'
    ; add it to the accumulation of the numbers * 10 in order to 'push' the new digit to the lowest place
    imul r9, 10
    add r9, r8

    ; increments our counter to move to the next byte
    inc r15

    ; checks if our number is past the decimal point
    cmp r11, 1 
    jne .parse_loop

    ; if it's past the decimal point, we increment the counter of how many times to divide it by ten
    inc r12
    jmp .parse_loop
; --------------------------------------------------
    ; Char handling
; --------------------------------------------------
.check_for_char:
    cmp r8, 'A'
    jl .not_a_char_or_digit
    cmp r8, 'z'
    jg .not_a_char_or_digit

    ; We're working with a class
    ; In our model, we're gonna format it so that the class is the final thing in each row
    xor r8, r8
    mov r8d, [rsi+r15]
    mov [class_values], r8d
    
    add r15, 4
    xor r14, r14

    jmp .handle_remaining_chars
; --------------------------------------------------
.handle_remaining_chars:
    ; increments our byte counter
    inc r15

    ; checks if we're finished with the file
    cmp rdi, r15
    je .classify_loop ; ** change this later **

    ; take byte
    xor r8, r8
    mov r8b, [rsi+r15]

    ; check for the end of the word
    cmp r8b, ','
    jne .handle_remaining_chars

    jmp .parse_loop
; --------------------------------------------------
    ; Check misc byte
; --------------------------------------------------
.not_a_char_or_digit:
    ; checks if the current byte is a comma, if so, jump to check_negative to potentially convert to a negative
    cmp r8, ','
    je .check_sign
    ; checks if the current byte is a dot, if so, jump to decimal_true, as a dot will seperate integer from decimal
    cmp r8, '.'
    je .decimal_true
    ; checks if the current byte is a negative sign, if so, jump to negative_true, as we will need to confirm the number as negative as well as accounting for it in our byte count
    cmp r8, '-'
    je .negative_true
; --------------------------------------------------
    ; End of number handling
; --------------------------------------------------
.check_sign:
    ; moves our current number into xmm register
    cvtsi2sd xmm0, r9

    ; checks if negative state is true
    cmp r10, 0 
    jne .negate

    jmp .prepare_divisor
; --------------------------------------------------
    ; Negative handling
; --------------------------------------------------
.negative_true:
    ; increment our counter to account for the '-'
    inc r15
    
    ; update our negative state to true
    mov r10, 1
    jmp .parse_loop
; --------------------------------------------------
.negate:
    movsd xmm1, xmm0
    addsd xmm1, xmm1
    subsd xmm0, xmm1 

    jmp .prepare_divisor
;---------------------------------------------------
    ; Decimal handling
; --------------------------------------------------
.decimal_true:
    ; increment our counter to account for the '.'
    inc r15

    ; updates our decimal state to true
    mov r11, 1 
    jmp .parse_loop
; --------------------------------------------------
.prepare_divisor:
    ; multiply r10 (which should be 1) by 10 repeatedly, as it will become our divisor to find the actual float value
    imul r10, 10 ; swapped @

    ; decrement r10, which should hold the number of decimals there should be
    dec r12
    cmp r12, 0

    ; if r12 isn't 0 yet, loop until it is.
    jne .prepare_divisor
    jmp .calculate_decimal
; --------------------------------------------------
.calculate_decimal:
    cvtsi2sd xmm2, r10
    divsd xmm0, xmm2
    xor r9, r9
    xor r10, r10 ; 
    xor r11, r11 

    jmp .move_into_buffer
; ---------------------------------------------------
    ; STORE TRAINING VALUES
; ---------------------------------------------------   
.find_matching_buffer:
    ; ** NOTE: ADJUST AS NEEDED PER NUMBER OF CLASSES **
    cmp r14, 0
    je .x_value_buf

    cmp r14, 1
    je .y_value_buf
    
    cmp r14, 2
    je .z_value_buf

    cmp r14, 3
    je .class_buf

    cmp r14, 3
    jg .error1
; ---------------------------------------------------
.x_value_buf:
    mov [x_values+r13*8], xmm0
    addsd xmm13, xmm0
    inc r14
    jmp .parse_loop
.y_value_buf:
    mov [y_values+r13*8], xmm0
    addsd xmm14, xmm0
    inc r14
    jmp .parse_loop
.z_value_buf:
    mov [z_values+r13*8], xmm0
    addsd xmm15, xmm0
    inc r14
    jmp .parse_loop
.class_buf:
    mov [class_values+r13], xmm0
    xor r14, r14
    inc r13
    jmp .parse_loop
; -------------------------------------------------
    ; Output
; -------------------------------------------------
.prep_classify_loop:
    xor r8, r8
    xor r9, r9
    xor r10, r10
    xor r11, r11
    xor r12, r12
    xor r13, r13
    xor r14, r14
    xor r15, r15

    xorpd xmm0, xmm0
    
    call _classify

; ------------------------------------------------- 
.final_output:
    mov rax, 1
    mov rdi, 1
    mov rdx, rcx
    syscall
; -------------------------------------------------
.end_of_program:
    mov rax, 60
    mov rdi, 0
    syscall
