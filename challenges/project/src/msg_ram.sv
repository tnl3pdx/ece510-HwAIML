module msg_ram (
    input  logic        clk,
    input  logic        we,
    input  logic [9:0]  waddr,
    input  logic [7:0]  wdata,
    input  logic [7:0]  raddr,
    output logic [31:0] rdata
);
    // 8-bit wide memory, 1024 locations
    logic [7:0] mem [0:1023]; 
    logic [9:0] raddr_aligned;
    
    always_ff @(posedge clk) begin
        if (we) begin
            mem[waddr] <= wdata;
        end
    end

    assign raddr_aligned = {raddr[7:0], 2'b00}; // Align to 4-byte boundary
    assign rdata = {mem[raddr_aligned], mem[raddr_aligned+1], mem[raddr_aligned+2], mem[raddr_aligned+3]};

endmodule: msg_ram
