module w_ram_half (
    input  logic        clk,
    input  logic        we,
    input  logic [4:0]  waddr,
    input  logic [31:0] wdata,
    input  logic [4:0]  raddr,
    output logic [31:0] rdata
);

    // Memory array: 64 words of 32 bits each
    logic [31:0] mem [0:31];

    // Read and write operations
    always_ff @(posedge clk) begin
        // Write operation
        if (we) begin
            mem[waddr] <= wdata;
        end
    end

    assign rdata = mem[raddr]; // Output data

endmodule
