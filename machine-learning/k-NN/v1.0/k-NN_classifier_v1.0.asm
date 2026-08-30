global _classify
default rel
; buffers containing our training data
extern class_values

extern x_values
extern y_values
extern z_values

extern classifier_input_buffer
extern classifier_input_size

extern closest_buffer
extern nearest_neighbors

extern class_A_count
extern class_B_count
extern class_C_count

extern k

section .data
    input_msg db "Input:  ", 0xA
    len_msg equ $ - input_msg

; r11 == temp storage for current largest class 
; r12 == storage for class value
; r13 == counter that allows us to loop based on how many k-s we've done without clobbering r14
; r14 == current k-index counter
; r15 == row counter

section .text
_classify:
    mov rax, 1
    mov rdi, 1
    mov rsi, input_msg
    mov rdx, len_msg
    syscall

.wait_for_input:
    
    ; sys_read
    mov rax, 0
    mov rdi, 0
    mov rsi, classifier_input_buffer
    mov rdx, 24
    syscall

    ; checks for end command
    cmp [classifier_input_buffer], 'q'
    je .exit

    ; checks if input was given
    cmp rax, 24
    je .find_x
    
    jmp .wait_for_input

; --------------------------------------------
.find_x:
    ; moves the first float into variable x
    xor r13, r13
    movsd xmm1, [classifier_input_buffer+r15*8]
    ucomisd xmm1, xmm0
    je .check_if_finished
    movsd xmm10, [x_values+r15*8]

    ; subtracts input x by row x
    subsd xmm1, xmm10
    mulsd xmm1, xmm1

.find_y:
    ; moves the second float into variable y
    movsd xmm2, [classifier_input_buffer+r15*8+8]
    movsd xmm10, [y_values+r15*8]
    
    ; subtracts input y by row y
    subsd xmm2, xmm10
    mulsd xmm2, xmm2

.find_z:
    ; moves the third float into variable z
    movsd xmm3, [classifier_input_buffer+r15*8+16]
    movsd xmm10, [z_values+r15*8]

    ; subtracts input z by row z
    subsd xmm3, xmm10
    mulsd xmm3, xmm3

.find_class:
    ; moves the current class of the row into r11b
    mov r11b, [class_values+r15]
; ---------------------------------------------
.compare_distance:

    ; finds this current row's distance
    addsd xmm2, xmm1
    addsd xmm3, xmm2

    ; compares current rows distance with current nearest distance
    ucomisd xmm3, [closest_buffer+2]
    jge .next_row
    jle .new_nearest

.next_row:
    ; increments our row counter
    inc r15

.check_for_duplicate:
    ; checks if this row has already been found as a 'nearest neighbor', if so, skip the row
    cmp r15, [nearest_neighbors+r13+1]
    je .next_row

    ; compares a counter with the number of nearest neighbors we've current measured
    inc r13
    cmp r13, r14
    je .find_x

    ; if they are not equal, then we have not yet tested if we've checked if this row has already been found as a nearest neighbor
    jmp .check_for_duplicate

.new_nearest:
    mov [closest_buffer], r11b
    mov [closest_buffer+1], r15
    movsd [closest_buffer+2], xmm3
    xor r13, r13
    jmp .next_row

.check_if_finished:
    xor r8, r8
    xor r9, r9

    mov r8b, [closest_buffer]
    mov r9b, [closest_buffer+1]

    mov [nearest_neighbors+r14*5], r8b
    mov [nearest_neighbors+r14*5+1], r9b

    xor r15, r15
    inc r14
    cmp r14, k
    je .find_nearest

    cmp r15, [nearest_neighbors+r13+1]
    je .next_row

    jmp .find_x
; --------------------------------------------
    ; ** NOTICE **
    ; THIS SECTION SHOULD BE ADJUSTED BASED ON CLASS-COUNT/NAME
; --------------------------------------------
.find_nearest:
    cmp r14, 0
    je .find_closest_value

    xor r8, r8
    mov r8, class_A_count
    xor r9, r9
    mov r9, class_B_count
    xor r10, r10
    mov r10, class_C_count

    mov r12, [nearest_neighbors+r14]
    cmp r12, 'A'
    je .add_vote_a
    
    cmp r12, 'B'
    je .add_vote_b

    cmp r12, 'C'
    je .add_vote_c
    
.add_vote_a:
    inc r8
    dec r14
    add r14, 2
    jmp .find_nearest

.add_vote_b:
    inc r9
    dec r14
    add r14, 2
    jmp .find_nearest

.add_vote_c:
    inc r10
    dec r14
    add r14, 2
    jmp .find_nearest

.find_closest_value:
    cmp r8, r9
    jg .class_a_higher
    jl .class_b_higher
; ---------------------------------------------
.class_a_higher:
    cmp r8, r10
    jg .output_a
    jl .output_c

.class_b_higher:
    cmp r9, r10
    jg .output_b
    jl .output_c
; --------------------------------------------
.output_a:
    mov rsi, 'A'
    jmp .return
        
.output_b:
    mov rsi, 'B'
    jmp .return

.output_c:
    mov rsi, 'C'
    jmp .return
; --------------------------------------------
.return:
    mov rax, 1
    mov rdi, 1
    mov rdx, 1
    syscall

.exit:
    mov rax, 60
    mov rdi, 0
    syscall



    
