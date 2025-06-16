
# ece510-HwAIML - SPHINCS+: SHA-256 Chip Accelerator Project

The repository contains challenge solutions for ECE 510 - Hardware In AI and ML. Each week, 1 challenge is attempted to see if a solution can be found using LLMs.

## Navigation to Documentation

A page in the wiki is provided to assist with navigation of this repository: [Link](https://github.com/tnl3pdx/ece510-HwAIML/wiki)

## Challenge List

Attempted Challenges (as of 6/4/2025):
- Challenge 5
- Challenge 6
- Challenge 7
- Challenge 8
- Challenge 9  
- Challenge 12 
- Challenge 15 
- Challenge 18 
- Challenge 21 
- Challenge 25
- Challenge 27

Log Book Link: [Google Drive](https://drive.google.com/drive/folders/14qTbDQHp6gnZEJzkRY6MXAn2CLWChqG-?usp=sharing)

(Once the term is done, the files will be exported and saved onto this repo.)

## Requirements

### System Setup

Please use a UNIX-based OS or install WSL2 for Windows to run these challenges.

[WSL2 Installation Steps](https://learn.microsoft.com/en-us/windows/wsl/install)

Suggested: VSCode provides a way to connect to your WSL2 instance once installed: 

[VSCode with WSL2](https://code.visualstudio.com/docs/remote/wsl)

### Python Setup
Install the latest Python version to test a majority of these challenges. 

[Python Installation](https://www.python.org/downloads/)

Make sure to install venv to instantiate Python virtual environments through the start scripts using the following command:

    python3 -m pip install venv

## LLM Usage

In this repository, the following LLMs were used to assist in the creation of code for these challenges:

- Google's Gemini Models (2.0 Flash)
- Anthropic's Claude Models (3.5 Sonnet/3.7 Sonnet/3.7 Sonnet Thinking)
- OpenAI's ChatGPT Models (4o/4.1)

## Simulators

QuestaSim was used for the simulation and testing of the project. This does require a license, but there are open-source simulators that are available to use, such as [Icarus Verilog](https://steveicarus.github.io/iverilog/).

## ASIC Synthesis

OpenLane 2 was used for the synthesis of the design. They have tutorials for installation in their wiki: [Link](https://openlane2.readthedocs.io/en/latest/index.html). When installing the OpenLane repository to your machine, it is recommended to install it into the home directory, as many of the scripts reference the files at this location.

## Sources

Sources that were used in some challenges are mentioned here:

### Challenge 9

**RL-PCB**: [Link](https://github.com/LukeVassallo/RL_PCB)

**Car Racing**: [Link](https://github.com/Farama-Foundation/Gymnasium) / [Wiki](https://gymnasium.farama.org/environments/box2d/car_racing/)

**SPHINCS+**: [Link](https://github.com/tottifi/sphincs-python)

### Challenge 12

**MyHDL**: [Link](https://github.com/myhdl/myhdl)

**PyRTL**: [Link](https://github.com/UCSBarchlab/PyRTL)

### Challenge 15

[SHA256 Visualizer](https://sha256algorithm.com/)

[How Does SHA-256 Work? Youtube Video](https://www.youtube.com/watch?v=f9EbD6iY9zI)

### Challenge 18/21

**OpenLane 2**: [Link](https://github.com/efabless/openlane2)

## Challenge 25/27

**cocotb**: [Link](https://github.com/cocotb/cocotb)















