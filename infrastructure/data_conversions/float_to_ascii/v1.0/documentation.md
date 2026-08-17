## Version v1.0
 
 - Converts the float values m and b from our algorithm into ASCII
 - The resulting characters are written sequentially into 'output_buffer' 
 - The caller (our text parser) is responsible for writing the completed buffer to stdout.

### Pipeline (rough)

IEEE-754 double -> check special cases -> split into integer + fractional
                                                        |          |
                                                        V          V
                                                  divide by 10   multiply by 10
                                                  remainder =    integer portion
                                                  next digit     = next digit
                                                        |          |    
                                                        V          |
                                                  stack reversal   |    already in correct order
                                                        |          |
                                                        V          |  
                                                  ASCII digits <----
                                                        |
                                                        V
                                                  output_buffer

### Output

 - Each generated digit is converted to its ASCII version using the 'digits' table
 - Decimal point is inserted between integer and fractional value
 - The converter parses m and b seperately, using r12 as a state determinant, with 0 meaning we are dealing with 'm' and 1 meaning we are dealing with 'b'
 - 'output_buffer' is shared with the parser, and thus, the parser can simply use it as a pointer to the outputted values for sys_read
