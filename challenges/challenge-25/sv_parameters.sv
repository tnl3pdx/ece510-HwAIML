package spi_params;
    parameter PAUSE=1;                 //Number of clock cycles between transmit and receive
    parameter LENGTH_SEND_C=8;         //Length of sent data (Controller->Peripheral unit
    parameter LENGTH_SEND_P=32;         //Length of sent data (Peripheral unit-->Controller)
    parameter LENGTH_RECIEVED_C=32;     //Length of recieved data (Peripheral unit-->Controller)
    parameter LENGTH_RECIEVED_P=8;     //Length of recieved data (Controller-->Peripheral unit)
    parameter LENGTH_COUNT_C=7;        //Default: LENGTH_SEND_C+LENGTH_SEND_P+PAUSE+2=28 -->5 bit counter
    parameter LENGTH_COUNT_P=7;        //Default: LENGTH_SEND_C+LENGTH_SEND_P+2=18 -->5 bit counter
    parameter PERIPHERY_COUNT=1;       //Number of peripherals
    parameter PERIPHERY_SELECT=0;      //Peripheral unit select signals (log2 of PERIPHERY_COUNT)
endpackage