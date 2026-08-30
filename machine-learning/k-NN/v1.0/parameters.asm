global num_rows
global num_features
global num_classes
global one
global classifier_input_size
global file_size
global class_values
global x_values
global y_values
global z_values
global classifier_input_buffer
global closest_buffer
global nearest_neighbors
global class_A_count
global class_B_count
global class_C_count
global k
global training_input_buf

section .data
; -----------------------------------------------
    ; ** ADJUST PARAMETERS HERE **
; -----------------------------------------------
     num_rows dw 15 ; default: 0
; ----------------------------------------------
    num_features dw 3 ; default: 0
; -----------------------------------------------
    num_classes dw 3 ; default: 0
; -----------------------------------------------
    one dq 1.0
; -----------------------------------------------
    ; Note: we need a size variable for input when our classifier sys_read-s
    classifier_input_size dd 24 ; same formula as to find buffer size later on
; -----------------------------------------------
    k db 3

    file_size db 209


section .bss
; -----------------------------------------------
; WE DEFINE FILESIZE OF OUR TRAINING DATA BUFFER BY USING:
; -----------------------------------------------
    training_input_buf resb 209
; -----------------------------------------------
    ; DEFINE TRAINING BUFFERS
; -----------------------------------------------
    class_values resb 15

    x_values resb 120

    y_values resb 120

    z_values resb 120
; -----------------------------------------------

; -----------------------------------------------
; This is how we're structuring our data btw
; -----------------------------------------------
    ; C: [1, 2, 3, ...]
    ; x: [1.0, 3.5, 7.1, ...]
    ; y: [1.3, 0.9, 10.8, ...]
    ; z: [2.2, 4.3, 8.0, ...]
; -----------------------------------------------
; Input should look conceptually like:
    ; [x, y, z, ...]
; On the account that x/y/z/etc are double precision floats
; -----------------------------------------------
; Assign the classification buffer size as num.features * 8
; -----------------------------------------------
    classifier_input_buffer resb 24
; -----------------------------------------------


; -----------------------------------------------
; Set the buffer for the current closest neighbor (Distance:class)
; -----------------------------------------------
    closest_buffer resb 10
; -----------------------------------------------
; Set the buffer for the array of closest neighbors (Distance: class)
; -----------------------------------------------
    nearest_neighbors resb 6
; -----------------------------------------------
; Set up our buffers that keep track of the count of each of our classes 
; -----------------------------------------------
    class_A_count resb 4
    class_B_count resb 4
    class_C_count resb 4


; REGISTER REFERENCE
; -----------------------------------------------
; SYSCALL-RELATED
; -----------------------------------------------
    ; rax == holds the size of the input buffer
; -----------------------------------------------
; INPUT/OUTPUT
; -----------------------------------------------
    ; r8 == Current byte
    ; r9 == Whole number accumulation
    ; xmm0 == Float value
; -----------------------------------------------
; STATE TRACKERS    
; -----------------------------------------------    
    ; r10 == Keeps negative state
    ; r11 == Keeps decimal state  
; -----------------------------------------------
; COUNTERS
; -----------------------------------------------
    ; r12 == Decimal counter
    ; r13 == Row counter
    ; r14 == Column counter
    ; r15 == Byte counter
; -----------------------------------------------
; MISC
; -----------------------------------------------
    ; xmm5 == Converter/divisor into accurate float representation





