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
	always @(posedge clk)
		if (we)
			mem[waddr] <= wdata;
	assign rdata = {mem[raddr], mem[raddr + 1], mem[raddr + 2], mem[raddr + 3]};
endmodule
