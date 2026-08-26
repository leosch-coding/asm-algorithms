extern _get_buffer
extern _train
extern _classify
extern _parse_data_for_classification
extern output_buffer

default rel

section .bss
    pointbuf resb 161 ; this is our buffer that stores the pointers to each of the columns we make. It ends in % to signal it being finished
    tempbuf resb 3920 ; this is a temporary buffer to store our values in for the first column to get everything set up

section .rodata
    one dq 1.0

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

    ; stores the pointer to the input buffer in rsi
    ; stores the size of the file in xmm13 cuz we're running out of GPRs

    mov rsi, rax
    movq xmm13, rdi

    ; sets up our xmm-value incrementer
    movsd xmm12, [one]

    xor rdx, rdx 
    xor rcx, rcx
    xor r9, r9
    xor r10, r10
    xor r11, r11
    xor r12, r12
    xor r13, r13
    xor r14, r14
    xor r15, r15


    inc rcx
; -----------------------------------------------
    ; Loops
; -----------------------------------------------

.take_byte_loop:
    ; check if we're done
    cmp rdi, r15
    je .train_values

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

    ; increments our column-size counter
    inc r11

    ; checks if our number is past the decimal point
    cmp r14, 1
    jne .loop

    ; if it's past the decimal point, we increment the counter of how many times to divide it by ten
    inc r10
    jmp .loop

; --------------------------------------------------
    ; Char handling
; --------------------------------------------------

.check_for_char:
    ; checks if current byte is a character. If it is, we move onto our 
    cmp r8, 'A'
    jl .not_a_char_or_digit
    cmp r8, 'z'
    jg .not_a_char_or_digit

    inc r15

    jmp .handle_char
; --------------------------------------------------
.handle_char:
    cmp rdi, r15
    je .exit

    ; takes a byte
    xor r8, r8
    mov r8b, [rsi+r15]

    ; check for the end of the word
    cmp r8, ','
    je .find_height_of_column

    ; increments our byte offset counter and our column size
    inc r15
    inc r11

    jmp .handle_char

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
    ; moves our current number into xmm register
    cvtsi2sd xmm0, r9

    ; we temporarily repurpose r12 into something able to be multiplied by ten for the decimal-conversion process
    mov r12, 1 

    ; check if we've made it a proper decimal yet
    cmp r10, 0
    jne .prepare_divisor
    
    cmp rcx, 2
    jl .handle_first_column_value 

    ; deposit our float value into the column buffer it belongs in
    jmp .shove_value_into_column_buffer  

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

    jmp .shove_value_into_column_buffer

; --------------------------------------------------
    ; Handling the first column (since my architecture was made when I was heavily sleep deprived, so we have to do this now)
; --------------------------------------------------

.handle_first_column_input:
    
    ; increments our counter for the size of the first column input by 1
    addsd xmm11, xmm12

    ; turns xmm11 into a int 

    cvtsd2si r8, xmm11 

    ; moves our current value into the buffer we have for the first column
    movsd [tempbuf+r8*8], xmm0

    ; jumps back to the loop to parse more bytes
    jmp .take_byte_loop

.first_column_end:
    ; convert counter for the size of the first column input by 1
    cvtsd2si r8, xmm11

    ; moves the terminator byte into tempbuf to signal it is finished
    mov [tempbuf+r8*8+1], '%'

    ; move to the next column
    inc rcx

    jmp .take_byte_loop

; --------------------------------------------------
    ; Column operations
; --------------------------------------------------

.find_height_of_column:
    ; transfer the current column size into rdi to call the buffer with
    mov rdi, r11

    ; stores the current column size for safekeeping
    movq xmm14, r11

    ; adds the current column size to the total size of columns in bytes
    addsd xmm15, xmm14

    ; adds 1 to column size to account for byte 
    add rdi, 1

    ; stores the size of 
    mov rsi, r11
    call _get_buffer

    ; pointer to column buffer is in rax
    ; size of column buffer is in rdi

    ; we move our 'end of column' byte to the current end of the column

    mov [pointbuf+rcx], '%'

    
    ; we move our 
    mov [pointbuf+rcx*8-8], rax

    jmp .loop

; ---------------------------------------------------
.shove_value_into_column_buffer:

    cmp rcx, 1
    jl .handle_first_column_input

    ; loads the buffer that's holding out pointer array into rax 
    lea rax, [pointbuf+rcx*8-16]

    ; moves our current value into 
    dec r11
    movsd [rax+r13*8], xmm0
    inc r11

    jmp .loop

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

    ; signals end of pointbuf
    mov [pointbuf+rcx*8-7], '%'

    ; stores our pointer to the first column's buffer
    mov rdi, tempbuf

    ; stores the pointer to pointbuf
    mov rsi, pointbuf

    ; finds total number of values
    addsd xmm15, xmm11

    ; stores total number of values
    cvtsd2si rdx, xmm15

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
