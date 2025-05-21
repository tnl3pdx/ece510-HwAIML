// Message Controller Module
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
    output logic [63:0] word_data,      // Data to be sent to compression loop
    output logic        word_valid,     // Indicates if word from message controller is valid
    output logic [7:0]  num_blocks,     // Number of 512-bit blocks
    output logic        ready,          // Indicates if SHA-256 is ready to accept data
    output logic        done            // Indicates if message controller is done processing all blocks
);
    // Parameters
    localparam MAX_MESSAGE_BYTES = 1024;  // Maximum message size (can be adjusted)
    
    // Memory buffer for the message
    //logic [7:0] memory_buffer [0:MAX_MESSAGE_BYTES-1];

    logic [7:0] read_addr;         // Read address for memory buffer
    logic [31:0] read_data;        // Read data from memory buffer

    message_ram memory_buffer (
        .clk(clk),
        .we(state == RECEIVE || state == PADDING || state == LENGTH_APPEND),
        .waddr(byte_count),
        .wdata(state == RECEIVE ? data_in : 
            (state == PADDING && padding_phase == 0) ? 8'h80 : 
            (state == PADDING) ? 8'h00 : /* LENGTH_APPEND */ length_byte),
        .raddr(read_addr),
        .rdata(read_data)
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
    
    // Internal registers
    logic [12:0]    bit_count;         // Count of bits in the message
    logic [12:0]    temp_msgLen;       // Temporary message length
    logic [9:0]     byte_count;        // Count of bytes in the message
    logic           padding_phase;     // Track padding progress
    logic [2:0]     length_phase;      // Track length append progress
    logic [3:0]     block_section;     // Track block output section

    // Output control/regs
    logic [31:0]    word_p1;
    logic [31:0]    word_p2;
    logic [1:0]     read_segment;       // Read segment for word data
    
    

    // State machine
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            bit_count <= '0;
            byte_count <= '0;
            padding_phase <= '0;
            length_phase <= '0;
            num_blocks <= '0;
            ready <= 1'b0;
            done <= 1'b0;
            block_section <= '0;
            temp_msgLen <= '0;
        end else begin
            state <= next_state;
            
            case (state)
                IDLE: begin
                    bit_count <= '0;
                    byte_count <= '0;
                    padding_phase <= '0;
                    length_phase <= '0;
                    num_blocks <= '0;
                    ready <= 1'b1;
                    done <= 1'b0;
                    block_section <= '0;
                end
                
                RECEIVE: begin
                    if (data_valid) begin
                        memory_buffer[byte_count] <= data_in;
                        bit_count <= bit_count + 32;
                        byte_count <= byte_count + 4;
                    end
                end
                
                PADDING: begin
                    if (padding_phase == 0) begin
                        // Append '1' bit (0x80)
                        buffer[byte_count] <= 8'h80;
                        //memory_buffer[byte_count] <= 8'h80;
                        bit_count <= bit_count + 8;
                        byte_count <= byte_count + 1;
                        padding_phase <= 1;
                        temp_msgLen <= bit_count;
                    end else begin
                        // Append '0's until 448 bits mod 512
                        if ((byte_count % 64) != 56) begin
                            memory_buffer[byte_count] <= 8'h00;
                            byte_count <= byte_count + 1;
                            bit_count <= bit_count + 8;
                        end
                    end
                end
                
                LENGTH_APPEND: begin
                    // Append message length as 64-bit big endian integer
                    case (length_phase)
                        0: memory_buffer[byte_count] <= '0;
                        1: memory_buffer[byte_count] <= '0;
                        2: memory_buffer[byte_count] <= '0;
                        3: memory_buffer[byte_count] <= '0;
                        4: memory_buffer[byte_count] <= '0;
                        5: memory_buffer[byte_count] <= '0;
                        6: memory_buffer[byte_count] <= {5'b00000, temp_msgLen[10:8]};
                        7: memory_buffer[byte_count] <= temp_msgLen[7:0];
                    endcase
                    
                    byte_count <= byte_count + 1;
                    bit_count <= bit_count + 8;
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
                    if (req_word) begin
                        case (read_segment)
                            0: begin
                                read_addr <= {word_address, 2'b00};
                            end
                            1: begin
                                read_addr <= {word_address, 2'b01};
                                word_p1 <= read_data;
                            end
                            2: begin
                                word_p2 <= read_data;
                            end
                            3: begin
                                word_data <= {word_p1, word_p2};
                                word_valid <= 1'b1;
                                block_section <= block_section + 1;
                                read_segment <= 0;
                            end
                        read_segment <= read_segment + 1;
                    end else begin
                        word_valid <= 1'b0;
                    end
                end
            endcase
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