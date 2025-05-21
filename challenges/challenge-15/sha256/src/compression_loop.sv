// Compression Loop Module
module compression_loop (
    input  logic        clk,            // Clock signal
    input  logic        rst_n,          // Active low reset
    input  logic        start,          // Start signal from message controller
    input  logic [7:0]  num_blocks,     // Number of 512-bit blocks
    output logic [5:0]  word_address,   // Address for word access
    output logic        req_word,       // Request signal for word data
    input  logic [63:0] word_data,      // Data from message controller
    input  logic        word_valid,     // Indicates if word from message controller is valid
    input  logic        enable,         // Enable signal for compression loop
    output logic [7:0]  blockCount,     // Current block index
    output logic [255:0] hash_out,      // Final hash output
    output logic        hash_valid,     // Indicates hash is valid
    output logic        busy            // Signal to indicate compression loop is busy
);

    // SHA-256 Constants
    logic [5:0] kSel;
    logic [31:0] kBus;

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

    // Temporary variables for compression
    logic [31:0] temp1, temp2;
    
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

    // Use in compression_loop:
    k_rom k (
        .addr(kSel),
        .data(kBus)
    );

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
            kSel <= '0;
            
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
                        if (round_counter <= 64) begin
                            h <= g;
                            g <= f;
                            f <= e;
                            e <= d + temp1;
                            d <= c;
                            c <= b;
                            b <= a;
                            a <= temp1 + temp2;
                            kSel <= kSel + 1;
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
                    kSel <= '0;
                    current_block <= current_block + 1;
                    busy <= 1'b1;
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
    

    // Combinational logic for hash calculation
    always_comb begin
        // Perform calulation
        temp1 = h + sigma1(e) + ch(e, f, g) + k + W[round_counter-1];
        temp2 = sigma0(a) + maj(a, b, c);
    end

    // Next state logic
    always_comb begin
        next_state = state;
        
        case (state)
            IDLE: begin
                if (start && enable) next_state = LOAD_SCHEDULE;
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