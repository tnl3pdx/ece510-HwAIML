module tb_sha256_msgbuf;

    reg clk;
    reg rst;
    reg [7:0] data_in;
    reg data_valid;
    reg end_of_file;
    wire [511:0] block_out;
    wire block_ready;
    reg parser_ready;

    sha256_msgbuf uut (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .data_valid(data_valid),
        .end_of_file(end_of_file),
        .block_out(block_out),
        .block_ready(block_ready),
        .parser_ready(parser_ready)
    );

    // Create clock signal
    always begin
        #5 clk = ~clk; // 10 time units period
    end

    initial begin
        $dumpvars(0, tb_sha256_msgbuf);
        // Initialize signals
        clk = 0;
        rst = 1;
        data_in = 8'h00;
        data_valid = 0;
        end_of_file = 0;
        parser_ready = 0;

        // Release reset
        #10 rst = 0;

        // Test case 1: Normal operation
        #10 data_valid = 1; data_in = 8'h61; // 'a'
        #5 end_of_file = 1;
        #20
        $display("Block Out: %h, Block Ready: %b", block_out, block_ready);
        $finish;
    end
endmodule