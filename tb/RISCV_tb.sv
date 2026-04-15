import riscv_pkg::*;

`timescale 1ns/1ps

module RISCV_tb;
	logic        clk;
	logic        rst;
	logic [31:0] pc_reg;
	logic [31:0] pc_next;
	logic [31:0] wb_reg;
	logic [31:0] inst_reg;
	logic [4:0]  rs1;
	logic [4:0]  rs2;
	logic [4:0]  rd;
	logic [31:0] imm;
	ALU_OP_TYPE  alu_op;
	logic        alu_src_imm;
	logic        alu_src_pc;
	logic        mem_load;
	logic        mem_store;
	LOAD_TYPE    load_op;
	STORE_TYPE   store_op;
	logic        wb;
	WB_TYPE      wb_src;
	logic        branch;
	logic        jump;
	BRANCH_TYPE  branch_op;
	logic [31:0] rs1_data;
	logic [31:0] rs2_data;
	logic [31:0] alu_in1;
	logic [31:0] alu_in2;
	logic [31:0] alu_out;
	logic        zero_flag;
	logic        take_branch;
	logic [31:0] regfile_regs [31:0];

	RISCV dut (
		.clk(clk),
		.rst(rst),
		.pc_reg(pc_reg),
		.pc_next(pc_next),
		.wb_reg(wb_reg),
		.inst_reg(inst_reg),
		.rs1(rs1),
		.rs2(rs2),
		.rd(rd),
		.imm(imm),
		.alu_op(alu_op),
		.alu_src_imm(alu_src_imm),
		.alu_src_pc(alu_src_pc),
		.mem_load(mem_load),
		.mem_store(mem_store),
		.load_op(load_op),
		.store_op(store_op),
		.wb(wb),
		.wb_src(wb_src),
		.branch(branch),
		.jump(jump),
		.branch_op(branch_op),
		.rs1_data(rs1_data),
		.rs2_data(rs2_data),
		.alu_in1(alu_in1),
		.alu_in2(alu_in2),
		.alu_out(alu_out),
		.zero_flag(zero_flag),
		.take_branch(take_branch),
		.regfile_regs(regfile_regs)
	);

	// 100 MHz clock
	initial clk = 1;
	always #5 clk = ~clk;

	initial begin
		$dumpfile("RISCV_tb.vcd");
		$dumpvars(0, RISCV_tb);
	end

	initial begin
		rst = 1;
		#5;
		rst = 0;

		repeat (30) @(posedge clk);
		$finish;
	end
	
endmodule
