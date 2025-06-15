module top_tb (rst,clk,data_send_c,data_send_p,start_comm,CS_in);

    parameter PAUSE=1;                 //Number of clock cycles between transmit and receive
    parameter LENGTH_SEND_C=8;         //Length of sent data (Controller->Peripheral unit
    parameter LENGTH_SEND_P=32;         //Length of sent data (Peripheral unit-->Controller)
    parameter LENGTH_RECIEVED_C=32;     //Length of recieved data (Peripheral unit-->Controller)
    parameter LENGTH_RECIEVED_P=8;     //Length of recieved data (Controller-->Peripheral unit)
    parameter LENGTH_COUNT_C=7;        //Default: LENGTH_SEND_C+LENGTH_SEND_P+PAUSE+2=28 -->5 bit counter
    parameter LENGTH_COUNT_P=7;        //Default: LENGTH_SEND_C+LENGTH_SEND_P+2=18 -->5 bit counter
    parameter PERIPHERY_COUNT=1;       //Number of peripherals
    parameter PERIPHERY_SELECT=0;      //Peripheral unit select signals (log2 of PERIPHERY_COUNT)

    //Input signals
    input logic rst;                              //Active high logic
    input logic clk;                              //Controller's clock
    input logic [LENGTH_SEND_C-1:0] data_send_c;  //Data to be sent from the controller
    input logic [LENGTH_SEND_P-1:0] data_send_p;  //Data to be sent from the periphary unit
    input logic start_comm;                       //Rises to logic high upon communication initiation
    input logic [PERIPHERY_SELECT-1:0] CS_in;     //Chip-select (set in the TB)

    //Internal signals
    logic COPI;                                   //Controller-Out Peripheral-In
    wire CIPO;                                    //Controller-in periphary-out //changed from logic to support multiple drivers
    logic SCK;                                    //Shared serial clock
    logic CS;                                     //Chip select
    logic [LENGTH_SEND_P-1:0] data_send_p_internal;          //Data to be sent from the periphary unit
    logic [LENGTH_SEND_P-1:0] data_send_p_buffer;          //Data to be sent from the periphary unit
    logic [LENGTH_SEND_P-1:0] CIPO_register;      //Holds the data received at the controller unit
    logic [LENGTH_SEND_C-1:0] COPI_register_0;    //Holds the data recieved at the peripheral unit (SPI_P_0)
    logic [PERIPHERY_COUNT-1:0] CS_out;           //One-hot encoding

    // Internal logic signals for SHA-256
    // Inputs
    logic           rst_n;
    logic           sha_data_valid;
    logic           sha_end_of_file;
    logic           sha_enable;
    // Outputs
    logic           sha_ready;
    logic [31:0]    sha_hash_out;
    logic           sha_hash_valid;

    // Controller signals
    logic [9:0] message_counter; // Counter for the number of messages processed
    logic [9:0] total_message_size; // Total size of all messages
    logic [3:0] message_size [4]; // Array to hold the sizes of the messages
    logic [2:0] message_digit;
    logic [3:0] output_counter; // Counter for the output messages  
    logic wait_for_sha; // Flag to indicate if we are waiting for SHA-256 to be ready
    logic wait_for_message; // Flag to indicate if we are waiting for a message
    logic notify_sha; // Flag to notify hash is ready

    // Invert reset (SPI uses active high, SHA-256 uses active low)
    assign rst_n = ~rst;  

    //Controller instantiation
    SPI_Controller #(.PAUSE(PAUSE), .LENGTH_SEND(LENGTH_SEND_C), .LENGTH_RECIEVED(LENGTH_RECIEVED_C), 
                    .LENGTH_COUNT(LENGTH_COUNT_C), .PERIPHERY_COUNT(PERIPHERY_COUNT), .PERIPHERY_SELECT(PERIPHERY_SELECT)) 
                    SPI_C_0         (.rst(rst),
                                    .clk(clk),
                                    .SCK(SCK),
                                    .COPI(COPI),
                                    .CIPO(CIPO),
                                    .data_send(data_send_c),
                                    .start_comm(start_comm),
                                    .CS_in(CS_in),
                                    .CS_out(CS_out),
                                    .CIPO_register(CIPO_register)
    );

    SPI_Periphery #(.LENGTH_SEND(LENGTH_SEND_P), .LENGTH_RECIEVED(LENGTH_RECIEVED_P), .LENGTH_COUNT(LENGTH_COUNT_P), .PAUSE(PAUSE)) 
                    SPI_P_0         (.SCK(SCK),
                                    .COPI(COPI),
                                    .CIPO(CIPO),
                                    .CS(CS_out[0]),
                                    .data_send(data_send_p_internal),
                                    .rst(rst),
                                    .COPI_register(COPI_register_0)
    );

    // Instantiate SHA-256 module
    sha256_reduced sha256_inst (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(COPI_register_0),
        .data_valid(sha_data_valid),
        .end_of_file(sha_end_of_file),
        .ready(sha_ready),
        .hash_out(sha_hash_out),
        .hash_valid(sha_hash_valid),
        .enable(sha_enable)
    );

    // Connect the peripheral to the SHA-256 module if the sequence is correct
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            message_counter <= 10'b0;
            message_digit <= 3'b0;
            sha_enable <= 1'b0;
            sha_data_valid <= 1'b0;
            wait_for_message <= 1'b0;
            wait_for_sha <= 1'b0;
            notify_sha <= 1'b0;
            output_counter <= 4'b0; 
            total_message_size <= 10'b0;
            
            for (int i = 0; i < 4; i++) begin
                message_size[i] <= 4'b0;
            end
        end else begin
            if (sha_ready) begin
                wait_for_sha <= 1'b1; // Set ready signal when SHA is ready
            end 
            if (wait_for_sha && !wait_for_message) begin
                // Get message size from COPI_register_0
                if ((COPI_register_0 == 8'hFF || message_digit > 0) && !sha_data_valid) begin
                    message_digit <= message_digit + 1; // Reset digit counter on FF
                    case (message_digit)
                        3'b000: ;
                        3'b001: message_size[0] <= COPI_register_0[3:0]; // Second message size
                        3'b010: message_size[1] <= COPI_register_0[3:0]; // Third message size
                        3'b011: message_size[2] <= COPI_register_0[3:0]; // Fourth message size
                        3'b100: message_size[3] <= COPI_register_0[3:0]; // Fourth message size
                        3'b101: begin
                            total_message_size <= (message_size[0] * 1000) + (message_size[1] * 100) + (message_size[2] * 10) + message_size[3]; // Calculate total size
                            // Start SHA-256 processing if we have total size
                            sha_data_valid <= 1'b1;
                            sha_enable <= 1'b1; // Enable SHA processing    
                            message_digit <= 3'b0; // Reset digit counter
                        end
                        default: message_digit <= 3'b0; // Reset if more than 4 messages
                    endcase
                
                // Begin SHA processing
                end else if (sha_data_valid) begin
                    // If SHA processing is enabled, increment the message counter
                    message_counter <= message_counter + 1;
                end else begin
                    message_digit <= 3'b0; // Keep the same digit
                end

                if (sha_end_of_file) begin
                    sha_data_valid <= 1'b0; // Disable SHA processing after all messages are processed
                    wait_for_message <= 1'b1; // Wait for hash to be computed   
                end
            end else if (wait_for_message) begin
                if (sha_hash_valid && !notify_sha) begin
                    notify_sha <= 1'b1;
                end else if (notify_sha) begin
                    notify_sha <= 1'b0; // Reset notify flag after sending hash 
                end
                if (sha_hash_valid) begin
                    data_send_p_buffer <= sha_hash_out; // Buffer the SHA hash output
                    output_counter <= output_counter + 1; // Increment output counter
                end
                if (output_counter >= 9) begin
                    message_counter <= 10'b0;
                    message_digit <= 3'b0;
                    sha_enable <= 1'b0;
                    sha_data_valid <= 1'b0;
                    wait_for_message <= 1'b0;
                    wait_for_sha <= 1'b0;
                    notify_sha <= 1'b0;
                    output_counter <= 4'b0; 
                    total_message_size <= 10'b0;
                    for (int i = 0; i < 4; i++) begin
                        message_size[i] <= 4'b0;
                    end
                end
            end
        end
    end
    assign data_send_p_internal = (wait_for_message) ? ((notify_sha) ? data_send_p_buffer : 32'hFFFF0000) : data_send_p; // Send SHA hash if ready, otherwise send original data
    assign sha_end_of_file = (message_counter >= total_message_size) ? 1'b1 : 1'b0; // Signal end of file when all messages are processed



endmodule