global num_rows
global num_features
global num_classes
global one
global file_size
global class_valeus
global x_values
global y_values
global z_values
global classifier_input_buffer


section .data
; -----------------------------------------------
    ; ** ADJUST PARAMETERS HERE **
; -----------------------------------------------
     num_rows qb 0 ; default: 0
; -----------------------------------------------
    num_features qb 0 ; default: 0
; -----------------------------------------------
    num_classes idk, 0 ; default: 0
; -----------------------------------------------
    one qb, 1.0
; -----------------------------------------------
    ; Note: we need a size variable for input when our classifier sys_read-s
    classifier_input_size resp, 0 ; same formula as to find buffer size later on
; -----------------------------------------------
    k db, 3



section .bss
; -----------------------------------------------
; WE DEFINE FILESIZE OF OUR TRAINING DATA BUFFER BY USING:
; -----------------------------------------------
    ; (num_rows * num_features) + num_classes
    file_size resp, 0 
; -----------------------------------------------
    ; DEFINE TRAINING BUFFERS
; -----------------------------------------------
    class_values resp, 0

    x_values resp, 0

    y_values resp, 0

    z_values resp, 0
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
    classifier_input_buffer resp, 0
; -----------------------------------------------


; -----------------------------------------------
; Set the buffer for the current closest neighbor (Distance:class)
; -----------------------------------------------
    closest_buffer resp, 0
; -----------------------------------------------
; Set the buffer for the array of closest neighbors (Distance: class)
; -----------------------------------------------
    nearest_neighbors resp, 0
; -----------------------------------------------
; Set up our buffers that keep track of the count of each of our classes 
; -----------------------------------------------
    class_A_count resp, 0
    class_B_count resp, 0
    class_C_count resp, 0


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



