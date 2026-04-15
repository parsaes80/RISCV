module Reg_file (
    input  logic        clk,
	input  logic        rst,
    input  logic [4:0]  rs1, rs2, rd,
    input  logic [31:0] write_data,
    input  logic        we,
	output logic [31:0] rs1_data, rs2_data,
	output logic [31:0] regs_out [31:0]
);

	logic [31:0] regs[31:0]; // x0=0, x1=RA, x2=SP
	

	assign rs1_data = (rs1 == 5'b0) ? 32'b0 : regs[rs1];
	assign rs2_data = (rs2 == 5'b0) ? 32'b0 : regs[rs2];
	assign regs_out = regs;

	always_ff @(posedge clk or posedge rst) begin
        integer i;
		if (rst) begin
			for (i = 0; i < 32; i = i + 1)
				regs[i] <= 32'b0;
		end else begin
			if (we && rd != 5'b0)   // x0 is hardwired to 0
				regs[rd] <= write_data;
			regs[0] <= 32'b0;
		end
	end

endmodule