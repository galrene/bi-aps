module top (	input         clk, reset,
		output [31:0] data_to_mem, address_to_mem,
		output        write_enable);

	wire [31:0] pc, instruction, data_from_mem;

	inst_mem  imem(pc[8:2], instruction);
	data_mem  dmem(clk, write_enable, address_to_mem, data_to_mem, data_from_mem);
	processor CPU(clk, reset, pc, instruction, write_enable, address_to_mem, data_to_mem, data_from_mem);
endmodule

//-------------------------------------------------------------------
module data_mem (input clk, we,
		 input  [31:0] address, wd,
		 output [31:0] rd);

	reg [31:0] RAM[63:0];

	initial begin
		$readmemh ("memfile_data.hex",RAM,0,63);
	end

	assign rd=RAM[address[31:2]]; // word aligned

	always @ (posedge clk)
		if (we) begin
			RAM[address[31:2]]<=wd;
			// $display (wd);
		end
endmodule

//-------------------------------------------------------------------
module inst_mem (input  [6:0]  address,
		 output [31:0] rd);

	// reg [31:0] RAM[63:0];
	reg [31:0] RAM[127:0];
	initial begin
		// $readmemh ("memfile_inst.hex",RAM,0,63);
		// $readmemh ("testprog.hex",RAM,0,63);
		$readmemh ("myTest.hex",RAM,0,127);
	end
	assign rd=RAM[address]; // word aligned
endmodule

// 1111 1111 1111 ... 1111 1100
// 1111 1111 1111 ... 1111 1110
// 1111 1111 1111 ... 1111 1010

// 0100
// 0010
// 0110
// 1010