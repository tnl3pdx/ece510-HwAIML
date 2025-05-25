module msg_ram (
	clk,
	we,
	waddr,
	wdata,
	raddr,
	rdata
);
	input wire clk;
	input wire we;
	input wire [9:0] waddr;
	input wire [7:0] wdata;
	input wire [7:0] raddr;
	output wire [31:0] rdata;
	reg [7:0] mem [0:1023];
	wire [9:0] raddr_aligned;
	always @(posedge clk)
		if (we)
			mem[waddr] <= wdata;
	assign raddr_aligned = {raddr[7:0], 2'b00};
	assign rdata = {mem[raddr_aligned], mem[raddr_aligned + 1], mem[raddr_aligned + 2], mem[raddr_aligned + 3]};
endmodule
