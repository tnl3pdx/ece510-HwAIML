# Challenge 25

This challenge focuses on using the cocotb testsuite to test an SPI module.

For source code of the SPI module, I used [tom-urkin](https://github.com/tom-urkin)'s SPI repository, which can be found here: [Link](https://github.com/tom-urkin/SPI/tree/main)

![image](https://github.com/user-attachments/assets/6c716b36-597a-40e6-814d-7958d8f26fea)


[Log for Challenge 25](https://docs.google.com/document/d/1Oy4-bRJ7l0Lyl9WeyTtMmbvLG7Scp5g-CBwCc1dWNYU/edit?usp=sharing)

# Tasks for Challenge 25

![image](https://github.com/user-attachments/assets/6df5eb22-70e5-46dc-89b8-c92f54796c69)

# Usage

To start the Python environment, type the following:

    source start.sh


Move the SPI_Controller, SPI_Periphery, and SPI SV files out one directory into the src_sv folder, and replace the parameters in the SPI.sv file with the ones in the sv_parameters.sv file.

![image](https://github.com/user-attachments/assets/1e9130a1-d29f-4ac5-8818-c5359e18ca65)

![image](https://github.com/user-attachments/assets/fb898cdc-df64-4f4f-bfe1-fb12946e4297)

![image](https://github.com/user-attachments/assets/c82f4a96-fe34-45cd-89e1-0bcc4369a737)


To start the cocotb tests, type the following commands:

    ./run_test.py --test functional

    ./run_test.py --test performance
