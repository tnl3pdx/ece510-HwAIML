module sha256 (
	clk,
	rst_n,
	enable,
	data_in,
	data_valid,
	end_of_file,
	ready,
	hash_out,
	hash_valid
);
	input wire clk;
	input wire rst_n;
	input wire enable;
	input wire [7:0] data_in;
	input wire data_valid;
	input wire end_of_file;
	output wire ready;
	output reg [255:0] hash_out;
	output reg hash_valid;
	wire compression_busy;
	wire mc_done;
	wire [7:0] num_blocks;
	wire [7:0] block_index;
	wire [5:0] word_address;
	wire [63:0] word_data;
	wire req_word;
	wire word_valid;
	wire [255:0] internal_hash;
	wire hash_ready;
	message_controller mc(
		.clk(clk),
		.rst_n(rst_n),
		.data_in(data_in),
		.data_valid(data_valid),
		.end_of_file(end_of_file),
		.busy(compression_busy),
		.word_address(word_address),
		.req_word(req_word),
		.current_block(block_index),
		.word_data(word_data),
		.word_valid(word_valid),
		.num_blocks(num_blocks),
		.ready(ready),
		.done(mc_done),
		.enable(enable)
	);
	compression_loop cl(
		.clk(clk),
		.rst_n(rst_n),
		.start(mc_done),
		.num_blocks(num_blocks),
		.word_address(word_address),
		.req_word(req_word),
		.word_data(word_data),
		.word_valid(word_valid),
		.blockCount(block_index),
		.hash_out(internal_hash),
		.hash_valid(hash_ready),
		.busy(compression_busy),
		.enable(enable)
	);
	always @(posedge clk or negedge rst_n)
		if (!rst_n) begin
			hash_out <= 1'sb0;
			hash_valid <= 1'b0;
		end
		else if (hash_ready) begin
			hash_out <= internal_hash;
			hash_valid <= 1'b1;
		end
		else if (hash_valid)
			hash_valid <= 1'b0;
