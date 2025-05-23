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
    
    always_ff @(posedge clk) begin
        if (we) begin
            mem[waddr] <= wdata;
        end
    end

    assign rdata = {mem[raddr], mem[raddr+1], mem[raddr+2], mem[raddr+3]};
endmodule: msg_ram
