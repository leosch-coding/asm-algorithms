# asm-algorithms
Different algorithms implemented in x86_64 Assembly

## Current algorithms that actually work:

 ### Linear regression (least squares)

 - v1.0: Full working demo. Takes a .txt file, and outputs m and b for the coords given
   - Infrastructure included: Memory allocator, parser for the file, converter of floats to ascii
 - v2.0: WIP
   - Planning to add kahan summation, as well as centred values to improve numeric stability

 ### k-NN 

 - v1.0: Core algorithm and infrastructure is finished. I plan to feed in inputs through a python script later on, to let it train/classify in real time.

 - v2.0: WIP
   - Planning to add an initial k-NC algorithm to increase speed of classification, falling back to regular k-NN if confidence (probably ratio-based) is low
   - Also needs to...well...actually output stuff to the terminal.
   
## Algorithms currently being developed:

 ### Naive Bayes

 - I've been programming both the 'exp' and the 'log' functions, both using Taylor series right now. Is this precise? Not really, I'm going to improve it in the next iteration
 - Both will be posted alongside Naive Bayes
 - Exp and Log functions are intentionally left generic and primitive in order to be tweaked as needed
 - Estimated completion time for log/exp: today
 - Estimated completion time for full algorithm: 2-3 days
