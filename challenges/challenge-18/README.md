# Challenge 18: Starting OpenLane 2 Workflow

In this challenge, the goal is to work with OpenLane2 to convert the HDL design created in Challenge 15 and output a ASIC design to check how fast it can be clocked. This challenge involved several dependencies to create a workflow.


## Dependencies

This challenge require install the following tools:

    1. OpenLane2
    2. OpenRAM
       1. Anaconda (installed using script)
       2. Additional Exported Path Environment Variables
    3. SV2V (SystemVerilog to Verilog Converter)

# Tasks for Challenge 18
   1. Read through the OpenLane 2 “Newcomers” intro at [OpenLane2 Intro](https://openlane2.readthedocs.io/en/latest/getting_started/newcomers/index.html)
   2. Getting started with OpenLane 2
      1.  To set up OpenLane 2 on your computer, check out the Getting Started guide at the following link: [OpenLane2 Guide](https://openlane2.readthedocs.io/en/latest/getting_started/index.html)
   3. Pick an example design, your own, or one generate by vibe-coding.
   4. Try to obtain the maximum operating frequency for your ASIC design.
   5. Alternative: Synthesize on FPGA (skipped)
   6. Obtain the maximum operating frequency for your FPGA design.
   7. Use the maximum operating frequency of your design to get a first estimate of the throughput of your accelerator chiplet.

# Summary of Challenge 18