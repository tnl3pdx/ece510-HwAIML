// Compression Loop Module
module compression_loop_parity (
    // General Interface
    input  logic        clk,            // Clock signal
    input  logic        rst_n,          // Active low reset   
    input  logic        enable,         // Enable signal for compression loop

    // Message Controller Interface
    input  logic        start,          // Start signal from message controller
    input  logic [31:0] word_data,      // Data from message controller
    input  logic        word_valid,     // Indicates if word from message controller is valid
    
    output logic        busy,            // Signal to indicate compression loop is busy
    output logic [3:0]  word_address,   // Address for word access
    output logic        req_word,       // Request signal for word data
    output logic        load_done,      // Indicates loading is done

    // Hash Output Interface
    input  logic [255:0]    prev_hash,
    input  logic            hash_ack,       // Acknowledge signal for hash output
    output logic [255:0]    hash_out,      // Final hash output
    output logic            hash_valid     // Indicates hash is valid
    
);

    // States
    typedef enum logic [3:0] {
        IDLE,
        LOAD_SCHEDULE,
        EXTEND_SCHEDULE,
        COMPRESS,
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
    
    // Message schedule memory (W) (Even)
    logic [4:0] write_addr_e;     // Write address for W schedule
    logic [31:0] write_data_e;     // Data to write to memory buffer
    logic [4:0] read_addr1_e;      // Read address for memory buffer
    logic [31:0] read_data1_e;     // Read data from memory buffer
    logic [4:0] read_addr2_e;      // Read address for memory buffer
    logic [31:0] read_data2_e;     // Read data from memory buffer
    logic enable_write_e;         // Enable write signal for memory buffer

    w_ram_half w_e (
        .clk(clk),
        .we(enable_write_e),
        .waddr(write_addr_e),
        .wdata((state == LOAD_SCHEDULE) ? word_data : write_data_e),
        .raddr1(read_addr1_e),
        .rdata1(read_data1_e),
        .raddr2(read_addr2_e),
        .rdata2(read_data2_e)
    );

    logic [4:0] write_addr_o;     // Write address for W schedule
    logic [31:0] write_data_o;     // Data to write to memory buffer
    logic [4:0] read_addr1_o;      // Read address for memory buffer
    logic [31:0] read_data1_o;     // Read data from memory buffer
    logic [4:0] read_addr2_o;      // Read address for memory buffer
    logic [31:0] read_data2_o;     // Read data from memory buffer
    logic enable_write_o;         // Enable write signal for memory buffer

    w_ram_half w_o (
        .clk(clk),
        .we(enable_write_o),
        .waddr(write_addr_o),
        .wdata((state == LOAD_SCHEDULE) ? word_data : write_data_o),
        .raddr1(read_addr1_o),
        .rdata1(read_data1_o),
        .raddr2(read_addr2_o),
        .rdata2(read_data2_o)
    );

    // Working variables and hash values
    logic [31:0] a, b, c, d, e, f, g, h;
    logic [31:0] h0, h1, h2, h3, h4, h5, h6, h7; // Initial hash values
    
    // Counters and control signals
    logic [6:0]  schedule_counter;
    logic [6:0]  round_counter;
    logic [2:0]  extend_phase;

    // Temporary variables for compression
    logic [31:0] temp1, temp2;
    logic [31:0] extend_W [0:3];    // Temporary storage for W schedule extension
    logic hash_saved; // Flag to indicate if hash is saved
    
    // Helper functions (implemented as functions to keep the code clean)
    function automatic logic [31:0] ch(logic [31:0] x, logic [31:0] y, logic [31:0] z);
        logic [31:0] result;
        result = (x & y) ^ (~x & z);
        return result;
    endfunction
    
    function automatic logic [31:0] maj(logic [31:0] x, logic [31:0] y, logic [31:0] z);
        logic [31:0] result;
        result = (x & y) ^ (x & z) ^ (y & z);
        return result;
    endfunction
    
    function automatic logic [31:0] sigma0(logic [31:0] x);
        logic [31:0] result;
        result = {x[1:0], x[31:2]} ^ {x[12:0], x[31:13]} ^ {x[21:0], x[31:22]};
        return result;
    endfunction
    
    function automatic logic [31:0] sigma1(logic [31:0] x);
        logic [31:0] result;
        result = {x[5:0], x[31:6]} ^ {x[10:0], x[31:11]} ^ {x[24:0], x[31:25]};
        return result;
    endfunction
    
    function automatic logic [31:0] sigma_0(logic [31:0] x);
        logic [31:0] result;
        result = {x[6:0], x[31:7]} ^ {x[17:0], x[31:18]} ^ (x >> 3);
        return result;
    endfunction
    
    function automatic logic [31:0] sigma_1(logic [31:0] x);
        logic [31:0] result;
        result = {x[16:0], x[31:17]} ^ {x[18:0], x[31:19]} ^ (x >> 10);
        return result;
    endfunction

    // State machine
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            busy <= 1'b0;
            hash_valid <= 1'b0;
            schedule_counter <= 7'b0;
            round_counter <= 7'b0;
            //req_word <= 1'b0;
            kSel <= 6'b0;
            extend_phase <= 3'b0;
            hash_out <= 256'b0; 
            hash_saved <= 1'b0;
            h0 <= 32'b0;
            h1 <= 32'b0;
            h2 <= 32'b0;
            h3 <= 32'b0;
            h4 <= 32'b0;
            h5 <= 32'b0;
            h6 <= 32'b0;
            h7 <= 32'b0;
            a <= 32'b0;
            b <= 32'b0;
            c <= 32'b0;
            d <= 32'b0;
            e <= 32'b0;
            f <= 32'b0;
            g <= 32'b0;
            h <= 32'b0;
        end else begin
            state <= next_state;
            
            case (state)
                IDLE: begin
                    if (start) begin
                        busy <= 1'b1;
                        hash_valid <= 1'b0;
                        schedule_counter <= 7'b0;
                        round_counter <= 7'b0;
                        //req_word <= 1'b0;
                        kSel <= 6'b0;
                        extend_phase <= 3'b0;
                        hash_out <= 256'b0;
                        hash_saved <= 1'b0; 
                    end
                end
                
                LOAD_SCHEDULE: begin
                    if (schedule_counter < 16) begin    
                        //req_word <= 1'b1;
                        if (word_valid) begin
                            // Only increment counter when valid data arrives
                            schedule_counter <= schedule_counter + 1;
                        end
                    end 
                end
                
                EXTEND_SCHEDULE: begin
                    extend_phase <= extend_phase + 1;
                    case (extend_phase)
                        0: begin
                            if (schedule_counter[0] == 1'b0) begin
                                extend_W[0] <= read_data1_e;
                                extend_W[1] <= read_data1_o;
                                extend_W[2] <= read_data2_o;
                                extend_W[3] <= read_data2_e;
                            end else begin
                                extend_W[0] <= read_data1_o;
                                extend_W[1] <= read_data1_e;
                                extend_W[2] <= read_data2_e;
                                extend_W[3] <= read_data2_o;
                            end 
                        end
                        1: begin
                            schedule_counter <= schedule_counter + 1;
                            extend_phase <= 3'b0;
                        end
                    endcase
                end
                
                COMPRESS: begin
                    if (hash_ack == 1'b1 && hash_saved == 1'b0) begin
                        h0 <= prev_hash[255:224];
                        h1 <= prev_hash[223:192];
                        h2 <= prev_hash[191:160];
                        h3 <= prev_hash[159:128];
                        h4 <= prev_hash[127:96];
                        h5 <= prev_hash[95:64];
                        h6 <= prev_hash[63:32];
                        h7 <= prev_hash[31:0];

                        hash_saved <= 1'b1;

                    end else if (hash_saved == 1'b1) begin
                        if (round_counter == 0) begin
                            // Initialize hash values
                            a <= h0;
                            b <= h1;
                            c <= h2;
                            d <= h3;
                            e <= h4;
                            f <= h5;
                            g <= h6;
                            h <= h7;

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
                end
                
                FINALIZE: begin
                    // Combine hash values for final output
                    hash_out <= {h0+a, h1+b, h2+c, h3+d, h4+e, h5+f, h6+g, h7+h};
                    hash_valid <= 1'b1;
                    busy <= 1'b0;
                end
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end
    assign load_done = (state == LOAD_SCHEDULE && schedule_counter >= 16) ? 1'b1 : 1'b0;
    assign req_word = (state == LOAD_SCHEDULE && schedule_counter < 16) ? 1'b1 : 1'b0;

    // Combinational logic for hash calculation
    always_comb begin
        temp1 = 32'bz;
        temp2 = 32'bz;
        // Perform calulation
        if (state == COMPRESS) begin
            if (round_counter[0] == 1'b1) begin
                temp1 = h + sigma1(e) + ch(e, f, g) + kBus + read_data1_e;
                temp2 = sigma0(a) + maj(a, b, c);
            end else begin
                temp1 = h + sigma1(e) + ch(e, f, g) + kBus + read_data1_o;
                temp2 = sigma0(a) + maj(a, b, c);
            end
        end
    end

    // Combinational logic for memory access
    always_comb begin
        // Mem A
        enable_write_e = 1'b0;
        write_data_e = 32'bz;
        write_addr_e = 5'bz;
        read_addr1_e = 5'bz;
        read_addr2_e = 5'bz;

        // Mem B
        enable_write_o = 1'b0;
        write_data_o = 32'bz;
        write_addr_o = 5'bz;
        read_addr1_o = 5'bz;
        read_addr2_o = 5'bz;

        word_address = 4'bz;
        if (state == LOAD_SCHEDULE) begin
            word_address = schedule_counter[3:0];   // schedule_counter[4:0] for first 16 words

            // Check paritiy of last bit of schedule_counter to determine which memory to write to
            if (word_valid) begin
                if (schedule_counter[0] == 1'b0) begin
                    enable_write_e = 1'b1;
                    write_data_e = word_data;
                    write_addr_e = {2'b00, schedule_counter[3:1]};
                end else begin
                    enable_write_o = 1'b1;
                    write_data_o = word_data;
                    write_addr_o = {2'b00, schedule_counter[3:1]};
                end
            end
        end else if (state == EXTEND_SCHEDULE) begin
            case (extend_phase)
                0: begin
                    if (schedule_counter[0] == 1'b0) begin
                        read_addr1_e = schedule_counter[5:1]-1; 
                        read_addr1_o = schedule_counter[5:1]-4;
                        read_addr2_o = schedule_counter[5:1]-8; 
                        read_addr2_e = schedule_counter[5:1]-8;  
                    end else begin
                        read_addr1_o = schedule_counter[5:1]-1; 
                        read_addr1_e = schedule_counter[5:1]-3;
                        read_addr2_e = schedule_counter[5:1]-7; 
                        read_addr2_o = schedule_counter[5:1]-8;  
                    end
                end
                1: begin
                    // Determine which memory to write to based on parity of schedule_counter
                    if (schedule_counter[0] == 1'b0) begin
                        enable_write_e = 1'b1;
                        write_data_e = sigma_1(extend_W[0]) + extend_W[1] + sigma_0(extend_W[2]) + extend_W[3];
                        write_addr_e = schedule_counter[5:1];
                    end else begin
                        enable_write_o = 1'b1;
                        write_data_o = sigma_1(extend_W[0]) + extend_W[1] + sigma_0(extend_W[2]) + extend_W[3];
                        write_addr_o = schedule_counter[5:1];
                    end

                end
                default: begin
                    read_addr1_e = 5'bz;
                    read_addr1_o = 5'bz;
                    read_addr2_e = 5'bz;
                    read_addr2_o = 5'bz;
                end
            endcase
        end else if (state == COMPRESS) begin
            if (round_counter[0] == 1'b1) begin
                read_addr1_e = round_counter[5:1];
            end else begin
                read_addr1_o = round_counter[5:1] - 1;
            end
        end
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
                if (round_counter == 65) next_state = FINALIZE; // 64 rounds + initialization
            end
            
            FINALIZE: begin
                next_state = IDLE;
            end

            default: begin
                next_state = IDLE; // Default case to handle unexpected states
            end
        endcase
    end

endmodule