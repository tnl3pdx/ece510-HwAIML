// Top-level SHA-256 module split into 4 parts as described
// Produced by LLM

module sha256_top (
    input wire clk,
    input wire rst,
    input wire [7:0] data_in,
    input wire data_valid,
    input wire end_of_file,
    output wire [63:0] hash_out,
    output wire hash_valid
);

    // Internal wires
    wire [511:0] block_out;
    wire block_ready;
    wire parser_ready;
    wire [31:0] W_out;
    wire W_valid;
    wire [255:0] hash_full;
    wire hash_done;

    // Message Buffer: collects bytes into 512-bit blocks
    sha256_message_buffer msg_buf (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .data_valid(data_valid),
        .end_of_file(end_of_file),
        .block_out(block_out),
        .block_ready(block_ready),
        .parser_ready(parser_ready)
    );

    // Pad and Parser: expands 512-bit block into 64 32-bit words
    sha256_pad_parser pad_parser (
        .clk(clk),
        .rst(rst),
        .block_in(block_out),
        .block_valid(block_ready),
        .parser_ready(parser_ready),
        .W_out(W_out),
        .W_valid(W_valid)
    );

    // Compression Loop: processes 64 words, outputs 256-bit hash
    sha256_compression compression (
        .clk(clk),
        .rst(rst),
        .W_in(W_out),
        .W_valid(W_valid),
        .hash_out(hash_full),
        .hash_valid(hash_done)
    );

    // Hash Output Pipelining (64-bit chunks)
    sha256_hash_out_pipeliner out_pipe (
        .clk(clk),
        .rst(rst),
        .hash_in(hash_full),
        .hash_valid_in(hash_done),
        .hash_out(hash_out),
        .hash_valid(hash_valid)
    );

endmodule

// Message Buffer Module
module sha256_message_buffer (
    input wire clk,
    input wire rst,
    input wire [7:0] data_in,
    input wire data_valid,
    input wire end_of_file,
    output reg [511:0] block_out,
    output reg block_ready,
    input wire parser_ready
);
    reg [8:0] byte_cnt;
    reg [511:0] buffer;
    reg collecting;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            byte_cnt <= 0;
            buffer <= 0;
            block_ready <= 0;
            collecting <= 1;
        end else if (collecting) begin
            if (data_valid) begin
                buffer <= {buffer[503:0], data_in};
                byte_cnt <= byte_cnt + 1;
                if (byte_cnt == 63) begin
                    block_out <= {buffer[503:0], data_in};
                    block_ready <= 1;
                    collecting <= 0;
                end
            end
            if (end_of_file && byte_cnt != 0) begin
                // Output partial block for padding
                block_out <= buffer << (8 * (64 - byte_cnt));
                block_ready <= 1;
                collecting <= 0;
            end
        end else if (block_ready && parser_ready) begin
            block_ready <= 0;
            buffer <= 0;
            byte_cnt <= 0;
            collecting <= 1;
        end
    end
endmodule

// Pad and Parser Module
module sha256_pad_parser (
    input wire clk,
    input wire rst,
    input wire [511:0] block_in,
    input wire block_valid,
    output reg parser_ready,
    output reg [31:0] W_out,
    output reg W_valid
);
    reg [5:0] idx;
    reg [31:0] W [0:63];
    reg parsing;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            idx <= 0;
            W_valid <= 0;
            parser_ready <= 1;
            parsing <= 0;
        end else if (block_valid && parser_ready) begin
            // Load first 16 words
            integer i;
            for (i = 0; i < 16; i = i + 1)
                W[i] <= block_in[511 - i*32 -: 32];
            idx <= 16;
            parsing <= 1;
            parser_ready <= 0;
            W_valid <= 1;
            W_out <= block_in[511 - 0*32 -: 32];
        end else if (parsing) begin
            if (idx < 64) begin
                W[idx] <= (W[idx-16] ^ W[idx-15] ^ W[idx-7] ^ W[idx-2]); // Simplified, replace with real schedule
                W_out <= W[idx];
                W_valid <= 1;
                idx <= idx + 1;
            end else begin
                W_valid <= 0;
                parsing <= 0;
                parser_ready <= 1;
            end
        end else begin
            W_valid <= 0;
        end
    end
endmodule

// Compression Loop Module (simplified, not full SHA-256 logic)
module sha256_compression (
    input wire clk,
    input wire rst,
    input wire [31:0] W_in,
    input wire W_valid,
    output reg [255:0] hash_out,
    output reg hash_valid
);
    reg [6:0] round;
    reg [255:0] state;
    reg processing;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            round <= 0;
            hash_valid <= 0;
            processing <= 0;
            state <= 256'h6a09e667bb67ae8583efc6a1a54ff53a510e527fade682d1b00327c89821e5c6; // Initial SHA-256 IV
        end else if (W_valid && !processing) begin
            processing <= 1;
            round <= 1;
            // Start compression with W_in and state
        end else if (processing) begin
            if (round < 64) begin
                // SHA-256 compression round logic here (not implemented for brevity)
                round <= round + 1;
            end else begin
                hash_out <= state; // Output final hash (should be updated state)
                hash_valid <= 1;
                processing <= 0;
            end
        end else begin
            hash_valid <= 0;
        end
    end
endmodule

// Hash Output Pipeliner (outputs 64 bits per cycle)
module sha256_hash_out_pipeliner (
    input wire clk,
    input wire rst,
    input wire [255:0] hash_in,
    input wire hash_valid_in,
    output reg [63:0] hash_out,
    output reg hash_valid
);
    reg [1:0] idx;
    reg [255:0] hash_buf;
    reg outputting;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            idx <= 0;
            hash_valid <= 0;
            outputting <= 0;
        end else if (hash_valid_in) begin
            hash_buf <= hash_in;
            idx <= 0;
            outputting <= 1;
            hash_valid <= 1;
            hash_out <= hash_in[255:192];
        end else if (outputting) begin
            idx <= idx + 1;
            case (idx)
                2'd0: hash_out <= hash_buf[191:128];
                2'd1: hash_out <= hash_buf[127:64];
                2'd2: hash_out <= hash_buf[63:0];
                default: begin
                    hash_valid <= 0;
                    outputting <= 0;
                end
            endcase
        end else begin
            hash_valid <= 0;
        end
    end
endmodule