// SHA-256 Full Implementation in SystemVerilog
// Main top module with message buffer and submodules

module sha256_reduced (
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
    logic           compression_busy;  // Indicates if compression is busy
    logic           mc_done;           // Indicates if message controller is done
    logic [3:0]     num_blocks;        // Number of 512-bit blocks
    logic [3:0]     block_index;       // Current block index
    logic [7:0]     word_address;      // Address for word access
    logic [31:0]    word_data;         // Data for word access
    logic           req_word;          // Request signal from compression loop
    logic           word_valid;        // Indicates if word from message controller is valid
    logic [255:0]   internal_hash;     // Internal hash output from compression loop
    logic           hash_ready;        // Indicates if hash is ready to be outputted
    logic [2:0]     hash_counter;      // Counter for hash output cycles
    logic           hash_ack;          // Acknowledge signal for hash output
    
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
        .done(mc_done),
        .enable(enable)
    );
    
    // Compression loop instantiation
    compression_loop_parity cl (
        .clk(clk),
        .rst_n(rst_n),
        .start(mc_done),
        .num_blocks(num_blocks),
        .word_address(word_address),
        .req_word(req_word),
        .word_data(word_data),
        .word_valid(word_valid),
        .block_count(block_index),
        .hash_out(internal_hash),
        .hash_valid(hash_ready),
        .hash_ack(hash_ack),
        .busy(compression_busy),
        .enable(enable)
    );
    
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
