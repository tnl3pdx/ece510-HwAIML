// SHA-256 Full Implementation (split into 4 modules)
// Produced by LLM

`timescale 1ns/1ps

module sha256_top (
    input wire clk,
    input wire rst,
    input wire [7:0] data_in,
    input wire data_valid,
    input wire end_of_file,
    output wire [63:0] hash_out,
    output wire hash_valid
);

    wire [511:0] block_out;
    wire block_ready;
    wire parser_ready;
    wire [31:0] W_out;
    wire W_valid;
    wire [255:0] hash_full;
    wire hash_done;

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

    sha256_pad_parser pad_parser (
        .clk(clk),
        .rst(rst),
        .block_in(block_out),
        .block_valid(block_ready),
        .parser_ready(parser_ready),
        .W_out(W_out),
        .W_valid(W_valid)
    );

    sha256_compression compression (
        .clk(clk),
        .rst(rst),
        .W_in(W_out),
        .W_valid(W_valid),
        .hash_out(hash_full),
        .hash_valid(hash_done)
    );

    sha256_hash_out_pipeliner out_pipe (
        .clk(clk),
        .rst(rst),
        .hash_in(hash_full),
        .hash_valid_in(hash_done),
        .hash_out(hash_out),
        .hash_valid(hash_valid)
    );



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

    function [31:0] sigma0(input [31:0] x);
        sigma0 = {x[6:0], x[31:7]} ^ {x[17:0], x[31:18]} ^ (x >> 3);
    endfunction
    function [31:0] sigma1(input [31:0] x);
        sigma1 = {x[16:0], x[31:17]} ^ {x[18:0], x[31:19]} ^ (x >> 10);
    endfunction

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            idx <= 0;
            W_valid <= 0;
            parser_ready <= 1;
            parsing <= 0;
        end else if (block_valid && parser_ready) begin
            integer i;
            for (i = 0; i < 16; i = i + 1)
                W[i] <= block_in[511 - i*32 -: 32];
            idx <= 0;
            parsing <= 1;
            parser_ready <= 0;
        end else if (parsing) begin
            if (idx < 16) begin
                W_out <= W[idx];
                W_valid <= 1;
                idx <= idx + 1;
            end else if (idx < 64) begin
                W[idx] <= sigma1(W[idx-2]) + W[idx-7] + sigma0(W[idx-15]) + W[idx-16];
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

// Compression Loop Module (full SHA-256 logic)
module sha256_compression (
    input wire clk,
    input wire rst,
    input wire [31:0] W_in,
    input wire W_valid,
    output reg [255:0] hash_out,
    output reg hash_valid
);
    // SHA-256 constants
    reg [31:0] K [0:63];
    initial begin
        K[ 0]=32'h428a2f98; K[ 1]=32'h71374491; K[ 2]=32'hb5c0fbcf; K[ 3]=32'he9b5dba5;
        K[ 4]=32'h3956c25b; K[ 5]=32'h59f111f1; K[ 6]=32'h923f82a4; K[ 7]=32'hab1c5ed5;
        K[ 8]=32'hd807aa98; K[ 9]=32'h12835b01; K[10]=32'h243185be; K[11]=32'h550c7dc3;
        K[12]=32'h72be5d74; K[13]=32'h80deb1fe; K[14]=32'h9bdc06a7; K[15]=32'hc19bf174;
        K[16]=32'he49b69c1; K[17]=32'hefbe4786; K[18]=32'h0fc19dc6; K[19]=32'h240ca1cc;
        K[20]=32'h2de92c6f; K[21]=32'h4a7484aa; K[22]=32'h5cb0a9dc; K[23]=32'h76f988da;
        K[24]=32'h983e5152; K[25]=32'ha831c66d; K[26]=32'hb00327c8; K[27]=32'hbf597fc7;
        K[28]=32'hc6e00bf3; K[29]=32'hd5a79147; K[30]=32'h06ca6351; K[31]=32'h14292967;
        K[32]=32'h27b70a85; K[33]=32'h2e1b2138; K[34]=32'h4d2c6dfc; K[35]=32'h53380d13;
        K[36]=32'h650a7354; K[37]=32'h766a0abb; K[38]=32'h81c2c92e; K[39]=32'h92722c85;
        K[40]=32'ha2bfe8a1; K[41]=32'ha81a664b; K[42]=32'hc24b8b70; K[43]=32'hc76c51a3;
        K[44]=32'hd192e819; K[45]=32'hd6990624; K[46]=32'hf40e3585; K[47]=32'h106aa070;
        K[48]=32'h19a4c116; K[49]=32'h1e376c08; K[50]=32'h2748774c; K[51]=32'h34b0bcb5;
        K[52]=32'h391c0cb3; K[53]=32'h4ed8aa4a; K[54]=32'h5b9cca4f; K[55]=32'h682e6ff3;
        K[56]=32'h748f82ee; K[57]=32'h78a5636f; K[58]=32'h84c87814; K[59]=32'h8cc70208;
        K[60]=32'h90befffa; K[61]=32'ha4506ceb; K[62]=32'hbef9a3f7; K[63]=32'hc67178f2;
    end

    reg [31:0] H [0:7];
    reg [31:0] a, b, c, d, e, f, g, h;
    reg [31:0] W [0:63];
    reg [6:0] round;
    reg processing;
    reg [5:0] w_idx;

    // Helper functions
    function [31:0] ROTR(input [31:0] x, input [4:0] n);
        ROTR = (x >> n) | (x << (32-n));
    endfunction

    // Compression functions
    // CHECKED
    function [31:0] Ch(input [31:0] x, input [31:0] y, input [31:0] z);
        Ch = (x & y) ^ (~x & z);
    endfunction

    // CHECKED
    function [31:0] Maj(input [31:0] x, input [31:0] y, input [31:0] z);
        Maj = (x & y) ^ (x & z) ^ (y & z);
    endfunction

    // CHECKED
    function [31:0] Sigma0(input [31:0] x);
        Sigma0 = ROTR(x,2) ^ ROTR(x,13) ^ ROTR(x,22);
    endfunction

    // CHECKED
    function [31:0] Sigma1(input [31:0] x);
        Sigma1 = ROTR(x,6) ^ ROTR(x,11) ^ ROTR(x,25);
    endfunction

    // Message schedule functions

    // CHECKED
    function [31:0] sigma0(input [31:0] x);
        sigma0 = ROTR(x,7) ^ ROTR(x,18) ^ (x >> 3);
    endfunction

    // CHECKED
    function [31:0] sigma1(input [31:0] x);
        sigma1 = ROTR(x,17) ^ ROTR(x,19) ^ (x >> 10);
    endfunction

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            H[0] <= 32'h6a09e667; H[1] <= 32'hbb67ae85; H[2] <= 32'h3c6ef372; H[3] <= 32'ha54ff53a;
            H[4] <= 32'h510e527f; H[5] <= 32'h9b05688c; H[6] <= 32'h1f83d9ab; H[7] <= 32'h5be0cd19;
            round <= 0;
            processing <= 0;
            hash_valid <= 0;
            w_idx <= 0;
        end else if (W_valid && !processing) begin
            W[w_idx] <= W_in;
            w_idx <= w_idx + 1;
            if (w_idx == 63) begin
                // Start compression
                a <= H[0]; b <= H[1]; c <= H[2]; d <= H[3];
                e <= H[4]; f <= H[5]; g <= H[6]; h <= H[7];
                round <= 0;
                processing <= 1;
                w_idx <= 0;
            end
        end else if (processing) begin
            if (round < 64) begin
                reg [31:0] T1, T2;
                T1 = h + Sigma1(e) + Ch(e,f,g) + K[round] + W[round];
                T2 = Sigma0(a) + Maj(a,b,c);
                h <= g;
                g <= f;
                f <= e;
                e <= d + T1;
                d <= c;
                c <= b;
                b <= a;
                a <= T1 + T2;
                round <= round + 1;
            end else begin
                H[0] <= H[0] + a; H[1] <= H[1] + b; H[2] <= H[2] + c; H[3] <= H[3] + d;
                H[4] <= H[4] + e; H[5] <= H[5] + f; H[6] <= H[6] + g; H[7] <= H[7] + h;
                hash_out <= {H[0], H[1], H[2], H[3], H[4], H[5], H[6], H[7]};
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