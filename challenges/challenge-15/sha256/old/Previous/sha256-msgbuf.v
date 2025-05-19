// Message Buffer Module
module sha256_msgbuf (
    input wire clk,
    input wire rst,
    input wire [7:0] data_in,
    input wire data_valid,
    input wire end_of_file,
    output reg [511:0] block_out,
    output reg block_ready,
    input wire parser_ready
);
    reg [5:0] byte_cnt;
    reg [511:0] buffer;
    reg collecting;
    reg last_block;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            byte_cnt <= 0;
            buffer <= 0;
            block_ready <= 0;
            collecting <= 1;
            last_block <= 0;
        end else if (collecting) begin
            // While data_valid is high, collect data
            // into the buffer until 512 bits (64 bytes) are collected
            // or end_of_file is reached
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
                last_block <= 1;
            end
        end else if (block_ready && parser_ready) begin
            block_ready <= 0;
            buffer <= 0;
            byte_cnt <= 0;
            collecting <= !last_block;
            last_block <= 0;
        end
    end
endmodule