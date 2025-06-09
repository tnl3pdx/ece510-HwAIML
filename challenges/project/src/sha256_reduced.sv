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
    logic [255:0]   internal_hash;     // Internal hash output from compression loop
    logic           hash_ready;        // Indicates if hash is ready to be outputted
    logic [2:0]     hash_counter;      // Counter for hash output cycles
    logic           hash_ack;          // Acknowledge signal for hash output

    logic           mc_done;           // Indicates if message controller is done
    logic           compression_busy;  // Indicates if compression is busy
    
    logic [31:0]    word_data;         // Data for word access
    logic           word_valid;        // Indicates if word from message controller is valid





    logic [7:0]     word_address;      // Address for word access
    logic           req_word;          // Request signal from compression loop
    logic [3:0]     current_block;     // Current block index

    // Parallel control signals

    logic [num_loops-1:0]   cl_start;               // Start signal
    logic [num_loops-1:0]   cl_compression_busy;                // Busy signal  
    logic [3:0]             cl_word_address [num_loops];        // Address signal
    logic                   cl_req_word [num_loops];            // Request signal   
    logic [3:0]             cl_current_block [num_loops];       // Current block index for each loop
    logic                   cl_load_done [num_loops];            // Load done signal for each loop

    logic                   cl_hash_ack [num_loops];          // Acknowledge signal for hash output
    logic [255:0]           cl_internal_hash [num_loops];     // Internal hash output for each loop
    logic                   cl_hash_valid [num_loops];        // Hash valid signal for each loop

    logic          cont;                // Continue signal for message controller
    logic [3:0] cl_block_count;         // Block count for compression loop
    logic [3:0] cl_block_remainder;     // Remaining blocks for compression loop
    logic [num_loops-1:0] cl_select;    // Select signal for compression loop
    
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
                .block_count(cl_current_block[i]),
                .load_done(cl_load_done[i]),

                .hash_ack(cl_hash_ack[i]),
                .hash_out(cl_internal_hash[i]),
                .hash_valid(cl_hash_valid[i])
            );
        end
    endgenerate

    // States
    typedef enum {
        IDLE,
        ITERATE,
        WAIT,
        FINALIZE
    } state_t;

    state_t state;

    task automatic clSequence(input logic [1:0] select);
        cl_start <= 4'b0001 << select; // Activate the selected compression loop
        if (cl_load_done[select]) begin
            cl_select <= {cl_select[num_loops-2:0], cl_select[num_loops-1]}; // Rotate select signal
            cl_block_count <= cl_block_count + 1; // Increment block count
        end else if (cl_hash_valid[select]) begin
            internal_hash <= internal_hash + cl_internal_hash[select]; // Update internal hash
            cl_hash_ack[select] <= 1'b1; // Acknowledge hash output
        end else begin
            cl_hash_ack[select] <= 1'b0;
        end
    endtask

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            cl_block_count <= 4'b0; // Reset block count
            cl_start <= 4'b0; // Reset compression loop start signals
            cont <= 1'b1;
            cl_select <= 4'b1; // Start with first compression loop
            hash_ready <= 1'b0; // Reset hash ready signal
            internal_hash <= 256'h6a09e667bb67ae853c6ef372a54ff53a510e527f9b05688c1f83d9ab5be0cd19; // Initial hash value
        end else begin
            case (state)
                IDLE: begin
                    if (enable && mc_done) begin
                        state <= ITERATE; // Move to iterate state when ready
                        cl_block_remainder <= num_blocks % num_loops; // Initialize block remainder
                    end else begin
                        state <= IDLE; // Stay in idle if not enabled or not done
                    end
                end

                ITERATE: begin
                    if (cl_block_count < num_blocks) begin
                        if (cl_compression_busy == 4'b1111 && cl_load_done[3] == 1'b1) begin
                            cl_select <= 4'b1;
                            cl_start <= 4'b0;
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
                    else if (cl_block_count == num_blocks) begin
                        state <= FINALIZE;
                        cont <= 0;
                    end
                end
                
                FINALIZE: begin
                    hash_ready <= 1'b1; // Indicate hash is ready
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
    assign compression_busy = &cl_compression_busy;

    // Output hash in 32-bit chunks using hash_counter
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hash_counter <= 3'b0;
            hash_ack <= 1'b0;
        end else if (hash_valid) begin
            if (hash_counter < 3'b111) begin
                hash_counter <= hash_counter + 1;
            end else begin
                hash_ack <= 1'b1; // Acknowledge hash output
            end
        end else begin
            hash_counter <= 3'b0; // Reset counter if not valid
            hash_ack <= 1'b0; // Acknowledge hash output
        end   
    end
    assign hash_valid = (hash_counter <= 3'b111 && enable && hash_ready) ? 1'b1 : 1'b0;
    assign hash_out = hash_valid ? internal_hash[255 - 32*hash_counter -: 32] : 32'bz;

endmodule
