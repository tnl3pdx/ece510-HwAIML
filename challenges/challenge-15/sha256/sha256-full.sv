// SHA-256 Full Implementation in SystemVerilog
// Main top module with message buffer and submodules

module sha256_top (
    input  logic        clk,
    input  logic        rst_n,          // Active low reset
    input  logic [7:0]  data_in,        // Input data stream (8 bits)
    input  logic        data_valid,     // Indicates valid data for data_in
    input  logic        end_of_file,    // Indicates end of input data
    output logic        ready,          // Indicates if 
    output logic [255:0] hash_out,
    output logic        hash_valid
);
    
    // Control signals between modules
    logic        compression_busy;  // Indicates if compression is busy
    logic        mc_done;           // Indicates if message controller is done
    logic [7:0]  num_blocks;        // Number of 512-bit blocks
    logic [7:0]  block_index;       // Current block index
    logic [5:0]  word_address;      // Address for word access
    logic [63:0] word_data;         // Data for word access
    logic        req_word;          // Request signal from compression loop
    logic        word_valid;        // Indicates if word from message controller is valid
    logic [255:0] internal_hash;    // Internal hash output from compression loop
    logic        hash_ready;        // Indicates if hash is ready to be outputted
    
    // Message Controller instantiation
    message_controller mc (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_valid(data_valid),
        .end_of_file(end_of_file),
        .busy(compression_busy),
        .word_address(word_address),
        .req_word(req_word),
        .current_block(block_index),
        .word_data(word_data),
        .word_valid(word_valid),
        .num_blocks(num_blocks),
        .ready(ready),
        .done(mc_done)
    );
    
    // Compression loop instantiation
    compression_loop cl (
        .clk(clk),
        .rst_n(rst_n),
        .start(mc_done),
        .num_blocks(num_blocks),
        .word_address(word_address),
        .req_word(req_word),
        .word_data(word_data),
        .word_valid(word_valid),
        .blockCount(block_index),
        .hash_out(internal_hash),
        .hash_valid(hash_ready),
        .busy(compression_busy)
    );
    
    // Output hash when valid
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hash_out <= '0;
            hash_valid <= 1'b0;
        end else if (hash_ready) begin
            hash_out <= internal_hash;
            hash_valid <= 1'b1;
        end else if (hash_valid) begin
            // Keep the hash value but lower the valid signal after one cycle
            hash_valid <= 1'b0;
        end
    end

endmodule

