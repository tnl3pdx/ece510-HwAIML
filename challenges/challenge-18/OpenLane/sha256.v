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
	wire [31:0] word_data;
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
