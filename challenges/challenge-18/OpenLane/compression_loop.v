module compression_loop (
	clk,
	rst_n,
	start,
	num_blocks,
	word_data,
	word_valid,
	enable,
	word_address,
	req_word,
	blockCount,
	hash_out,
	hash_valid,
	busy
);
	reg _sv2v_0;
	input wire clk;
	input wire rst_n;
	input wire start;
	input wire [7:0] num_blocks;
	input wire [31:0] word_data;
	input wire word_valid;
	input wire enable;
	output reg [5:0] word_address;
	output reg req_word;
	output wire [7:0] blockCount;
	output reg [255:0] hash_out;
	output reg hash_valid;
	output reg busy;
	reg [3:0] state;
	reg [3:0] next_state;
	reg [5:0] kSel;
	wire [31:0] kBus;
	k_rom k(
		.kSel(kSel),
		.kBus(kBus)
	);
	reg [5:0] write_addr;
	reg [31:0] write_data;
	reg [5:0] read_addr;
	wire [31:0] read_data;
	reg enable_write;
	w_ram w(
		.clk(clk),
		.we(enable_write),
		.waddr(write_addr),
		.wdata((state == 4'd1 ? word_data : write_data)),
		.raddr(read_addr),
		.rdata(read_data)
	);
	reg [31:0] a;
	reg [31:0] b;
	reg [31:0] c;
	reg [31:0] d;
	reg [31:0] e;
	reg [31:0] f;
	reg [31:0] g;
	reg [31:0] h;
	reg [31:0] h0;
	reg [31:0] h1;
	reg [31:0] h2;
	reg [31:0] h3;
	reg [31:0] h4;
	reg [31:0] h5;
	reg [31:0] h6;
	reg [31:0] h7;
	reg [7:0] current_block;
	reg [6:0] schedule_counter;
	reg [6:0] round_counter;
	reg [2:0] block_section;
	reg [2:0] extend_phase;
	reg [31:0] temp1;
	reg [31:0] temp2;
	reg [31:0] extend_W [0:3];
	reg [31:0] compress_W;
	function [31:0] ch;
		input reg [31:0] x;
		input reg [31:0] y;
		input reg [31:0] z;
		ch = (x & y) ^ (~x & z);
	endfunction
	function [31:0] maj;
		input reg [31:0] x;
		input reg [31:0] y;
		input reg [31:0] z;
		maj = ((x & y) ^ (x & z)) ^ (y & z);
	endfunction
	function [31:0] sigma0;
		input reg [31:0] x;
		sigma0 = ({x[1:0], x[31:2]} ^ {x[12:0], x[31:13]}) ^ {x[21:0], x[31:22]};
	endfunction
	function [31:0] sigma1;
		input reg [31:0] x;
		sigma1 = ({x[5:0], x[31:6]} ^ {x[10:0], x[31:11]}) ^ {x[24:0], x[31:25]};
	endfunction
	function [31:0] sigma_0;
		input reg [31:0] x;
		sigma_0 = ({x[6:0], x[31:7]} ^ {x[17:0], x[31:18]}) ^ (x >> 3);
	endfunction
	function [31:0] sigma_1;
		input reg [31:0] x;
		sigma_1 = ({x[16:0], x[31:17]} ^ {x[18:0], x[31:19]}) ^ (x >> 10);
	endfunction
	always @(posedge clk or negedge rst_n)
		if (!rst_n) begin
			state <= 4'd0;
			busy <= 1'b0;
			hash_valid <= 1'b0;
			current_block <= 1'sb0;
			schedule_counter <= 1'sb0;
			round_counter <= 1'sb0;
			req_word <= 1'b0;
			block_section <= 1'sb0;
			kSel <= 1'sb0;
			extend_phase <= 1'sb0;
			h0 <= 32'h6a09e667;
			h1 <= 32'hbb67ae85;
			h2 <= 32'h3c6ef372;
			h3 <= 32'ha54ff53a;
			h4 <= 32'h510e527f;
			h5 <= 32'h9b05688c;
			h6 <= 32'h1f83d9ab;
			h7 <= 32'h5be0cd19;
		end
		else begin
			state <= next_state;
			case (state)
				4'd0:
					if (start) begin
						busy <= 1'b1;
						hash_valid <= 1'b0;
						current_block <= 1'sb0;
					end
				4'd1:
					if (schedule_counter < 16) begin
						req_word <= 1'b1;
						if (word_valid)
							schedule_counter <= schedule_counter + 1;
					end
					else
						req_word <= 1'b0;
				4'd2: begin
					extend_phase <= extend_phase + 1;
					case (extend_phase)
						0: extend_W[0] <= read_data;
						1: extend_W[1] <= read_data;
						2: extend_W[2] <= read_data;
						3: extend_W[3] <= read_data;
						4: begin
							schedule_counter <= schedule_counter + 1;
							extend_phase <= 1'sb0;
						end
					endcase
				end
				4'd3:
					if (round_counter == 0) begin
						a <= h0;
						b <= h1;
						c <= h2;
						d <= h3;
						e <= h4;
						f <= h5;
						g <= h6;
						h <= h7;
						round_counter <= round_counter + 1;
					end
					else if (round_counter >= 65)
						busy <= 1'b0;
					else begin
						if (round_counter <= 64) begin
							h <= g;
							g <= f;
							f <= e;
							e <= d + temp1;
							d <= c;
							c <= b;
							b <= a;
							a <= temp1 + temp2;
							kSel <= kSel + 1;
						end
						round_counter <= round_counter + 1;
					end
				4'd4: begin
					h0 <= h0 + a;
					h1 <= h1 + b;
					h2 <= h2 + c;
					h3 <= h3 + d;
					h4 <= h4 + e;
					h5 <= h5 + f;
					h6 <= h6 + g;
					h7 <= h7 + h;
					schedule_counter <= 1'sb0;
					round_counter <= 1'sb0;
					kSel <= 1'sb0;
					current_block <= current_block + 1;
					busy <= 1'b1;
					extend_phase <= 1'sb0;
				end
				4'd5: begin
					hash_out <= {h0, h1, h2, h3, h4, h5, h6, h7};
					hash_valid <= 1'b1;
					busy <= 1'b0;
				end
			endcase
		end
	assign blockCount = current_block;
	always @(*) begin
		if (_sv2v_0)
			;
		temp1 = (((h + sigma1(e)) + ch(e, f, g)) + kBus) + compress_W;
		temp2 = sigma0(a) + maj(a, b, c);
	end
	always @(*) begin
		if (_sv2v_0)
			;
		enable_write = 1'b0;
		write_data = 'bz;
		write_addr = 'bz;
		read_addr = 'bz;
		word_address = 'bz;
		if (state == 4'd1) begin
			word_address = (current_block * 16) + schedule_counter;
			write_addr = schedule_counter;
			if (word_valid)
				enable_write = 1'b1;
		end
		else if (state == 4'd2)
			case (extend_phase)
				0: read_addr = schedule_counter - 2;
				1: read_addr = schedule_counter - 7;
				2: read_addr = schedule_counter - 15;
				3: read_addr = schedule_counter - 16;
				4: begin
					enable_write = 1'b1;
					write_data = ((sigma_1(extend_W[0]) + extend_W[1]) + sigma_0(extend_W[2])) + extend_W[3];
					write_addr = schedule_counter;
				end
			endcase
		else if (state == 4'd3) begin
			read_addr = round_counter - 1;
			compress_W = read_data;
		end
	end
	always @(*) begin
		if (_sv2v_0)
			;
		next_state = state;
		case (state)
			4'd0:
				if (start && enable)
					next_state = 4'd1;
			4'd1:
				if (schedule_counter == 16)
					next_state = 4'd2;
			4'd2:
				if (schedule_counter == 64)
					next_state = 4'd3;
			4'd3:
				if (round_counter == 65)
					next_state = 4'd4;
			4'd4:
				if ((current_block + 1) >= num_blocks)
					next_state = 4'd5;
				else
					next_state = 4'd1;
			4'd5: next_state = 4'd0;
		endcase
	end
	initial _sv2v_0 = 0;
endmodule
