extern _get_buffer
extern _train
extern _classify
extern _parse_data_for_classification
extern output_buffer

default rel

section .text
global _start
; -----------------------------------------------
    ; rax == holds the pointer to the output buffer 
    ; rbx == size of output buffer N * 16
    ; rcx == current column we're working with - also serves as an offset to find which pointer in pointbuf we're dealing with
    ; rdi == holds the size of the input buffer
    ; rsi == holds the pointer to the input buffer
    ; r8 == Current byte
    ; r9 == Whole number accumulation
    ; r10 == Keeps how many decimals there are (Increases for every decimal added, so that we can divide the total number of it by however many times there's a decimal)
    ; r11 == Keeps current column size count
    ; r12 == Keeps negative state (if 0, number is positive, if 1, number is negative)
    ; r13 == Offset for the extra '%' we add to signal EOF
    ; r14 == Keeps decimal state (if 0, number is before the decimal point, if 1, number is after the decimal point)
    ; r15 == Our counter of what byte we're working with


    ; xmm0 == parsed input
    
    ; xmm13 == keeps track of the offset for the first column buffer
    ; xmm14 == size of column storage (bytes)
    ; xmm15 == total number of non-label values (bytes)
; -----------------------------------------------
_start:
    call _get_buffer

    ; rsi is the pointer to our input buffer
    mov rsi, rax

    ; r13 is the filesize
    mov r13, rdi

    mov rdi, 151 ; max around of rows for now is 50. We'll make this dynamic later instead of just hardcoding but whatever

    ; T - 50
    ; F - 50
    ; T and F themselves - 50
    ; % - 1
    ; == 151
    call _get_buffer

    mov [rax+451], '%'
    ; rax is now the pointer to the output buffer
    ; rdi is the size of this buffer

    xor rdx, rdx 
    xor rcx, rcx
    xor r9, r9
    xor r10, r10
    xor r11, r11
    xor r12, r12
    xor r13, r13
    xor r14, r14
    xor r15, r15
; -----------------------------------------------
    ; Loops
; -----------------------------------------------

.take_byte_loop:
    ; check if we're done
    cmp r13, r15
    je .start_training

    ; checks if we're working with the class yet
    cmp r11, 3
    je .t_or_f

    ; takes a byte
    xor r8, r8
    mov r8b, [rsi+r15]

    ; check if it's a number
    cmp r8, '0'       
    jl .check_for_char  
    cmp r8, '9'       
    jg .check_for_char    

    ; minus '0' which essentially turns the ASCII digit into a raw int
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
    ; Check misc byte
; --------------------------------------------------

.not_a_char_or_digit:
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

.end_of_number:
    inc r11
    ; moves our current number into xmm register
    cvtsi2sd xmm0, r9

    ; we temporarily repurpose r12 into something able to be multiplied by ten for the decimal-conversion process
    mov r12, 1 

    ; check if we've made it a proper decimal yet
    cmp r10, 0
    jne .prepare_divisor

    ; deposit our float value into the column buffer it belongs in
    jmp .package_value

; --------------------------------------------------
    ; Negative handling
; --------------------------------------------------

.negative_true:
    ; increment our counter to account for the '-'
    inc r15
    
    ; update our negative state to true
    mov r12, 1
    jmp .take_byte_loop
; --------------------------------------------------
.check_negative:

    ; moves our current number into xmm register
    cvtsi2sd xmm0, r9

    ; checks if negative state is true
    cmp r12, 0 
    jne .negate
; --------------------------------------------------
.negate:
    movsd xmm1, xmm0
    addsd xmm1, xmm1
    subsd xmm0, xmm1
    xor r12, r12
    jmp .end_of_number

;---------------------------------------------------
    ; Decimal handling
; --------------------------------------------------

.decimal_true:
    ; increment our counter to account for the '.'
    inc r15

    ; updates our decimal state to true
    mov r14, 1

    jmp .take_byte_loop
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
    xor r9, r9
    xor r12, r12
    xor r14, r14

    jmp .package_value
; ---------------------------------------------------
    ; Shoves our features and boolean into the training buffer
; ---------------------------------------------------
.package_floats:
    ; moves our current float into the training buffer
    mov [rax+rcx], xmm0

    ; increments rcx by 8 to account for the offset
    add rcx, 8

    inc r11

    jmp .take_byte_loop
; ----------------------------------------------------
.t_or_f:
    add rcx, 1
    cmp r8b, 'T'
    je .true
    mov [rax+rcx], 'F'
    xor r11, r11
    jmp .take_byte_loop
; -----------------------------------------------------
.true:
    mov [rax+rcx], 'T'
    xor r11, r11
    jmp .take_byte_loop

; -------------------------------------------------
    ; Output
; -------------------------------------------------

.train_values:
    xor r8, r8
    xor r9, r9
    xor r10, r10
    xor r11, r11
    xor r12, r12
    xor r13, r13
    xor r14, r14
    xor r15, r15
    
    inc rcx

    ; stores our pointer to the first column's buffer
    mov rdi, rax

    ; stores the size of the buffer
    mov rsi, rdi

    ; calls our NB training function
    call _train

    ; parses the second file to for classification, returns pointer to buffer of data
    call _parse_data_for_classification

    ; classifies values based off of training data
    call _classify
; ------------------------------------------------- 
.final_output:
    mov rax, 1
    mov rdi, 1
    mov rsi, output_buffer
    mov rdx, rcx
    syscall
; -------------------------------------------------
.end_of_program:
    mov rax, 60
    mov rdi, 0
    syscall


    
