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

# Summary of Challenge 5

In Challenge 5, out of the example workloads, I chose these 3: differential equation solver, quicksort, and RSA cryptography. The goal of this challenge was to implement these workloads using the help of LLMs and work on developing a workflow for profiling these scripts. 

Note: For more details on my documentation, the link to my logbook provides a better visual of my progress through this challenge. This will be replicated in my other challenges as well.

## Diff. Equation Solver

In this script, my goal was to have a way to input an equation into the program, configure the parameters, and have the solver output a graph of the diff. eq. As I was not familiar of vibe-coding, my very first prompt is as follows: 

    Create a differential equation solver for ordinary differential equations in Python which can take in user input

This provided an okay result, but I had to provide many additional prompts to get my intention across (shown more in the logbook). Here, I began to realize that my approach was not the best to vibe-code, but at this point, I wanted to experiment more in this way before switching my approach later.

The final program result is shown below:

<img width="500" src="https://github.com/user-attachments/assets/649af85c-b1fa-41e3-b2bd-23afe1763a66">

For testing the script, I provided two equation pairs: dy/dt = -y, y(0) = 1, and dy/dt = -y/(t+1), y(0) = 500. The first diff. eq. should result in a declining exponential, which the program outputs the expected graph.

<img width="500" src="https://github.com/user-attachments/assets/ab23d155-1d88-48e9-9845-804e07f72b98">

For the second equation, this should have characteristics of a 1/x graph. Providing the equation and parameter to the script results in the following.

<img width="500" src="https://github.com/user-attachments/assets/c6c34993-6d21-49cf-8341-77b3245f91a4">

For both equations, the script properly outputs the solution through a visual graph.

## Quicksort

In this script, I used a bit more detail in my prompting. The first prompt I used to ask the LLM was: 

    Create a python program that performs a quick sort algorithm that can take in a external text file. This text file will contain random values separated by new lines. Output the results to a new text file with an appropriate name.

Even with the additional details, there were some parts that I needed to clean up with additional prompts, such as asking the LLM to take in custom txt files and adding a user menu when using the tool. Later in the profiling stage, I realized that this approach to scripting isn't ideal, as it results in a ton of additional work to get the profiler to navigate the menu. It is best to use user arguments as the main way to interface with the profiler, but I was not aware of this at the time.

<img width="500" src="https://github.com/user-attachments/assets/fe450f2d-fe7b-4671-8b8c-1c0d00b9137c">

To test this program, I asked the LLM to produce a text file that contained the numbers from 1 to 100, but randomly ordered to test the quicksort algorithm. Feeding this text file to my script produced an output text file that was properly sorted throughout, which showed that the algorithm worked.

<img width="500" src="https://github.com/user-attachments/assets/f2ca2bd2-00fb-4c2c-9602-8370c251b732">

## RSA Cryptography

In this script, since I was not very knowledgable in any cryptography algorithm, I asked the LLM about what parts do I need in a RSA encryption scheme. The LLM provided me that I needed to generate keypairs, and have a way to encrypt and decrypt the files using those keys. Using that knowledge, I started my prompt with much more details after seeing the effect it provided in the previous script generation to implement those key ideas.

    Can you make a RSA tool that provides a menu that allows the user to decrypt a file using a private key, encrypt a file using a public key, and generate public and private keys

The resulting code required some additional prompts to make sure that the file generation and retrieval were working correctly. However, I realized that the prompts I gave to the LLM to fix these problems were not necessary, and they were an artifact of forgetting how to use Python on a shell terminal. After finishing this challenge, I realized that I did not cd into the target directory to run the program. I detail this more in the **Exploring Python Environments** section.

<img width="500" src="https://github.com/user-attachments/assets/933df9fb-7895-41d2-af9e-beafb06df6fd">

I added some random text to my input file for testing. When running the script using my input file, I was able to produce keypairs, encrypt the file using the private key, and decrypt the encrypted file using the public key. 

<img width="1000" src="https://github.com/user-attachments/assets/28fc8a93-63a5-413a-a514-fed710768e76">

## Profiling

After completing all 3 programs, I moved to profiling them in the following parts: bytecode generation/disassembler, instruction counter, and profiler.

### Bytecode/Disassembler

The first step was to generate bytecode from my program. I asked the LLM to generate me a script called compile.py that would compile my programs into bytecode that can be analyzed later using the following prompts:

    For an existing Python script, is there a way to compile it into bytecode
    Can you change this code to accept a custom file to compile
    Can you do this as text entry instead of command line

I encountered some file location issues, which are related to the **Exploring Python Environments** section. To fix this, I asked the LLM to have the user provide a filepath to the location to have the file saved. There was also an indexing issue which I got the LLM to solve by arbitraly asking the LLM if there was an error present. The resulting code is shown below.