endmodule
module message_controller (
	clk,
	rst_n,
	data_in,
	data_valid,
	end_of_file,
	busy,
	word_address,
	req_word,
	current_block,
	enable,
	word_data,
	word_valid,
	num_blocks,
	ready,
	done
);
	reg _sv2v_0;
	input wire clk;
	input wire rst_n;
	input wire [7:0] data_in;
	input wire data_valid;
	input wire end_of_file;
	input wire busy;
	input wire [5:0] word_address;
	input wire req_word;
	input wire [7:0] current_block;
	input wire enable;
	output reg [63:0] word_data;
	output reg word_valid;
	output reg [7:0] num_blocks;
	output reg ready;
	output reg done;
	localparam MAX_MESSAGE_BYTES = 1024;
	reg [7:0] memory_buffer [0:1023];
	reg [31:0] state;
	reg [31:0] next_state;
	reg [12:0] bit_count;
	reg [12:0] temp_msgLen;
	reg [9:0] byte_count;
	reg padding_phase;
	reg [2:0] length_phase;
	reg [3:0] block_section;
	always @(posedge clk or negedge rst_n)
		if (!rst_n) begin
			state <= 32'd0;
			bit_count <= 1'sb0;
			byte_count <= 1'sb0;
			padding_phase <= 1'sb0;
			length_phase <= 1'sb0;
			num_blocks <= 1'sb0;
			ready <= 1'b0;
			done <= 1'b0;
			block_section <= 1'sb0;
			temp_msgLen <= 1'sb0;
		end
		else begin
			state <= next_state;
			case (state)
				32'd0: begin
					bit_count <= 1'sb0;
					byte_count <= 1'sb0;
					padding_phase <= 1'sb0;
					length_phase <= 1'sb0;
					num_blocks <= 1'sb0;
					ready <= 1'b1;
					done <= 1'b0;
					block_section <= 1'sb0;
				end
				32'd1:
					if (data_valid) begin
						memory_buffer[byte_count] <= data_in;
						bit_count <= bit_count + 8;
						byte_count <= byte_count + 1;
					end
				32'd2:
					if (padding_phase == 0) begin
						memory_buffer[byte_count] <= 8'h80;
						bit_count <= bit_count + 8;
						byte_count <= byte_count + 1;
						padding_phase <= 1;
						temp_msgLen <= bit_count;
					end
					else if ((byte_count % 64) != 56) begin
						memory_buffer[byte_count] <= 8'h00;
						byte_count <= byte_count + 1;
						bit_count <= bit_count + 8;
					end
				32'd3: begin
					case (length_phase)
						0: memory_buffer[byte_count] <= 1'sb0;
						1: memory_buffer[byte_count] <= 1'sb0;
						2: memory_buffer[byte_count] <= 1'sb0;
						3: memory_buffer[byte_count] <= 1'sb0;
						4: memory_buffer[byte_count] <= 1'sb0;
						5: memory_buffer[byte_count] <= 1'sb0;
						6: memory_buffer[byte_count] <= {5'b00000, temp_msgLen[10:8]};
						7: memory_buffer[byte_count] <= temp_msgLen[7:0];
					endcase
					byte_count <= byte_count + 1;
					bit_count <= bit_count + 8;
					length_phase <= length_phase + 1;
				end
				32'd4: num_blocks <= (byte_count + 63) / 64;
				32'd5: begin
					done <= 1'b1;
					padding_phase <= 1'sb0;
				end
				32'd6:
					if (req_word) begin
						word_data <= {memory_buffer[{word_address, 2'b00}], memory_buffer[{word_address, 2'b00} + 1], memory_buffer[{word_address, 2'b00} + 2], memory_buffer[{word_address, 2'b00} + 3], memory_buffer[{word_address, 2'b00} + 4], memory_buffer[{word_address, 2'b00} + 5], memory_buffer[{word_address, 2'b00} + 6], memory_buffer[{word_address, 2'b00} + 7]};
						word_valid <= 1'b1;
						block_section <= block_section + 1;
					end
					else
						word_valid <= 1'b0;
			endcase
		end
	always @(*) begin
		if (_sv2v_0)
			;
		next_state = state;
		case (state)
			32'd0:
				if (data_valid && enable)
					next_state = 32'd1;
			32'd1:
				if (end_of_file)
					next_state = 32'd2;
			32'd2:
				if ((padding_phase > 0) && ((byte_count % 64) == 56))
					next_state = 32'd3;
			32'd3:
				if (length_phase == 7)
					next_state = 32'd4;
			32'd4: next_state = 32'd5;
			32'd5:
				if (!busy)
					next_state = 32'd6;
			32'd6:
				if (((block_section == 4'b1111) && busy) && done) begin
					if ((current_block + 1) < num_blocks)
						next_state = 32'd5;
					else
						next_state = 32'd0;
				end
		endcase
	end
	initial _sv2v_0 = 0;
endmodule
module compression_loop (
	clk,
	rst_n,
	start,
	num_blocks,
	word_address,
	req_word,
	word_data,
	word_valid,
	enable,
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
	output reg [5:0] word_address;
	output reg req_word;
	input wire [63:0] word_data;
	input wire word_valid;
	input wire enable;
	output wire [7:0] blockCount;
	output reg [255:0] hash_out;
	output reg hash_valid;
	output reg busy;
	reg [2047:0] K = 2048'h428a2f9871374491b5c0fbcfe9b5dba53956c25b59f111f1923f82a4ab1c5ed5d807aa9812835b01243185be550c7dc372be5d7480deb1fe9bdc06a7c19bf174e49b69c1efbe47860fc19dc6240ca1cc2de92c6f4a7484aa5cb0a9dc76f988da983e5152a831c66db00327c8bf597fc7c6e00bf3d5a7914706ca63511429296727b70a852e1b21384d2c6dfc53380d13650a7354766a0abb81c2c92e92722c85a2bfe8a1a81a664bc24b8b70c76c51a3d192e819d6990624f40e3585106aa07019a4c1161e376c082748774c34b0bcb5391c0cb34ed8aa4a5b9cca4f682e6ff3748f82ee78a5636f84c878148cc7020890befffaa4506cebbef9a3f7c67178f2;
	reg [3:0] state;
	reg [3:0] next_state;
	reg [31:0] W [0:63];
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
			word_address <= 1'sb0;
			block_section <= 1'sb0;
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
					if (!req_word && !word_valid) begin
						req_word <= 1'b1;
						word_address <= (current_block * 16) + schedule_counter;
					end
					else if (req_word && word_valid) begin
						W[schedule_counter + 1] <= {word_data[31:0]};
						W[schedule_counter] <= {word_data[63:32]};
						req_word <= 1'b0;
						schedule_counter <= schedule_counter + 2;
					end
				4'd2: begin
					W[schedule_counter] <= ((sigma_1(W[schedule_counter - 2]) + W[schedule_counter - 7]) + sigma_0(W[schedule_counter - 15])) + W[schedule_counter - 16];
					schedule_counter <= schedule_counter + 1;
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
					else begin : sv2v_autoblock_1
						reg [31:0] temp1;
						reg [31:0] temp2;
						temp1 = (((h + sigma1(e)) + ch(e, f, g)) + K[(64 - round_counter) * 32+:32]) + W[round_counter - 1];
						temp2 = sigma0(a) + maj(a, b, c);
						if (round_counter <= 64) begin
							h <= g;
							g <= f;
							f <= e;
							e <= d + temp1;
							d <= c;
							c <= b;
							b <= a;
							a <= temp1 + temp2;
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
					current_block <= current_block + 1;
					busy <= 1'b1;
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
