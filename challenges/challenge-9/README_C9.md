# Challenge 9: Final Project Decision and Introduction

This challenge will be a introduction into researching and choosing a final project for the term. The project I chose is to develop an RL accelerator that can improve the training time for car driving.

Before selecting this project, I tried to look into a RL-based PCB component placer program, but I faced several issues involving the code provided by the paper and training time in general. These are detailed in the log.

[Log for Challenge 9](https://docs.google.com/document/d/19jQnhDfZXu6YweQI545uACPpJ-LIOy4y2dxP9cnUEXE/edit?usp=sharing)


## Tasks for C9
    1. Answer the Heilmeier questions for your project idea
    2. If you have good answers to these questions, you likely have a solid project.
    3. For question 2, use Google Scholar and ResearchRabbit.
    4. Post your answers 
    5. Find code for your algorithm, write your own, or use “vibe coding.” 
    6. Establish an initial software benchmark that will serve as a baseline for comparing your accelerator HW later on.
    7. Analyze the algorithm, identify bottlenecks, generate data-flow graphs, profile the code, generate call graphs. 
    8. Draw a high-level block diagram and/or flow chart of your algorithm.
       - You can either do that based on info about the algorithm you find online and/or
       - Based on the analysis and data of the tools above.
    9. Get a first idea of what parts of your code would benefit from a HW acceleration.
       - PyRTL, MyHDL, or pynq can be used to design or interface with FPGAs or other hardware from Python.
       - libusb, pyserial, or RPi.GPIO can be used to interact with devices drivers through libraries.
       - cocotb or MyHDL can be used for Python-based hardware verification and co-simulation.