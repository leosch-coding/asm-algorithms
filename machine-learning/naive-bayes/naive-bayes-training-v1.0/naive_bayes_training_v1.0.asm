global _train ; choo choo
global _classify

section .bff
    train_buffer resp 40 ; our training data

section .text

; --------------------------------------------------------
    ; rdi == pointer to the buffer that contains our pointers
    ; r8 == pointer to the current pointer to the column we want
    ;
    ; r12 == offset for the output buffer array
    ; r13 == 
    ; r14 == offset to which pointer we're dealing with - aka, which column, basically
    ; r15 == counts how many elements we're working with rn

    ; xmm0 == feature 1
    ; xmm1 == feature 2
    ; xmm2 == squared feature 1
    ; xmm3 == squared feature 2
    ; xmm4 == prior probability
    ; xmm5 == number of something. It's just n. We use it to divide. I'm so tired dude I had three hours of sleep last night tryna get this thing done
    ; xmm6 == variance of feature 1
    ; xmm7 == variance of feature 2
    ; xmm8 == accumulation of squared feature 1
    ; xmm9 == accumulation of squared feature 2
    ; xmm10 == mean of feature 1
    ; xmm11 == mean of feature 2
    ; xmm12 == accumulation of feature 1
    ; xmm13 == accumulation of feature 2
    ; xmm14 == accumulation of feature 1^2
    ; xmm15 == accumulation of feature 2^2 
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
    ; we should recieve two parameters here
        ; rdi == Pointer to pointbuf
        ; rsi == Number of data given
        
; ---------------------------------------------------------
    ; Select our column
; ---------------------------------------------------------
.grab_values:

    ; grabs first feature
    mov xmm0, [rdi+r15]

    ; grabs second feature
    mov xmm1, [rdi+r15+8]

    ; grabs the class (T/F)
    mov r8, [rdi+r15+9]

    cmp r8, '%'
    jmp .find_statistical_values

    cmp r8, 'T'
    je .accumulate_true
    
    add r15, 8
    jmp .grab_values
; --------------------------------------------------------
    ; Accumulate values
; --------------------------------------------------------
.accumulate:
    ; accumulate feature 1, true
    addsd xmm12, xmm0

    ; accumulate feature 2, true
    addsd xmm13, xmm1

    ; accumulate feature 1, T, a second time for squaring
    movsd xmm2, xmm0

    ; accumulate feature 2, T, a secont time for squaring 
    movsd xmm3, xmm1

    ; squares current feature 1
    mulsd xmm2, xmm2

    ; squares current feature 2
    mulsd xmm3, xmm3

    ; adds the squares feature 1 to the accumulation of squared feature 1
    addsd xmm8, xmm2
    
    ; adds the squared feature 2 to the accumulation of squared feature 2
    addsd xmm9, xmm3

    ; increment bytes counter for column
    add r15, 8

    inc r14

    jmp .grab_values
; -------------------------------------------------------
    ; Finding the mean, variance, and prior-probability
; -------------------------------------------------------

.find_statistical_values:
; ---------------
    ; MEAN
; ---------------
    ; place n (number of elements) into xmm1
    movq xmm5, r14

    ; stores our accumulation of feature one (TRUE) for use later
    movsd xmm8, xmm12
    
    ; finds the mean for feature 1 (TRUE)
    divsd xmm8, xmm4
    
    ; stores our accumulation of feature two (TRUE) for use later
    movsd xmm9, xmm13

    ; finds the mean for features 2 (TRUE)
    divsd xmm9, xmm4

    ; stores our two means away for future use
    movsd xmm10, xmm8
    movsd xmm11, xmm9

    ; finds the squared mean of feature 1 (TRUE)
    mulsd xmm8, xmm8

    ; finds the squared mean of feature 2 (TRUE)
    mulsd xmm9, xmm9

    ; finds the mean of feature 1^2
    divsd xmm14, xmm4

    ; finds the mean of feature 2^2
    divsd xmm15, xmm4

; ----------------
    ; VARIANCE
; ----------------
    ; find variance of feature 1 (TRUE) using expected values
    subsd xmm14, xmm8

    ; find variance of feature 2 (TRUE) using expected values
    subsd xmm15, xmm9
    
    ; moves variance of feature 1 (TRUE) into xmm6
    movsd xmm6, xmm14

    ; moves variance of feature 2 (TRUE) into xmm7
    movsd xmm7, xmm15
; ----------------
    ; PRIOR-PROBABILITY
; ----------------
    ; moves our hardcoded number of elements in the column 
    movq xmm4, 50

    ; moves our total number of elements into xmm5
    ; our hardcoded amount is 151 right now
    movq xmm5, 100

    divsd xmm4, xmm5

    ; so its 1/2 obviously 


; -------------------------------------------------------

.store_values:
    ; We have the mean, variance, and prior-probability now!!!!!11!!1

    ; stores the mean (feature 1T)
    movsd [train_buffer], xmm10

    ; stores the mean (feature 2T)
    movsd [train_buffer+8], xmm11

    ; stores the variance (feature 1T)
    movsd [train_buffer+16], xmm6

    ; stores the variance (feature 2T)
    movsd [train_buffer+24], xmm7

    ; stores the prior probability
    ; due to hardcoded values we know it's 50/50 either way 
    movsd [train_buffer+32], xmm4

    ret
; -------------------------------------------------------

_classify:

    ; we take pointer to buffer input
    ; we already have our values stored in this programs buffer, happy days!

    ; THIS IS A WIP. I'LL FINISH IT AFTER I NAP
