global _train ; choo choo
global _classify

section .bff
    train_buffer resp 640 ; 32 (our data structure) * 20 (max number of features)

section .text

; --------------------------------------------------------
    ; rdi == pointer to the buffer that contains our pointers
    ; r8 == pointer to the current pointer to the column we want
    ;
    ; r12 == offset for the output buffer array
    ; r13 == 
    ; r14 == offset to which pointer we're dealing with - aka, which column, basically
    ; r15 == counts how many elements we're working with rn

    ; xmm0 == accumulation of values
; --------------------------------------------------------


_train:
    xor r8, r8
    xor r9, r9
    xor r10, r10
    xor r11, r11
    xor r12, r12
    xor r13, r13
    xor r14, r14
    xor r15, r15
    ; we should recieve three parameters here:
        ; rdi == pointer to the first column buffer
        ; rsi == pointer to the subsequent column buffers
        ; rdx == size of all the float values combined

; ---------------------------------------------------------
    ; Select our column
; ---------------------------------------------------------
.select_first_column:
    ; we move the pointer to the pointer to the column values into r8
    mov r8, [rdi]

    jmp .accumulate
; --------------------------------------------------------
.select_subsequent_column:
    xor r15, r15

    ; we move the pointer to the array of pointers + the current pointer * 8 - 8 (due to r14 starting it's index at 1 instead of zero
    ; excellent design choice, I know
    mov r8, [rsi+r14*8-8]
    
    ; check for end of pointbuf
    cmp r8, '%'
    je .return
    jmp .accumulate
; --------------------------------------------------------
    ; Accumulate values
; --------------------------------------------------------
.accumulate:
    ; check for end of column
    mov r13b, [r8+r15*8]

    ; if true, jmp to finding the mean
    cmp r13b, '%'
    je .calculate_statistical_values

    ; otherwise, we add the value to the sum of values
    addsd xmm0, [r8+r15*8]
    
    ; duplicates the sum to find the squared value of the sum
    movsd xmm10, [r8+r15*8]

    ; squares the value
    mulsd xmm10, xmm10

    ; add squared value to the sum of the squared values
    addsd xmm11, xmm10
    ; increment bytes counter for column
    inc r15

    jmp .accumulate

; -------------------------------------------------------
    ; Finding the mean, variance, and prior-probability
; -------------------------------------------------------
; ---------------
    ; MEAN
; ---------------
    ; place n (number of elements) into xmm1
    movq xmm1, r15

    ; stores our accumulation for use calculating the variance later
    movsd, xmm2, xmm0
    
    ; finds the mean
    divsd xmm2, xmm1

    ; stores the mean for safekeeping
    movsd xmm3, xmm2

    ; finds the squared mean
    mulsd xmm2, xmm2

    ; finds the mean of the squared values
    divsd xmm11, xmm1
; ----------------
    ; VARIANCE
; ----------------
    ; find variance by using expected values
    subsd xmm11, xmm2
    
    ; moves variance into xmm4 because now it lines up with the other numbers 
    movsd xmm4, xmm11
; ----------------
    ; PRIOR-PROBABILITY
; ----------------
    ; moves our number of elements in the column to xmm5
    movq xmm5, r15

    ; moves our total number of elements to xmm6
    movq xmm6, rdx

    ; we find the prior probability
    divsd xmm5, xmm6 
; -------------------------------------------------------

.store_values:
    ; We have the mean, variance, prior-prob, and column index to keep track of
    ; Each column's value will be packed in 32 bytes, 8 bytes for each

    ; stores which column index
    mov [train_buffer+r12], r14

    ; stores the mean
    movsd [train_buffer+r12+8], xmm3

    ; stores the variance
    movsd [train_buffer+r12+16], xmm4

    ; stores the prior probability
    movsd [train_buffer+r12+24], xmm5

    ; offsets r12, which we're using to keep track of the data structure we made
    add r12, 32

    ; moves onto the next column
    inc r14

    jmp .next_column

.return:
    ret
; -------------------------------------------------------

_classify:

    ; TBA