// Message Controller Module
module message_controller (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [7:0]  data_in,
    input  logic        data_valid,
    input  logic        end_of_file,
    input  logic        busy,
    input  logic [5:0]  word_address,   // Address from compression loop to read data
    input  logic        req_word,       // Request signal from compression loop
    input  logic [7:0]  current_block,
    output logic [63:0] word_data,
    output logic        word_valid,
    output logic [7:0]  num_blocks,
    output logic        ready,
    output logic        done
);
    // Parameters
    localparam MAX_MESSAGE_BYTES = 1024;  // Maximum message size (can be adjusted)
    
    // Memory buffer for the message
    logic [7:0] memory_buffer [0:MAX_MESSAGE_BYTES-1];

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
    logic [63:0] bit_count;         // Count of bits in the message
    logic [63:0] temp_msgLen;       // Temporary message length
    logic [31:0] byte_count;        // Count of bytes in the message
    logic [31:0] pad_byte_index;    // Index for padding
    logic [2:0]  padding_phase;     // Track padding progress
    logic [2:0]  length_phase;      // Track length append progress
    logic [3:0]  block_section;     // Track block output section
    
    // State machine
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            bit_count <= '0;
            byte_count <= '0;
            pad_byte_index <= '0;
            padding_phase <= '0;
            length_phase <= '0;
            num_blocks <= '0;
            ready <= 1'b1;
            done <= 1'b0;
            block_section <= '0;
        end else begin
            state <= next_state;
            
            case (state)
                IDLE: begin
                    bit_count <= '0;
                    byte_count <= '0;
                    pad_byte_index <= '0;
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
                        bit_count <= bit_count + 8;
                        byte_count <= byte_count + 1;
                    end
                end
                
                PADDING: begin
                    if (padding_phase == 0) begin
                        // Append '1' bit (0x80)
                        memory_buffer[byte_count] <= 8'h80;
                        bit_count <= bit_count + 8;
                        byte_count <= byte_count + 1;
                        padding_phase <= padding_phase + 1;
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
                        0: memory_buffer[byte_count] <= temp_msgLen[63:56];
                        1: memory_buffer[byte_count] <= temp_msgLen[55:48];
                        2: memory_buffer[byte_count] <= temp_msgLen[47:40];
                        3: memory_buffer[byte_count] <= temp_msgLen[39:32];
                        4: memory_buffer[byte_count] <= temp_msgLen[31:24];
                        5: memory_buffer[byte_count] <= temp_msgLen[23:16];
                        6: memory_buffer[byte_count] <= temp_msgLen[15:8];
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
                    ready <= 1'b0;
                    done <= 1'b1;
                    padding_phase <= '0;
                end
                
                PROVIDE_DATA: begin
                    if (req_word) begin
                        // Convert byte address to word address
                        word_data <= {
                            memory_buffer[{word_address, 2'b00}],
                            memory_buffer[{word_address, 2'b00} + 1],
                            memory_buffer[{word_address, 2'b00} + 2],
                            memory_buffer[{word_address, 2'b00} + 3],
                            memory_buffer[{word_address, 2'b00} + 4],
                            memory_buffer[{word_address, 2'b00} + 5],
                            memory_buffer[{word_address, 2'b00} + 6],
                            memory_buffer[{word_address, 2'b00} + 7]
                        };
                        word_valid <= 1'b1;
                        block_section <= block_section + 1;
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
                if (data_valid) next_state = RECEIVE;
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
                    if (current_block < num_blocks) begin
                        next_state = READY;
                    end else begin
                        next_state = IDLE;
                    end
                end 
            end
        endcase
    end

endmodule

// Compression Loop Module
module compression_loop (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        start,
    input  logic [7:0]  num_blocks,
    output logic [5:0]  word_address,
    output logic        req_word,
    input  logic [63:0] word_data,
    input  logic        word_valid,
    output logic [7:0]  blockCount,
    output logic [255:0] hash_out,      // Final hash output
    output logic        hash_valid,     // Indicates hash is valid
    output logic        busy            // Signal to indicate compression loop is busy
);

    // SHA-256 Constants
    logic [31:0] K [0:63];
    assign K = '{
        32'h428a2f98, 32'h71374491, 32'hb5c0fbcf, 32'he9b5dba5,
        32'h3956c25b, 32'h59f111f1, 32'h923f82a4, 32'hab1c5ed5,
        32'hd807aa98, 32'h12835b01, 32'h243185be, 32'h550c7dc3,
        32'h72be5d74, 32'h80deb1fe, 32'h9bdc06a7, 32'hc19bf174,
        32'he49b69c1, 32'hefbe4786, 32'h0fc19dc6, 32'h240ca1cc,
        32'h2de92c6f, 32'h4a7484aa, 32'h5cb0a9dc, 32'h76f988da,
        32'h983e5152, 32'ha831c66d, 32'hb00327c8, 32'hbf597fc7,
        32'hc6e00bf3, 32'hd5a79147, 32'h06ca6351, 32'h14292967,
        32'h27b70a85, 32'h2e1b2138, 32'h4d2c6dfc, 32'h53380d13,
        32'h650a7354, 32'h766a0abb, 32'h81c2c92e, 32'h92722c85,
        32'ha2bfe8a1, 32'ha81a664b, 32'hc24b8b70, 32'hc76c51a3,
        32'hd192e819, 32'hd6990624, 32'hf40e3585, 32'h106aa070,
        32'h19a4c116, 32'h1e376c08, 32'h2748774c, 32'h34b0bcb5,
        32'h391c0cb3, 32'h4ed8aa4a, 32'h5b9cca4f, 32'h682e6ff3,
        32'h748f82ee, 32'h78a5636f, 32'h84c87814, 32'h8cc70208,
        32'h90befffa, 32'ha4506ceb, 32'hbef9a3f7, 32'hc67178f2
    };

    // States
    typedef enum logic [3:0] {
        IDLE,
        LOAD_SCHEDULE,
        EXTEND_SCHEDULE,
        COMPRESS,
        NEXT_BLOCK,
        FINALIZE
    } state_t;
    
    state_t state, next_state;
    
    // Message schedule memory (W)
    logic [31:0] W [0:63];
    
    // Working variables and hash values
    logic [31:0] a, b, c, d, e, f, g, h;
    logic [31:0] h0, h1, h2, h3, h4, h5, h6, h7;
    
    // Counters and control signals
    logic [7:0]  current_block;
    logic [6:0]  schedule_counter;
    logic [6:0]  round_counter;
    logic [2:0]  block_section;
    
    // Helper functions (implemented as functions to keep the code clean)
    function logic [31:0] ch(logic [31:0] x, logic [31:0] y, logic [31:0] z);
        return (x & y) ^ (~x & z);
    endfunction
    
    function logic [31:0] maj(logic [31:0] x, logic [31:0] y, logic [31:0] z);
        return (x & y) ^ (x & z) ^ (y & z);
    endfunction
    
    function logic [31:0] sigma0(logic [31:0] x);
        return {x[1:0], x[31:2]} ^ {x[12:0], x[31:13]} ^ {x[21:0], x[31:22]};
    endfunction
    
    function logic [31:0] sigma1(logic [31:0] x);
        return {x[5:0], x[31:6]} ^ {x[10:0], x[31:11]} ^ {x[24:0], x[31:25]};
    endfunction
    
    function logic [31:0] sigma_0(logic [31:0] x);
        return {x[6:0], x[31:7]} ^ {x[17:0], x[31:18]} ^ (x >> 3);
    endfunction
    
    function logic [31:0] sigma_1(logic [31:0] x);
        return {x[16:0], x[31:17]} ^ {x[18:0], x[31:19]} ^ (x >> 10);
    endfunction
    
    // State machine
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            busy <= 1'b0;
            hash_valid <= 1'b0;
            current_block <= '0;
            schedule_counter <= '0;
            round_counter <= '0;
            req_word <= 1'b0;
            word_address <= '0;
            block_section <= '0;
            
            // Initialize hash values (first block)
            h0 <= 32'h6a09e667;
            h1 <= 32'hbb67ae85;
            h2 <= 32'h3c6ef372;
            h3 <= 32'ha54ff53a;
            h4 <= 32'h510e527f;
            h5 <= 32'h9b05688c;
            h6 <= 32'h1f83d9ab;
            h7 <= 32'h5be0cd19;
        end else begin
            state <= next_state;
            
            case (state)
                IDLE: begin
                    if (start) begin
                        busy <= 1'b1;
                        hash_valid <= 1'b0;
                        current_block <= '0;
                    end
                end
                
                LOAD_SCHEDULE: begin
                    if (!req_word && !word_valid) begin
                        // Request next dword
                        req_word <= 1'b1;
                        word_address <= current_block * 16 + schedule_counter;
                    end else if (req_word && word_valid) begin
                        // Store received word into two 32-bit words
                        W[schedule_counter+1] <= {
                            word_data[31:0]
                        }; 
                        W[schedule_counter] <= {
                            word_data[63:32]
                        }; 
                        
                        // Convert from memory (little endian) to big endian
                        req_word <= 1'b0;
                        schedule_counter <= schedule_counter + 2;
                    end
                end
                
                EXTEND_SCHEDULE: begin
                    // Extend the first 16 words into 64 words
                    W[schedule_counter] <= sigma_1(W[schedule_counter-2]) +
                                          W[schedule_counter-7] +
                                          sigma_0(W[schedule_counter-15]) +
                                          W[schedule_counter-16];
                    schedule_counter <= schedule_counter + 1;
                end
                
                COMPRESS: begin
                    if (round_counter == 0) begin
                        // Initialize working variables
                        a <= h0; b <= h1; c <= h2; d <= h3;
                        e <= h4; f <= h5; g <= h6; h <= h7;
                        round_counter <= round_counter + 1;
                    end else if (round_counter >= 65) begin
                        busy <= 1'b0;
                    end else begin
                        // Perform compression round
                        logic [31:0] temp1, temp2;
                        temp1 = h + sigma1(e) + ch(e, f, g) + K[round_counter-1] + W[round_counter-1];
                        temp2 = sigma0(a) + maj(a, b, c);
                        
                        if (round_counter <= 64) begin
                            h <= g;
                            g <= f;
                            f <= e;
                            e <= d + temp1;
                            d <= c;
                            c <= b;
                            b <= a;
                            a <= temp1 + temp2;
                        end

                        round_counter <= round_counter + 1;
                    end
                end
                
                NEXT_BLOCK: begin
                    // Update hash values
                    h0 <= h0 + a; h1 <= h1 + b; h2 <= h2 + c; h3 <= h3 + d;
                    h4 <= h4 + e; h5 <= h5 + f; h6 <= h6 + g; h7 <= h7 + h;
                    
                    // Reset counters for next block
                    schedule_counter <= '0;
                    round_counter <= '0;
                    current_block <= current_block + 1;
                end
                
                FINALIZE: begin
                    // Combine hash values for final output
                    hash_out <= {h0, h1, h2, h3, h4, h5, h6, h7};
                    hash_valid <= 1'b1;
                    busy <= 1'b0;
                end
            endcase
        end
    end

    assign blockCount = current_block;
    
    // Next state logic
    always_comb begin
        next_state = state;
        
        case (state)
            IDLE: begin
                if (start) next_state = LOAD_SCHEDULE;
            end
            
            LOAD_SCHEDULE: begin
                if (schedule_counter == 16) next_state = EXTEND_SCHEDULE;
            end
            
            EXTEND_SCHEDULE: begin
                if (schedule_counter == 64) next_state = COMPRESS;
            end
            
            COMPRESS: begin
                if (round_counter == 65) next_state = NEXT_BLOCK; // 64 rounds + initialization
            end
            
            NEXT_BLOCK: begin
                if (current_block + 1 >= num_blocks) 
                    next_state = FINALIZE;
                else
                    next_state = LOAD_SCHEDULE;
            end
            
            FINALIZE: begin
                next_state = IDLE;
            end
        endcase
    end

endmodule