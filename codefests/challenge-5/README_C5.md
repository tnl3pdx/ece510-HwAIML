# Challenge 5

In this challenge, the goal was to utilize LLMs to create several Python scripts to become familiar with "vibe coding" and useful Python scripts that can be used in our final project.

[Log for Challenge 5](https://docs.google.com/document/d/1XcF3CRrBOHWalfG8xPQ686ce_saWbHYDSeSkMUAZ8fs/edit?usp=sharing)

# Tasks for Challenge 5

    1. Pick 3 different Python programs/workloads. (*: these are the workloads I chose)
        a. Differential equation solver*
        b. Convolutional neural network
        c. Traveling Salesman Problem (TSP)
        d. Quicksort*
        e. Matrix multiplication
        f. A cryptography algorithm, e.g., AES*
        g. ...
    2. Either write your own code (probably not enough time), download some code, or ask your LLM to
    generate examples.
    3. Compile the code into Python bytecode. Ask your LLM how to do that. Or look it up. Hint:
    py_compile.
    4. Disassemble the bytecode and look at the instructions. Hint: dis
    5. Can you guess what virtual machine Python uses just by looking at the bytecode?
    6. How many arithmetic instructions are there? Hint:
    http://vega.lpl.arizona.edu/python/lib/bytecodes.html
    7. Write a script that counts the number of each instruction. Hint: ask your LLM.
    8. Compare the instruction distribution for your 3 workloads.
    9. Use a profiler to measure the execution time and resource usage of your codes. Hint:
    cProfile. Hint: snakeviz allows for interactive visualization.
    10. Ask your LLM to write you some code to analyze the algorithmic structure and data dependencies
    of your code to identify potential parallelism.
    11. Now, knowing all these details, what instruction architectures would you build for each of these
    workloads?
    12. Document all your findings and insights carefully. What did you learn?
