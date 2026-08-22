# asm-algorithms
Different algorithms implemented in x86_64 Assembly

## Current algorithms that actually work:

 ### Linear regression (least squares)

 - v1.0: Full working demo. Takes a .txt file, and outputs m and b for the coords given.
   - NOTE: These values are accurate to whole number only. For some reason the program auto rounds any number *down*, regardless of decimal places.
   - Infrastructure included: Memory allocator, parser for the file, converter of floats to ascii
 
