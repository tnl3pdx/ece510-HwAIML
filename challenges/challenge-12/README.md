# Challenge 12: Toy Example Testing with High Level HDL and Selecting HDL tools

This challenge involves searching for High Level HDL tools to use in our implementation of our project. For simplicity, the FrozenLake toy example was used to test the HDL tools that are available in Python.

In the past challenge, I figured out that the hash function in the program was my main bottleneck since every part of the program uses the hash function at some point. Since SPHINCS+ uses many trees, there is a lot of hashing that is involved in the computation of the signature. 

From two HDL tools, PyRTL and MyHDL, I decided on using PyRTL for its easier usage and overall better integration with Python code that isn't HDL. I see it being more useful in a real-time usage, rather than the test-bench method that was attempted with MyHDL.

[Log for Challenge 12](https://docs.google.com/document/d/15jMmQ7skkgFBn3HmJEAERZrbOjLRVaEkFBYpU9Y5-5s/edit?usp=sharing)

## Tasks for C12
    1. Before you complete the tasks below, you should benchmark and profile the algorithm that you chose. 
    2. Based on your initial benchmarking and profiling of your code, make a first informed decision what part(s) should be accelerated in HW.
    3. You may want to do a back-of-the-envelope calculation to see if the HW acceleration is worth the effort.
    4. The HW acceleration is only worth it if T5 + T6 + T7 < T3.
    5. Next, based on your background and interests, pick one of the high-level tools listed below that will allow you to do rapid HW prototyping in Python.
    6. Implement a toy example to test the entire design workflow. E.g., FrozenLake RL code in which you implement the Q value updating formula in hardware (think adders + multipliers).
    7. Once you know the tools will be right for you, start implementing your own HW design for your chosen algorithm.