## How input data is taken, processed, and output:

## Allocating memory

- File parser calls memory allocator 
- Memory allocator allocates a buffer, 'statbuf', for where file metadata will go
- Memory allocator uses syscall 'openat' to find the file descriptor
- Using the file descriptor, we can now use syscall 'fstat' to find metadata about the file, including the size, which we will use to dynamically allocate memory for our file parser
  - The specific locations/layout of this metadata differs from CPU-to-CPU I believe, always check the layout of the metadata output for fstat before using it to find file size
- Memory allocator calls mmap, using 'statbuf' with an offset of 48 in order to find our file size
  - We use 48 as it is the exact number of bytes we must traverse to get to the file size metadata
- rax is the current pointer to the now mapped out file in memory, while rdi currently holds the size of the file
- We return to the parser, but we need to call the memory allocator a second time due to needing an extra buffer to put the parsed data into, so that our linreg algo can process it
- We move our pointer and file size to non-clobbered registers, before finding rdi * 16
  - Why rdi * 16? rdi holds our file size right now, we multiply that size by 16 to account for the size of the raw data given in bytes, that will be passed into memory

- We call our memory allocator again - this time with rdi != 0
  - this tells our memory allocator that we are running it with an argument; the filesize * 16
  - Due to already having the filesize, we can skip straight to mmap-ing our buffer out.
  - Once again, rax is our pointer, this time to our output buffer to the processor. rdi too is now the filesize * 16, to account for the text being parsed into raw bytes for our processor to handle.
  - We swap values around in registers to make them easier to work with
 
- Now its time to actually parse the data.

## Core parsing loop

- We need to manage:
                   - r11, which keeps track of if we have converted our integer into a float yet
                   - r12, which keeps track of if our current coordinate is negative or positive
                   - r13, which keeps track of if we're dealing with an x-coordinate, or a y-coordinate
                   - r14, which keeps track of if we are before, or after the decimal point

- Furthermore, r10 keeps track of how many decimals there are, in order to divide by 10^r10, so that we can make sure it has the correct decimals

