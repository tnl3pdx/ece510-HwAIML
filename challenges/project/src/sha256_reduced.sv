// SHA-256 Full Implementation in SystemVerilog
// Main top module with message buffer and submodules

module sha256_reduced 
#(
    parameter num_loops = 4 // Number of compression loop iterations
)

(
    input  logic        clk,
    input  logic        rst_n,          // Active low reset
    input  logic        enable,         // Enable signal
    input  logic [7:0]  data_in,        // Input data stream (8 bits)
    input  logic        data_valid,     // Indicates valid data for data_in
    input  logic        end_of_file,    // Indicates end of input data
    output logic        ready,          // Indicates if SHA-256 is ready to accept data
    output logic [31:0] hash_out,      // Final hash output (256 bits)
    output logic        hash_valid      // Indicates hash output is valid
);
    
    // Control signals between modules

    
    logic [3:0]     num_blocks;        // Number of 512-bit blocks
    logic [3:0]     block_count;       // Current block count
    logic [255:0]   internal_hash;     // Internal hash output from compression loop
    logic           hash_ready;        // Indicates if hash is ready to be outputted
    logic [2:0]     hash_counter;      // Counter for hash output cycles

    logic           mc_done;           // Indicates if message controller is done
    logic           compression_busy;  // Indicates if compression is busy
    
    logic [31:0]    word_data;         // Data for word access
    logic           word_valid;        // Indicates if word from message controller is valid

    logic [7:0]     word_address;      // Address for word access
    logic           req_word;          // Request signal from compression loop

    // Parallel control signals

    logic [num_loops-1:0]   cl_start;               // Start signal
    logic [num_loops-1:0]   cl_compression_busy;                // Busy signal  
    logic [3:0][num_loops]             cl_word_address;        // Address signal
    logic                   cl_req_word [num_loops];            // Request signal   
    logic                   cl_load_done [num_loops];            // Load done signal for each loop

    logic [num_loops-1:0]   cl_hash_ack;                        // Acknowledge signal for hash output
    logic [255:0]           cl_internal_hash [num_loops];       // Internal hash output for each loop
    logic [255:0]           cl_hash_out [num_loops];            // Individual hash outputs
    logic [255:0]           cl_output_hash;                     // Output hash from last compression loop
    logic                   cl_hash_valid [num_loops];          // Hash valid signal for each loop

    logic          cont;                // Continue signal for message controller
    logic [3:0] cl_block_count;         // Block count for compression loop
    logic [num_loops-1:0] cl_select;    // Select signal for compression loop
    logic cl_init_hash;                 // Initial hash flag for compression loop
    logic cl_finalize;                // Finalize signal for compression loop
    
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
        .cont(cont),
        .word_data(word_data),
        .word_valid(word_valid),
        .num_blocks(num_blocks),
        .ready(ready),
        .done(mc_done),
        .enable(enable)
    );
    
    genvar i;

    // Compression loop instantiation
    generate
        for (i = 0; i < num_loops; i++) begin : compression_loop
            compression_loop_parity cl (
                .clk(clk),
                .rst_n(rst_n),
                .enable(enable),

                .start(cl_start[i]),
                .word_data(word_data),
                .word_valid(word_valid),

                .busy(cl_compression_busy[i]),
                .word_address(cl_word_address[i]),
                .req_word(cl_req_word[i]),
                .load_done(cl_load_done[i]),

                .prev_hash(cl_internal_hash[i]),
                .hash_ack(cl_hash_ack[i]),
                .hash_out(cl_hash_out[i]),
                .hash_valid(cl_hash_valid[i])
            );
        end
    endgenerate

    // States
    typedef enum {
        IDLE,
        ITERATE,
        SINGLE,
        FINALIZE
    } state_t;

    state_t state;

    task automatic clSequence(input logic [1:0] select);

        if (compression_busy || cl_finalize) begin
            cl_start <= 4'b0; // If busy, do not start any compression loop
        end else begin
            cl_start <= 4'b0001 << select; // Activate the selected compression loop
        end

        // Check if the selected compression loop has completed loading
        if (cl_load_done[select] && cl_block_count != block_count) begin
            cl_select <= {cl_select[num_loops-2:0], cl_select[num_loops-1]}; // Rotate select signal
            cl_block_count <= cl_block_count + 1; // Increment block count 

        // Check if the selected compression loop is done with compression
        end else if (cl_hash_valid[0]) begin
            //cl_select <= {cl_select[num_loops-2:0], cl_select[num_loops-1]}; // Rotate select signal
            cl_init_hash <= 1'b1; // Initialize internal hash if valids
        end 

        if (cl_block_count == block_count && cl_compression_busy == 4'b0) begin
            cl_finalize <= 1'b1; // Set finalize signal when all blocks are processed
            cl_start <= 4'b0;
        end else begin
            cl_finalize <= 1'b0; // Reset finalize signal otherwise
        end

    endtask

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            cl_block_count <= 4'b0; // Reset block count
            cl_start <= 4'b0; // Reset compression loop start signals
            cl_select <= 4'b1; // Start with first compression loop
            hash_ready <= 1'b0; // Reset hash ready signal
            cl_init_hash <= 1'b0; // Initialize internal hash
            cl_finalize <= 1'b0; // Reset finalize signal
            block_count <= 4'b0; // Reset block count
            internal_hash <= 256'h6a09e667bb67ae853c6ef372a54ff53a510e527f9b05688c1f83d9ab5be0cd19; // Initial hash value
        end else begin
            case (state)
                IDLE: begin
                    state <= IDLE;
                    cl_block_count <= 4'b0; // Reset block count
                    cl_start <= 4'b0; // Reset compression loop start signals
                    cl_select <= 4'b1; // Start with first compression loop
                    hash_ready <= 1'b0; // Reset hash ready signal
                    cl_init_hash <= 1'b0; // Initialize internal hash
                    cl_finalize <= 1'b0; // Reset finalize signal
                    block_count <= num_blocks; // Set block count from message controller
                    internal_hash <= 256'h6a09e667bb67ae853c6ef372a54ff53a510e527f9b05688c1f83d9ab5be0cd19; // Initial hash value
                    if (enable && mc_done && block_count != 4'b0) begin
                        state <= ITERATE;                               // Move to iterate state when ready
                    end else if (enable && mc_done && block_count == 4'b0) begin
                        state <= SINGLE; // Move to single state if no blocks to process
                        block_count <= 4'b1; // Set block count to 1 for single block processing
                    end else begin
                        state <= IDLE; // Stay in idle if not enabled or not done
                    end
                end
                ITERATE: begin
                    // Check current block count based on number of blocks
                    if (cl_finalize) begin
                        state <= FINALIZE;
                        case (cl_select)
                            4'b0001: internal_hash <= cl_internal_hash[1]; // Finalize hash
                            4'b0010: internal_hash <= cl_internal_hash[2]; // Finalize hash
                            4'b0100: internal_hash <= cl_internal_hash[3]; // Finalize hash
                            4'b1000: internal_hash <= cl_internal_hash[0]; // Finalize hash
                            default: cl_start <= 4'b0; // No compression loop active
                        endcase
                    end else if (cl_block_count <= block_count) begin
                        // Check if all compression loops are busy, and if the last loop has completed loading
                        if (cl_compression_busy == 4'b1111 && cl_load_done[num_loops-1] == 1'b1 && cl_block_count != block_count) begin
                            // Start back at first compression loop
                            cl_select <= 4'b1;
                            cl_start <= 4'b0;
                            cl_block_count <= cl_block_count + 1; // Increment block count
                        end else begin
                            // Start compression loop based on select signal
                            case (cl_select)
                                4'b0001: clSequence(2'b00); // Start first compression loop
                                4'b0010: clSequence(2'b01);
                                4'b0100: clSequence(2'b10);
                                4'b1000: clSequence(2'b11);
                                default: cl_start <= 4'b0; // No compression loop active
                            endcase

                        end
                    end 
                end

                SINGLE: begin
                    // If one block needs to be processed, start the first compression loop
                    if (cl_finalize) begin
                        state <= FINALIZE;
                        internal_hash <= cl_internal_hash[1]; // Use initial hash for single block
                    end else begin
                        cl_start <= 4'b0001; // Start first compression loop
                        cl_select <= 4'b0001; // Select first compression loop
                        if (cl_load_done[0] && cl_block_count != block_count) begin
                            cl_block_count <= cl_block_count + 1; // Increment block count 
                        end
                        if (cl_block_count == block_count && cl_compression_busy == 4'b0) begin
                            cl_finalize <= 1'b1; // Set finalize signal when all blocks are processed
                            cl_start <= 4'b0;
                        end else begin
                            cl_finalize <= 1'b0; // Reset finalize signal otherwise
                        end
                    end
                end
                
                FINALIZE: begin
                    hash_ready <= 1'b1; // Indicate hash is ready
                    if (hash_counter == 3'b111) begin
                        state <= IDLE; // Reset to idle state after finalizing
                    end 
                end
                
                default: state <= IDLE; // Default case to reset to idle state
            endcase
        end   
    end

    // Connect compression loop control signals
    always_comb begin
        case (cl_select)
            4'b0001: begin
                word_address = {cl_block_count, cl_word_address[0]};
                req_word = cl_req_word[0];
            end
            4'b0010: begin
                word_address = {cl_block_count, cl_word_address[1]};
                req_word = cl_req_word[1];
            end
            4'b0100: begin
                word_address = {cl_block_count, cl_word_address[2]};
                req_word = cl_req_word[2];
            end
            4'b1000: begin
                word_address = {cl_block_count, cl_word_address[3]};
                req_word = cl_req_word[3];
            end
            default: begin
                word_address = 8'bz; // Default case
                req_word = 1'bz; // No request
            end
        endcase
    end

    // Connect the hash chain using assign statements
    always_comb begin
        // First loop uses the initial/current internal hash
        cl_internal_hash[0] = (cl_init_hash) ? cl_output_hash : internal_hash;
        cl_hash_ack[0] = (cl_init_hash) ? cl_hash_valid[num_loops-1] : 1'b1; // Acknowledge hash output for first loop
        
        // Chain the hash outputs for intermediate loops
        for (int j = 1; j < num_loops; j++) begin
            cl_internal_hash[j] = cl_hash_out[j-1];
            cl_hash_ack[j] = cl_hash_valid[j-1];
        end

    end

    // Final output hash comes from the last compression loop
    assign cl_output_hash = cl_hash_out[num_loops-1];

    assign compression_busy = &cl_compression_busy;

    assign cont = ((cl_block_count < block_count) ? 1'b1 : 1'b0); // Continue signal for message controller
    // Output hash in 32-bit chunks using hash_counter
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hash_counter <= 3'b0;
        end else if (hash_valid) begin
            if (hash_counter < 3'b111) begin
                hash_counter <= hash_counter + 1;
            end 
        end else begin
            hash_counter <= 3'b0; // Reset counter if not valid
        end   
    end
    assign hash_valid = (hash_counter <= 3'b111 && enable && hash_ready) ? 1'b1 : 1'b0;
    assign hash_out = hash_valid ? internal_hash[255 - 32*hash_counter -: 32] : 32'bz;

endmodule