![image](https://github.com/user-attachments/assets/ce75a111-2533-436f-a00d-063a813166ff)

Taking a look at the bytecode produced, it did not look like any ISA that I was familiar with such as x86 or ARM. I asked the LLM to tell me what type of instructions these were. It told me that this code is part of Python's own VM called Python Virtual Machine. Taking a look from the LLM, there is a total of 80 instructions, and 12 of them are arithmetic operations.

## Instruction Counter

I asked the LLM the following prompt to generate a script to see the distribution of instructions used in each of my programs:

    Generate me a Python program that takes in x number of disassembled Python programs stored as txt files (pass file path to program), and returns an instruction distribution count of instructions in each file. State each unique instruction and its count to the console. also, the program should stop taking in files when nothing is typed, and this is when it should return the distribution count

I had many issues of getting a parser that would properly read the correct instructions, thus I revised this prompt with more details.

    Generate me a Python program that takes in x number of disassembled Python programs stored as txt files (pass file path to program), and returns an instruction distribution count of instructions in each file. State each unique instruction and its count to the console. Also, the program should stop taking in files when nothing is typed, and this is when it should return the distribution count. A line may contain other substrings that are not the instruction, so only count strings that have all capital letters, may contain an underscore, and do not include numbers.

This prompt provided a much better result, but required some revisions to have it accept multiple text files to produce a table (shown in the log). The final program provided me with the following result after passing each of the dissaseembled python programs:

![image](https://github.com/user-attachments/assets/1cb72363-3d1f-4d79-8f84-7997046f1306)

However there was an artifact from the parsing which counted the C in filepaths which was not too big of a problem, so I kept it in as I spent way too much time refining this part of the challenge. The conclusion I made from this table is shown in the following excerpt from my log:

_Based on the instructions provided, the dif. eq. solver doesn’t use much instructions (since it is a much smaller program). But it uses many loads instructions to operate on. The quicksort program uses a medium amount of loads, and the rsa program uses the most loads. Much of the instruction use is more heavy on the RSA program._

### Profiler

For the profiler, I used the following prompt to generate a Python script profiler:

    Make a Python profiler program that uses cProfile and snakeviz to measure the execution time and resource usage of another Python program. allow for the profile to take in user input for passing a path to the target Python program. 

I had to add some minor changes using some additional prompts for the program to handle Windows-based filepaths, but after adding those, the profiler worked, but the stats were not providing an accurate representation of the program. I realized at this point, my previous programs were using user menus which don't work well with profilers, as it's difficult to guide the profiler to navigate the menu. I made some changes to my prior programs (detailed in the log) for them to execute without needing any user input. They are somewhat hardcoded to specific filenames, as I did not find a good way to pass user args until later challenges. After passing the programs back into the compiler and disassembly, the instruction count did not differ too much, besides some minor changes to the code.

Running the profiler resulted in some interest findings. Apparently, my diff. eq. solver took the longest, even though I would expect that the RSA encryption program would take longer. My hypothesis is that the diff. eq. solver needs to plot a lot of points and has to graphically plot them which may require more time for drawing out the graph.

![image](https://github.com/user-attachments/assets/f1264f2d-6493-4003-86ce-341c67dc563c)

### Analyzer

For analyzing the programs, I asked the LLM to generate a script that could analyze the algorithm structure and data dependencies of another script:

    Make a Python program that can analyze the algorithm structure and data dependencies of another python script. have the program wait for the user to enter a filepath to the target script.
    
    Change this code to be able to pass multiple file paths to target python scripts for analysis. print the findings in a tabulate manner, so that each script name is associated by a column (shorten the file path to only the script name when printing)

Luckily, these two prompts resulted in a script that provided want I wanted. When running the script with the workload scripts as input, it produced a table that provided structural information about each program.

![image](https://github.com/user-attachments/assets/10f18636-89a6-4ec2-8135-cb9c93510ea4)


## Workload Analysis

From my log, I detail my analysis of the workloads and my suggestions of what type ISA would be best suited for each:

From the information gathered, I think that the instruction architectures that would be best suited for each workload can be divided into two different categories: optimized for OS/system and optimized for algorithms. 
        
The difeqsolver program had the longest execution time which I suspect is caused by its use of matplotlib. This requires a visual UI to be opened when execution is done. An ISA that is more optimized for the OS that is running the program might be more efficient. I am using Windows for these programs, so an x86 ISA can be more efficient for this program.

The quicksort and rsa programs had many function calls, and the quicksort algorithm is optimized for execution on computers. However I did notice that the creation of RSA keys did take slightly longer, so an ISA that is optimized for crytography is ideal. I would go with something similar to ARM, as it is much more power efficient while being able to run these programs.


## Exploring Python Environments

I do have experience in using Python and programming Python, but I have not tried it in a shell environment with VSCode as my main editor. At the time, I was not very informed on how to use virtual environments for Python, as I was still exploring the ways I should organize my codebase. The issue I encountered was that my venv folder, which held my packages and Python executable, was being generated in the root directory. This caused a lot of issues in running my programs, as many of the generated files were being sent to the root directory. When I tried to install libraries without a virtual environment, it would not let me:

![image](https://github.com/user-attachments/assets/2fdd1cbc-2396-444c-9d78-35f606f06212)

I wanted to detail this in my first challenge, as in later challenges, I found a better workflow for using Python through the use of a start shell script to generate a venv environment and install packages using a requirements text file.


## Vibe Coding Experience

Since this is my first time vibe-coding, my usage of it was not very thorough in terms of the prompt I provided for the first 2 programs. I provided very shallow prompts, which resulted in code that was not exactly up to par with my thinking. Starting in the RSA script, I began using long prompts with more details about the program I have envisioned, and this resulted in a much more effective result from the LLM.

Going through the first two programs, I was quite surprised by the capability of LLMs and how useful they can be in developing programs. For me, I was somewhat rusty in my diff. eqs. and I didn't exactly remember how the quicksort algorithm worked. But prior to jumping into these programs, I asked the LLM some more research-based questions to help me understand these concepts a bit more before I attempted to create them.