- We check if our counter is equal to r15 (so that we know if we've dealt with the entire file), if they're equal, we move to exit, otherwise;
- we clear our r8 and move a byte of [rsi] (the current pointer to the input buffer) with an offset of r15 (the counter, repurposed to measure how many bytes we must offset to get to the current digit)
- we compare r8 to '0' and '9', if it's not in that range, then it's not a digit, we'll get to that now
- subtract our current input digit with '0', which converts this into a raw integer
- Multiply our current accumulation of the current digits, to essentially move the whole number up one decimal place, and make 'room' for the new int
- Increment r15 - our counter
- Checks if our number is past the decimal point, if its not, we can restart the loop. If it is, then we increment r10 - which keeps track of how many decimal points there are - and then we can restart the loop


## Outputting values to the processor

- Remember that check if our current digit was not actually a digit? If it's not, we move to the 'not a digit' section
- if it's a comma, we move to 'end of number true', to update our state machine
- if its a decimal point, we move to 'decimal true', to update our state machine
- if its a dash ('-'), we move to 'negative true', to, you guessed it, update our state machine

## Preperation for output to processor
- We convert our signed integer accumulated value into a signed double float, now stored in xmm0
- we check if our negative state is true, if so, we move onto **Handling negative numbers**
- Because we just checked for negative-state-true, we temporarily repurpose r12 (our negative state tracker) to be used to deal with making our double into the correct number
- We check for float state (aka, if its been converted into a proper value yet or not), if true, we move onto **Converting to proper decimal value**
- We check for x/y state. If we're working with x, we move on to **storing x**, otherwise, we move into **outputting our coordinates**

**Handling negative numbers**:
  - Because there's not a proper 'neg' command for the float-registers, we just copy our current integer into xmm1, add it to itself, and then subtract that value from the original one
  - In simpler terms, we subtract our decimal by itself * 2 in order to find the negative representation of it
  - We move back to **preperation for output to procesor**, now with the negative-state reset, so that we can pass that state-check and move onto the next

**Converting to proper decimal value**:
  - Firstly, we prepare our divisor. We multiply r12 by 10, which should be one (this is what I meant by repurposing it)
  - we decrement r10, which measures how many decimals there should be
  - Check if there's any decimals left, if yes, move onto actually calculating the decimal. Otherwise, loop back to the beginning of preparing our divisor
  - To calculate the decimal, we convert signed integer r12 (our divisor) to float, and divide xmm0 (our accumulated float value) by it. 
    - This essentially forces the big integer part of the float to 'move back' behind the decimal, as dividing by ten 'moves' each digit 'back' by one. This is how we calculate the proper float value
  - We reset a few states (float state, before/after decimal point, number of decimal places to 'move back' by)
  - We check if our y-state is true, if so, we auto-move to streaming the coords, as we've basically done everything we needed to do, so we do not need to move back into preperation
  - If the y-state is false, then we move to storing x

**Storing x**
  - after resetting a few states to be ready to handle y, we move our current x value float into a different register - xmm10
  - we then jump back to the loop. Regardless of what way the program entered 'store x', the y-value state would be set to true, signalling that we are dealing with a y-coord

**Outputting our coordinates to the processor's buffer**:
  - After clearing out our state trackers, the accumulated int value, and etc, we move our x and y value into [rax+rcx] for x, and [rax+rcx+8] for y
    - in this case, rax is a pointer to our processor buffer, and rcx is our offset from that buffer. We add an extra 8 as an offset when dealing with our y value to account for the fact that x took up space
  - We add 16 to rcx, this accounts for the offset of the two x-y values in the buffer, so that we don't overwrite values just put into the buffer.

## Processing values via linear regression

  - Once we have parsed all values, we move onto the processing. We call our linear regression algorithm, with rdi, as the new pointer to the processor buffer, our first parameter, and rsi, which now holds the size of our buffer, to the second parameter
  - We check rcx (which has been incremented with steps of 16 if you remember) to see if its 0 yet, as this represents how many values we've processed so far
  - if everything is good, we move an x value into xmm4, and a y value into xmm5
  - We use four other registers to keep track of the accumulated values of x, of y, of xy, and of x^2
  - After adding all those x-y values to the accumulations, we move onto actually finding m and b 
  - We find N and D for our algorithm, and we divide them to find m. We use the accumulated values again, now with n (the counter of how many times we accumulated x/y values) in the mix too, to find b
  - we return xmm0 - our m - and xmm1 - our b - to the parser.

## Converting raw bytes into ASCII for output
  - we're in endgame now
  - We call our float-to-ascii converter, handing it m and b as parameters
  - We make two rodata thingys that'll help us later; digits, that act as a way to convert a single digit of data into a single digit of ascii, and ten, which lets us handily store a 10.0 into an xmm- register
  - We also make an output buffer
  - firstly, we deal with m. We store xmm0 into xmm10, which will represent the current variable we work with. When it's time to work with b, we store away the xmm10 value that holds m-related data, and moves xmm1 into it, to handle b
  - We put [ten] into xmm2, and then isolate the different parts of the float (sign, exponent, and fractional)
  - We quickly check for zero, subnormal, NAN, or an infinity to shortcut our way into output and serve as a layer of protection against errors. 
    - I plan to add proper handling for subnormal numbers in the future
  - I then use repeated conversions between decimals and integers as a way to 'zero out' the digits after the decimal point. This is to isolate the integer and decimal part of the number for handling seperately
    - Converting a float to an integer rounds the number *down* to a whole number. That acts as our 'integer part'. We find the decimal part by subtracting the full float value by *just* the integer part, now converted back into a float
  - With our int and decimal isolated, we can get to work processing them.
  - Starting with the int part, we start our loop by dividing our int-part (currently in rax) by r9 (holding 10).
    - The quotient will be stored in rax, the remainder, in rdx
  - We can push rdx - the remainder, which is the last number of the int value - to the stack, while checking if our quotient is 0. If it is, we know we've pushed all of our int values on the stack
    - we also increment rbx to keep track of how many push-es we've made
    - we're taking advantage of the fact that pop technically reverses everything we've put onto the stack, and since we pushed the values lowest-to-highest, this works out well for us
  - We can now convert our int into ascii
  - Firstly, we check the sign to see if our value has to be negative. If so, mov a '-' into the output buffer, and increment rcx (which is our offset) by one to account for it
  - We check if we've finished pop-ing our values off the stack. If we have, then we can move a '.' onto the stack, and account for the offset. We would then move onto handling the decimal value
  - otherwise, we lea [digits] into r14 to act as our converter. We pop a value off the stack, and use it as our index to store into r13b. We increment our offset, decrement the counter of how many things are on the stack, and loop
  - Now working with decimals, we take a different approach.
  - We duplicate our original decimal value, and then multiply the copy by ten, before converting THAT value into an int - this isolates the first decimal place as an int
  - Unlike with integers, we can now directly use this value to go through the whole lea [digits] shebang, no push/pop needed!
  - We then convert the decimal value into a float again, to subtract the original value by this. This is effectively moves the all the decimal places up by one.
    - to put it bluntly, I'm a bit confused about how I did this part, and why it works as intended. But it uh...it works right now, and I don't wanna change the logic and have it break again. 
    - I'll define the logic more clearly in the next iteration
  - We xor out xmm7 to act as 0, and then use it to check if we've exhausted all the decimal places. If so, great, we can move on to b, otherwise, loop.

  - Finally, we move x0a into the buffer to act as a newline.

## Outputting the values

  - We sys_write, with the output buffer's address being stored in rsi, and rcx being stored in rdx to account for how big the values are (as we incremented rcx each time to keep track of how big the output is
  - finally, we exit.
  - this documentation took me way too long to do.
  
