module Reg_file (
    input  logic        clk,
    input  logic [4:0]  rs1, rs2, rd,
    input  logic [31:0] write_data,
    input  logic        we,
    output logic [31:0] rd1, rd2
);

	logic [31:0] regs[31:0]; // x1 RA, x2 SP 

	assign rd1 = (rs1 == 5'b0) ? 32'b0 : regs[rs1];
	assign rd2 = (rs2 == 5'b0) ? 32'b0 : regs[rs2];
	 
	always_ff @(posedge clk) begin
		if (we && rd != 5'b0)   // x0 is hardwired to 0
			regs[rd] <= write_data;
	end
	 
endmodule