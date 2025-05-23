module k_rom (
	kSel,
	kBus
);
	reg _sv2v_0;
	input wire [5:0] kSel;
	output reg [31:0] kBus;
	always @(*) begin
		if (_sv2v_0)
			;
		case (kSel)
			0: kBus = 32'h428a2f98;
			1: kBus = 32'h71374491;
			2: kBus = 32'hb5c0fbcf;
			3: kBus = 32'he9b5dba5;
			4: kBus = 32'h3956c25b;
			5: kBus = 32'h59f111f1;
			6: kBus = 32'h923f82a4;
			7: kBus = 32'hab1c5ed5;
			8: kBus = 32'hd807aa98;
			9: kBus = 32'h12835b01;
			10: kBus = 32'h243185be;
			11: kBus = 32'h550c7dc3;
			12: kBus = 32'h72be5d74;
			13: kBus = 32'h80deb1fe;
			14: kBus = 32'h9bdc06a7;
			15: kBus = 32'hc19bf174;
			16: kBus = 32'he49b69c1;
			17: kBus = 32'hefbe4786;
			18: kBus = 32'h0fc19dc6;
			19: kBus = 32'h240ca1cc;
			20: kBus = 32'h2de92c6f;
			21: kBus = 32'h4a7484aa;
			22: kBus = 32'h5cb0a9dc;
			23: kBus = 32'h76f988da;
			24: kBus = 32'h983e5152;
			25: kBus = 32'ha831c66d;
			26: kBus = 32'hb00327c8;
			27: kBus = 32'hbf597fc7;
			28: kBus = 32'hc6e00bf3;
			29: kBus = 32'hd5a79147;
			30: kBus = 32'h06ca6351;
			31: kBus = 32'h14292967;
			32: kBus = 32'h27b70a85;
			33: kBus = 32'h2e1b2138;
			34: kBus = 32'h4d2c6dfc;
			35: kBus = 32'h53380d13;
			36: kBus = 32'h650a7354;
			37: kBus = 32'h766a0abb;
			38: kBus = 32'h81c2c92e;
			39: kBus = 32'h92722c85;
			40: kBus = 32'ha2bfe8a1;
			41: kBus = 32'ha81a664b;
			42: kBus = 32'hc24b8b70;
			43: kBus = 32'hc76c51a3;
			44: kBus = 32'hd192e819;
			45: kBus = 32'hd6990624;
			46: kBus = 32'hf40e3585;
			47: kBus = 32'h106aa070;
			48: kBus = 32'h19a4c116;
			49: kBus = 32'h1e376c08;
			50: kBus = 32'h2748774c;
			51: kBus = 32'h34b0bcb5;
			52: kBus = 32'h391c0cb3;
			53: kBus = 32'h4ed8aa4a;
			54: kBus = 32'h5b9cca4f;
			55: kBus = 32'h682e6ff3;
			56: kBus = 32'h748f82ee;
			57: kBus = 32'h78a5636f;
			58: kBus = 32'h84c87814;
			59: kBus = 32'h8cc70208;
			60: kBus = 32'h90befffa;
			61: kBus = 32'ha4506ceb;
			62: kBus = 32'hbef9a3f7;
			63: kBus = 32'hc67178f2;
			default: kBus <= 32'h00000000;
		endcase
	end
	initial _sv2v_0 = 0;
endmodule
