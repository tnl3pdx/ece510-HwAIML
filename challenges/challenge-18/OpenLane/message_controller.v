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
	output reg [31:0] word_data;
	output reg word_valid;
	output reg [7:0] num_blocks;
	output reg ready;
	output reg done;
	reg [31:0] state;
	reg [31:0] next_state;
	localparam MAX_MESSAGE_BYTES = 1024;
	reg [12:0] bit_count;
	reg [12:0] temp_msgLen;
	reg [9:0] byte_count;
	reg padding_phase;
	reg [2:0] length_phase;
	reg [3:0] block_section;
	reg [7:0] write_data;
	reg [7:0] read_addr;
	wire [31:0] read_data;
	reg enable_write;
	msg_ram memory_buffer(
		.clk(clk),
		.we(enable_write),
		.waddr(byte_count),
		.wdata(write_data),
		.raddr(read_addr),
		.rdata(read_data)
	);
	always @(posedge clk or negedge rst_n)
		if (!rst_n) begin
			state <= 32'd0;
			bit_count <= 1'sb0;
			temp_msgLen <= 1'sb0;
			byte_count <= 1'sb0;
			padding_phase <= 1'sb0;
			length_phase <= 1'sb0;
			num_blocks <= 1'sb0;
			ready <= 1'b0;
			done <= 1'b0;
			block_section <= 1'sb0;
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
						bit_count <= bit_count + 8;
						byte_count <= byte_count + 1;
					end
				32'd2:
					if (padding_phase == 0) begin
						bit_count <= bit_count + 8;
						byte_count <= byte_count + 1;
						padding_phase <= 1;
						temp_msgLen <= bit_count;
					end
					else if ((byte_count % 64) != 56) begin
						bit_count <= bit_count + 8;
						byte_count <= byte_count + 1;
					end
				32'd3: begin
					bit_count <= bit_count + 8;
					byte_count <= byte_count + 1;
					length_phase <= length_phase + 1;
				end
				32'd4: num_blocks <= (byte_count + 63) / 64;
				32'd5: begin
					done <= 1'b1;
					padding_phase <= 1'sb0;
				end
				32'd6:
					if (req_word && word_valid)
						block_section <= block_section + 1;
			endcase
		end
	always @(*) begin
		if (_sv2v_0)
			;
		enable_write = 1'b0;
		read_addr = 1'sbz;
		write_data = 1'sbz;
		word_data = 32'h00000000;
		word_valid = 1'b0;
		if (state == 32'd1) begin
			enable_write = 1'b1;
			write_data = data_in;
		end
		else if (state == 32'd2) begin
			enable_write = 1'b1;
			if (padding_phase == 0)
				write_data = 8'h80;
			else
				write_data = 8'h00;
		end
		else if (state == 32'd3) begin
			enable_write = 1'b1;
			if (length_phase == 6)
				write_data = {5'b00000, temp_msgLen[10:8]};
			else if (length_phase == 7)
				write_data = temp_msgLen[7:0];
			else
				write_data = 8'h00;
		end
		else if (state == 32'd6) begin
			read_addr = {word_address, 2'b00};
			word_data = read_data;
			word_valid = req_word;
		end
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
