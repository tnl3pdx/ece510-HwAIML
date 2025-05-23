/* Message Controller Module
    Input: takes in a stream of 8-bit data and processes it to prepare for SHA-256 compression.
    Processing: handles padding, length appending, and block segmentation.
    Output: provides 512-bit blocks to the compression loop for hashing. (32-bit words per clock)
*/
module message_controller (
    input  logic        clk,            // Clock signal
    input  logic        rst_n,          // Active low reset
    input  logic [7:0]  data_in,       // Input data stream (8 bits)
    input  logic        data_valid,     // Indicates valid data for data_in
    input  logic        end_of_file,    // Indicates end of input data
    input  logic        busy,           // Incoming busy signal from compression loop
    input  logic [5:0]  word_address,   // Address from compression loop to read data
    input  logic        req_word,       // Request signal from compression loop
    input  logic [7:0]  current_block,  // Current block index
    input  logic        enable,         // Enable signal for message controller

    output logic [31:0] word_data,      // Data to be sent to compression loop
    output logic        word_valid,     // Indicates if word from message controller is valid
    output logic [7:0]  num_blocks,     // Number of 512-bit blocks
    output logic        ready,          // Indicates if SHA-256 is ready to accept data
    output logic        done            // Indicates if message controller is done processing all blocks
);
    // States
    typedef enum {
        IDLE,
        RECEIVE,
        PADDING,
        LENGTH_APPEND,
        CALCULATE_BLOCKS,
        READY,
        PROVIDE_DATA
    } state_t;

    state_t state, next_state;

    // Parameters
    //localparam MAX_MESSAGE_BYTES = 1024;  // Maximum message size (can be adjusted)
    

    // Internal registers
    logic [12:0]    bit_count;         // Counter of bits in the message
    logic [12:0]    temp_msgLen;       // Counter for tracking message length
    logic [9:0]     byte_count;        // Counter for bytes in the message
    logic           padding_phase;     // Track padding progress
    logic [2:0]     length_phase;      // Track length append progress
    logic [3:0]     block_section;     // Track block output section

    // Memory signals
    logic [7:0] write_data;       // Data to write to memory buffer
    logic [7:0] read_addr;         // Read address for memory buffer
    logic [31:0] read_data;        // Read data from memory buffer
    logic enable_write;         // Enable write signal for memory buffer

    msg_ram memory_buffer (
        .clk(clk),
        .we(enable_write),
        .waddr(byte_count),
        .wdata(write_data),
        .raddr(read_addr),
        .rdata(read_data)
    );

    // State machine
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            bit_count <= 13'b0;
            temp_msgLen <= 13'b0;
            byte_count <= 10'b0;
            padding_phase <= 1'b0;
            length_phase <= 3'b0;
            num_blocks <= 8'b0;
            ready <= 1'b0;
            done <= 1'b0;
            block_section <= 4'b0;
        end else begin
            state <= next_state;
            
            case (state)
                // IDLE state: waiting for data
                IDLE: begin
                    bit_count <= 13'b0;
                    byte_count <= 10'b0;
                    padding_phase <= '0;
                    length_phase <= 3'b0;
                    num_blocks <= 8'b0;
                    ready <= 1'b1;
                    done <= 1'b0;
                    block_section <= 4'b0;
                end
                
                // RECEIVE state: receive data per clock cycle (8-bits per clock)
                RECEIVE: begin
                    if (data_valid) begin
                        bit_count <= bit_count + 8;
                        byte_count <= byte_count + 1;
                    end
                end
                
                // PADDING state: handle padding and length appending
                // Append '1' bit (0x80) and '0's until 448 bits mod 512
                PADDING: begin
                    if (padding_phase == 0) begin
                        bit_count <= bit_count + 8;
                        byte_count <= byte_count + 1;
                        padding_phase <= 1;
                        temp_msgLen <= bit_count;
                    end else begin
                        // Append '0's until 448 bits mod 512
                        if ((byte_count % 64) != 56) begin
                            bit_count <= bit_count + 8;
                            byte_count <= byte_count + 1;
                        end
                    end
                end
                
                LENGTH_APPEND: begin
                    // Append message length as 64-bit big endian integer
                    bit_count <= bit_count + 8;
                    byte_count <= byte_count + 1;
                    length_phase <= length_phase + 1;
                end
                
                CALCULATE_BLOCKS: begin
                    // Calculate number of 512-bit blocks
                    num_blocks <= (byte_count + 63) / 64;
                end
                
                READY: begin
                    // ready <= 1'b0;
                    done <= 1'b1;
                    padding_phase <= '0;
                end
                
                PROVIDE_DATA: begin
                    if (req_word && word_valid) begin
                        block_section <= block_section + 1;
                    end
                end
            endcase
        end
    end

    // Combinational logic
    always_comb begin
        // Default assignments
        enable_write = 1'b0;
        read_addr = 8'bz;
        write_data = 8'bz;
        word_data = 32'h0;
        word_valid = 1'b0;
        if (state == RECEIVE) begin
            // Write data to memory buffer
            enable_write = 1'b1;
            write_data = data_in;
        // Padding values to write data if in PADDING state
        end else if (state == PADDING) begin
            enable_write = 1'b1;
            if (padding_phase == 0)
                write_data = 8'h80;
            else
                write_data = 8'h00;
        end else if (state == LENGTH_APPEND) begin
            enable_write = 1'b1;
            if (length_phase == 6)
                write_data = {5'b00000, temp_msgLen[10:8]};
            else if (length_phase == 7)
                write_data = temp_msgLen[7:0];
            else
                write_data = 8'h00;
        end else if (state == PROVIDE_DATA) begin
            // Read data from memory buffer
            read_addr = {word_address, 2'b00};
            word_data = read_data;
            word_valid = req_word;
        end 
    end
    
    // Next state logic
    always_comb begin
        next_state = state;
        case (state)
            IDLE: begin
                if (data_valid && enable) next_state = RECEIVE;
            end
            RECEIVE: begin
                if (end_of_file) next_state = PADDING;
            end
            PADDING: begin
                if (padding_phase > 0 && (byte_count % 64) == 56)
                    next_state = LENGTH_APPEND;
            end
            LENGTH_APPEND: begin
                if (length_phase == 7) next_state = CALCULATE_BLOCKS;
            end
            CALCULATE_BLOCKS: begin
                next_state = READY;
            end
            READY: begin
                if (!busy) next_state = PROVIDE_DATA;
            end
            PROVIDE_DATA: begin
                if ((block_section == 4'b1111) && busy && done) begin
                    if (current_block + 1 < num_blocks) begin
                        next_state = READY;
                    end else begin
                        next_state = IDLE;
                    end
                end 
            end
        endcase
    end

endmodule