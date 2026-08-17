## Version v1.0
 
 - Converts the float values m and b from our algorithm into ASCII
 - The resulting characters are written sequentially into 'output_buffer' 
 - The caller (our text parser) is responsible for writing the completed buffer to stdout.

### Pipeline (rough)

IEEE-754 double -> check special cases -> split into integer and fractional

**Integer**
The integer portion is converted one digit at a time using division by ten.
Our last digit will be stored in rdx, our remainder
The remaining integer is in our quotient, aka, rax
We cmp rax each time with 0, as the quotient being 0 would equate to there being less then 2 decimal places left, so we move on from the integer part
Since division provides the least significant digit first, we push the value onto the stack, to pop it off in the reverse order

**Fractional**
The fractional portion is repeatedly converted by multiplying by ten, and using conversions between ints and double-floats in order to essentially kill off all remaining decimal places
We re-convert this back into an integer, and push it onto the stack
We convert the integer *back* into a float, and now we have a single digit float stored in xmm0
Subtract 10(xmm10) - xmm0 to reduce the value of xmm0 for next time
Repeat until the fraction is exhausted

### Output

 - Each generated digit is converted to its ASCII version using the 'digits' table
 - Decimal point is inserted between integer and fractional value
 - The converter parses m and b seperately, using r12 as a state determinant, with 0 meaning we are dealing with 'm' and 1 meaning we are dealing with 'b'
 - 'output_buffer' is shared with the parser, and thus, the parser can simply use it as a pointer to the outputted values for sys_read
