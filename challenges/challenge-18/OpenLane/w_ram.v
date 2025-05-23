module w_ram (
	clk,
	we,
	waddr,
	wdata,
	raddr,
	rdata
);
	input wire clk;
	input wire we;
	input wire [5:0] waddr;
	input wire [31:0] wdata;
	input wire [5:0] raddr;
	output wire [31:0] rdata;
	reg [31:0] mem [0:63];
	always @(posedge clk)
		if (we)
			mem[waddr] <= wdata;
	assign rdata = mem[raddr];
endmodule
