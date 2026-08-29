global _classify

; This was written on 3-4 hours of sleep
; Aka, it's not my best work.
; It'll be fixed tomorrow, okay? Don't judge me.

; buffers containing our training data
extern class_values

extern x_values
extern y_values
extern z_values

extern classifier_input_buffer
extern classifier input_size

; r10 == temp storage for current largest class 
; r11 == temp storage for k-nearest class thing. God damn I'm tired 
; r12 == scratchpad to pop off our class-values
; r13 == counter that allows us to loop based on how many k-s we've done without clobbering r14
; r14 == current k-index counter
; r15 == row counter

section .text
_classify:
    mov rax, 1
    mov rdi, 2
    mov rsi, [classifier_input_buffer]
    mov rbx, classifier_input_size
    syscall

    cmp rax, 0
    je _classify
    jg .find_x
    jl .error
; --------------------------------------------
.find_x:
    movsd xmm1, [classifier_input_buffer+r15*8]
    ucomsid xmm1, xmm0
    jmp .check_if_finished
    movsd xmm10, [x_values+r15*8]
    subsd xmm1, xmm10
    mulsd xmm1, xmm1

.find_y:
    movsd xmm2, [classifier_input_buffer+r15*8+8]
    movsd xmm10, [y_values+r15*8]
    subsd xmm2, xmm10
    mulsd xmm2, xmm2

.find_z:
    movsd xmm3, [classifier_input_buffer+r15*8+16]
    movsd xmm10, [z_values+r15*8]
    subsd xmm3, xmm10
    mulsd xmm3, xmm3

.find_class:
    mov r10b, [class_values+r15]
; ---------------------------------------------
.compare_distance:
    addsd xmm2, xmm1
    addsd xmm3, xmm2

    ucomsid xmm3, [closest_buffer]
    jl .move_on
    jg .check_if_duplicate

.move_on:
    inc r15
    cmp r15, 
    jmp .find_x

.check_if_duplicate:
    ucomisd xmm3, [nearest_neighbors+r13*9]
    inc r13
    cmp r13, r14
    jge .new_nearest

.new_nearest:
    mov [closest_buffer], r10b
    mov [closest_buffer+1], xmm3
    xor r13, r13
    jmp .find_x

.check_if_finished:
    mov r11b, [closest_buffer]
    movsd xmm4, [closest_buffer+1]
    mov [nearest_neighbors+r14*8], r11b
    push r11b
    movsd [nearest_neighbors+r14*8+1], xmm4
    inc r14
    cmp r14, k
    je .find_nearest
; --------------------------------------------
    ; ** NOTICE **
    ; THIS SECTION SHOULD BE ADJUSTED BASED ON CLASS-COUNT/NAME
; --------------------------------------------
.find_nearest:
    cmp r14, 0
    je .find_answer

    xor r12, r12

    pop r12
    cmp r12, 'A'
    je .add_vote_a
    
    cmp r12, 'B'
    je .add_vote_b

    cmp r12, 'C'
    je .add_vote_c
    
.add_vote_a:
    inc class_A_count
    dec r14

.add_vote_b:
    inc class_B_count
    dec r14

.add_vote_c:
    inc class_C_count

.find_closest_value:
    cmp class_A_count, class_B_count
    jg .class_a_higher
    jl .class_b_higher
; ---------------------------------------------
.class_a_higher:
    cmp class_A_count, class_C_count
    jg .output_a
    jl .output_c

.class_b_higher:
    cmp class_B_count, class_C_count
    jg .output_b
    jl .output_c
; --------------------------------------------
.output_a:
    mov rsi, 'A'
    ret
        
.output_b:
    mov rsi, 'B'
    ret

.output_c:
    mov rsi, 'C'
    ret

    
