## WIP

### What is this file? It's the design I threw together in like ten minutes. I'm using this as a reference to build with, and so that I can point out what I changed afterwards

### Also, it gives you, the reader, a nice little look into how I'm thinking about these algorithms

We split it into two seperate 'stages'.
Stage 1 - Parsing digits/whatever the non-label values are
Transition prerequisite - parser has detected an ASCII character
Stage 2 - Increment the register that holds the value of the number of columns there are. Each number represents a specific column/feature (idk if feature is the word. I'm not super knowledgeable of ML terminology funnily enough)

Now we need to keep track of more 'states', namely:
Every other state from before
The added states of 'number of columns' and 'what value belongs to what column'.

We have two ways to handle an increased number of states:
Juggle general purpose registers
Move certain states to xmm-registers

I'll decide when I actually get to engineering

I'm making the engineering decision to using a buffer as a means of how we store our training input to feed to the classifier. How will we know the size of this buffer? I'll derive a formula to figure out how many columns/rows there *most likely will be* based on the number of bytes of the file. If I can't do that, I'll just go current filesize * 2 in order to account for both the values passed to the classifier, and the value of what column they belong to.

Now onto the classifier.
It will 'chunk' in groups of 16. Same as our linreg calculator. But this time, instead of for x and y data, it's for x data and class data. x being the value, class data being the assigned column number.
The naive bayes classifier itself should have a state check immediately, to see if it's training on data, or using it's training to now classify.
In training mode, it calculates the probability for any class c to be true when x is true. Simple.
It will need to call the dynamic memory allocator, which will nicely make a buffer for it to hold each of the probabilities for each class. 
After it rets, and 'pings' back to the parser, that signals the parser to now call the dynamic memory allocator AGAIN, make a buffer for the non-training data, for the parser to then call the naive bayes algorithm, now with the 'training' argument set to false. The naive bayes classifier shifts into it's classification state, and uses Bayes' theorem to calculate what class each value belongs to.
We also would need to use the dynamic memory allocator to make an output buffer lmfao.
Anyway, because of the simplicity of the output, I just match the class number to the index of the column, grab that value, then shove the current value we're working with to it (though, this needs to be converted to ASCII. Good thing we already made a float-to-ascii converter, so we can reuse a lot of code there) alongside it.
We FINALLY go and output that in the parser, and bam, we're done.


**Update 1**:
Gonna use struct of arrays, because when I hit a char value (end of the 'column' we immediately call mem-allocator, make a buffer, and dump that column into said buffer.
Problem: Where are we gonna store the pointers to the buffer?
IN ANOTHER BUFFER.
I'll make a buffer of 8(20) bytes, to allow 20 seperate features to be tested simutaniously. (160)

As I'm building this I sorta am starting to realize that I need to start juggling registers to keep up with the states that keep track of number-related stuff and ALSO states that keep track of class related stuff
Amazing.
