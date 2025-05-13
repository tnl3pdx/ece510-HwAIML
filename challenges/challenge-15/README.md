# Challenge 15: HDL Implementation of SHA256

In this challenge, I will be attempting to implement the SHA256 algorithm in SystemVerilog. 


# Tools

For tools, I will be use Icarus for compiling my code, and GTKWave to visualize waveforms. To install these, use the following command:

    sudo apt install iverilog gtkwave

# Tasks for C15

    1. Based on your HW/SW boundary (which may be tentative) from last week, write an HDL (hardware description language) description of your HW part.
    2. If you have never done Verilog, SystemVerilog, or VHDL, here are some resources:
        o Verilog: https://www.geeksforgeeks.org/getting-started-with-verilog
        o SystemVerilog: https://verificationguide.com/systemverilog/systemverilog-tutorial
        o VHDL: https://nandland.com/learn-vhdl
    3. Alternatively, take your Python or C/C++ high-level code and ask your favorite LLM to translate it into SystemVerilog.
    4. Alternatively, use toy example (e.g., Frozen Lake Q table update formula) and convert that into a HW design (manually or with an LLM).
    5. Write (or have your LLM write) a basic testbench for your design: https://fpgatutorial.com/how-to-write-a-basic-verilog-testbench
    6. Simulate and test the design.
    7. List of HDL simulators: https://en.wikipedia.org/wiki/List_of_HDL_simulators
    8. Unless you know Cadence & Synopsis tools, I’d recommend you use verilator:
        o Verilator is a free Verilog/SystemVerilog simulator.
        o https://github.com/verilator/verilator
    9. Alternatively, you can use one of the tools from the week 3 codefest (challenge #13) if you are
    able to write Verilog RTL code.
