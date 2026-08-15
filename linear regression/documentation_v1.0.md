## Version v1.0

Basic linear regression implemented in assembly. Not yet optimized how I want it to be, but its a start
The program consists of _start, loop, accumulate, simplify, error, and end.

### _start: 

 - this exists just to xor out our counter (r15) first and foremost

### loop:

 - I first clear our space in the stack for our float input, as well as point our input to said buffer.
     - **I plan to tweak this so that we don't need to keep allocating/deallocating the stack buffer every loop 
 - Then, I syscall (sys_read) and check rax
 - If there's no more data (rax == 0) then I jmp to simplify, where we preform arithmetic on our accumulations to find m and b
 - If there's an error (rax <= 0) then I jmp to error, in order to gracefully handle said error and return information on what went wrong
 - I check rax once again, this time for partial input (if rax recieved less then 16 bytes)
 - If it has in fact received partial input, I directly skip it and move onto simplifying.
 - The reason for this is that I plan to add a data parser that properly formats and inputs data into our program, in order to make sure partial values cannot be passed through

### accumulate:

 - We clear out xmm4 and xmm5, which are going to act as our new (x, y) values
 - I chose double precision floats as it gives us more breathing room for precision before rounding begins to eating meaningful information
 - We then use pointer offsets to transfer the new input x and y into the previously stated floating point registers
 - Going down the line, we add the new x input to our accumulation of x, our new y to our accumulation of y, and so on.
 - After finishing accumulation for the new inputs, we restore the stack, increment our counter (that represents n, which we need to calculate b later), and jumps back to 'loop'

### simplify:

 - First, we xor our xmm8 to make it zero, then compare xmm2 with it (0) to handle what happens if no data is input to the program. If it is equal to zero, we jump to error
     - **This is primitive and I plan to change this in the next version
 - We restore the stack once again, before doing our arithmetic to find our numerator and denominator. We will occasionally copy the values of xmm0 and xmm0 because when we have to divide with those two
 - After calculating the denominator, we compare it to zero in the same manner we did before, but this time to preemtively check for a divide by zero error. If the denominator is 0, we jmp to error
 - We divide n and d to find our m, before using it in our last calculation in order to find d.
 - We convert r15 to xmm15 before this so that we can divide by the counter

### exit

 - We make another buffer in the stack, but this time, for our output
 - Doing essentially the inverse of before, we now input our m and b values into the buffer
 - We sys_write, and then exit cleanly with exit code 0

### error

 - We exit with code -1
   - **I want to add more verbose error messages in a later iteration
