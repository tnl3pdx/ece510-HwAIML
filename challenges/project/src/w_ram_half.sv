module w_ram_half (
    input  logic        clk,
    input  logic        we,
    input  logic [4:0]  waddr,
    input  logic [31:0] wdata,
    input  logic [4:0]  raddr1,
    output logic [31:0] rdata1,
    input  logic [4:0]  raddr2,
    output logic [31:0] rdata2
);

    // Memory array: 32 words of 32 bits each
    logic [31:0] mem [0:31];

    // Read and write operations
    always_ff @(posedge clk) begin
        // Write operation
        if (we) begin
            mem[waddr] <= wdata;
        end
    end

    assign rdata1 = mem[raddr1]; // Output data
    assign rdata2 = mem[raddr2]; // Output data

endmodule
