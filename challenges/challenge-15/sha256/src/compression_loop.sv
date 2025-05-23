// Compression Loop Module
module compression_loop (
    input  logic        clk,            // Clock signal
    input  logic        rst_n,          // Active low reset
    input  logic        start,          // Start signal from message controller
    input  logic [7:0]  num_blocks,     // Number of 512-bit blocks
    input  logic [31:0] word_data,      // Data from message controller
    input  logic        word_valid,     // Indicates if word from message controller is valid
    input  logic        enable,         // Enable signal for compression loop

    output logic [5:0]  word_address,   // Address for word access
    output logic        req_word,       // Request signal for word data
    output logic [7:0]  blockCount,     // Current block index
    output logic [255:0] hash_out,      // Final hash output
    output logic        hash_valid,     // Indicates hash is valid
    output logic        busy            // Signal to indicate compression loop is busy
);

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

    // SHA-256 Constants
    logic [5:0] kSel;
    logic [31:0] kBus;

    // k_rom instance for SHA-256 constants
    k_rom k (
        .kSel(kSel),
        .kBus(kBus)
    );
    
    // Message schedule memory (W)
    logic [5:0] write_addr;     // Write address for W schedule
    logic [31:0] write_data;     // Data to write to memory buffer
    logic [5:0] read_addr;      // Read address for memory buffer
    logic [31:0] read_data;     // Read data from memory buffer
    logic enable_write;         // Enable write signal for memory buffer

    w_ram w (
        .clk(clk),
        .we(enable_write),
        .waddr(write_addr),
        .wdata((state == LOAD_SCHEDULE) ? word_data : write_data),
        .raddr(read_addr),
        .rdata(read_data)
    );
    
    // Working variables and hash values
    logic [31:0] a, b, c, d, e, f, g, h;
    logic [31:0] h0, h1, h2, h3, h4, h5, h6, h7;
    
    // Counters and control signals
    logic [7:0]  current_block;
    logic [6:0]  schedule_counter;
    logic [6:0]  round_counter;
    logic [2:0]  extend_phase;

    // Temporary variables for compression
    logic [31:0] temp1, temp2;
    logic [31:0] extend_W [0:3];    // Temporary storage for W schedule extension
    
    // Helper functions (implemented as functions to keep the code clean)
    function logic [31:0] ch(logic [31:0] x, logic [31:0] y, logic [31:0] z);
        return ((x & y) ^ (~x & z));
    endfunction
    
    function logic [31:0] maj(logic [31:0] x, logic [31:0] y, logic [31:0] z);
        return ((x & y) ^ (x & z) ^ (y & z));
    endfunction
    
    function logic [31:0] sigma0(logic [31:0] x);
        return ({x[1:0], x[31:2]} ^ {x[12:0], x[31:13]} ^ {x[21:0], x[31:22]});
    endfunction
    
    function logic [31:0] sigma1(logic [31:0] x);
        return ({x[5:0], x[31:6]} ^ {x[10:0], x[31:11]} ^ {x[24:0], x[31:25]});
    endfunction
    
    function logic [31:0] sigma_0(logic [31:0] x);
        return ({x[6:0], x[31:7]} ^ {x[17:0], x[31:18]} ^ (x >> 3));
    endfunction
    
    function logic [31:0] sigma_1(logic [31:0] x);
        return ({x[16:0], x[31:17]} ^ {x[18:0], x[31:19]} ^ (x >> 10));
    endfunction

    // State machine
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            busy <= 1'b0;
            hash_valid <= 1'b0;
            current_block <= 8'b0;
            schedule_counter <= 7'b0;
            round_counter <= 7'b0;
            req_word <= 1'b0;
            //word_address <= '0;
            kSel <= 6'b0;
            extend_phase <= 3'b0;
            
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
                        current_block <= 8'b0;
                    end
                end
                
                LOAD_SCHEDULE: begin
                    if (schedule_counter < 16) begin
                        req_word <= 1'b1;
                        //word_address <= current_block * 16 + schedule_counter;
                        
                        if (word_valid) begin
                            // Only increment counter when valid data arrives
                            schedule_counter <= schedule_counter + 1;
                        end
                    end else begin
                        req_word <= 1'b0;
                    end
                end
                
                EXTEND_SCHEDULE: begin
                    extend_phase <= extend_phase + 1;
                    case (extend_phase)
                        0: begin
                            extend_W[0] <= read_data;
                        end
                        1: begin 
                            extend_W[1] <= read_data;
                        end 
                        2: begin
                            extend_W[2] <= read_data;
                        end
                        3: begin
                            extend_W[3] <= read_data;
                        end
                        4: begin
                            schedule_counter <= schedule_counter + 1;
                            extend_phase <= 3'b0;
                        end
                    endcase
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
                    schedule_counter <= 7'b0;
                    round_counter <= 7'b0;
                    kSel <= 6'b0;
                    current_block <= current_block + 1;
                    busy <= 1'b1;
                    extend_phase <= 3'b0;
                end
                
                FINALIZE: begin
                    // Combine hash values for final output
                    hash_out <= {h0, h1, h2, h3, h4, h5, h6, h7};
                    hash_valid <= 1'b1;
                    busy <= 1'b0;
                end
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

    assign blockCount = current_block;
    

    // Combinational logic for hash calculation
    always_comb begin
        // Perform calulation
        temp1 = h + sigma1(e) + ch(e, f, g) + kBus + read_data;
        temp2 = sigma0(a) + maj(a, b, c);
    end

    // Combinational logic for memory access
    always_comb begin
        enable_write = 1'b0;
        write_data = 32'bz;
        write_addr = 6'bz;
        read_addr = 6'bz;
        word_address = 6'bz;
        if (state == LOAD_SCHEDULE) begin
            word_address = current_block * 16 + {2'b00, schedule_counter[5:0]};
            write_addr = schedule_counter[5:0];
            if (word_valid) begin
                enable_write = 1'b1;
            end
        end else if (state == EXTEND_SCHEDULE) begin
            case (extend_phase)
                0: begin
                    read_addr = schedule_counter[5:0]-2; 
                end
                1: begin
                    read_addr = schedule_counter[5:0]-7; 
                end
                2: begin
                    read_addr = schedule_counter[5:0]-15; 
                end
                3: begin
                    read_addr = schedule_counter[5:0]-16; 
                end
                4: begin
                    enable_write = 1'b1;
                    write_data = sigma_1(extend_W[0]) + extend_W[1] + sigma_0(extend_W[2]) + extend_W[3];
                    write_addr = schedule_counter[5:0];
                end
                default: begin
                    read_addr = 6'bz;
                end
            endcase
        end else if (state == COMPRESS) begin
            read_addr = round_counter[5:0] - 1;
        end
    end

    // Next state logic
    always_comb begin
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
            default: begin
                next_state = IDLE;
            end
        endcase
    end

endmodule