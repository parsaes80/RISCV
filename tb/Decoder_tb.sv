`timescale 1ns/1ps

import riscv_pkg::*;

module Decoder_tb;

	logic [31:0] inst;

	logic [4:0] rs1;
	logic [4:0] rs2;
	logic [4:0] rd;
	logic [31:0] imm;

	ALU_OP_TYPE alu_op;
	logic       alu_src_imm;
	logic       alu_src_pc;

	logic       mem_load;
	logic       mem_store;
	LOAD_TYPE   load_op;
	STORE_TYPE  store_op;

	logic       reg_write;
	WB_TYPE     wb_src;

	logic       branch;
	logic       jump;
	BRANCH_TYPE branch_op;

	Decoder dut (
		.inst(inst),
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
		.reg_write(reg_write),
		.wb_src(wb_src),
		.branch(branch),
		.jump(jump),
		.branch_op(branch_op)
	);

	logic [31:0] instr_mem [0:36];
	integer i;

	initial begin


		// Instruction stream provided by user.
		instr_mem[0]  = 32'h00200137;
		instr_mem[1]  = 32'h008000ef;
		instr_mem[2]  = 32'h0000006f;
		instr_mem[3]  = 32'hfe010113;
		instr_mem[4]  = 32'h00112e23;
		instr_mem[5]  = 32'h00812c23;
		instr_mem[6]  = 32'h02010413;
		instr_mem[7]  = 32'h00100793;
		instr_mem[8]  = 32'hfef42623;
		instr_mem[9]  = 32'h00100793;
		instr_mem[10] = 32'hfef42423;
		instr_mem[11] = 32'hfe042023;
		instr_mem[12] = 32'hfe042223;
		instr_mem[13] = 32'h0300006f;
		instr_mem[14] = 32'hfec42783;
		instr_mem[15] = 32'hfef42023;
		instr_mem[16] = 32'hfec42703;
		instr_mem[17] = 32'hfe842783;
		instr_mem[18] = 32'h00f707b3;
		instr_mem[19] = 32'hfef42623;
		instr_mem[20] = 32'hfe042783;
		instr_mem[21] = 32'hfef42423;
		instr_mem[22] = 32'hfe442783;
		instr_mem[23] = 32'h00178793;
		instr_mem[24] = 32'hfef42223;
		instr_mem[25] = 32'h000117b7;
		instr_mem[26] = 32'h1487a783;
		instr_mem[27] = 32'hfe442703;
		instr_mem[28] = 32'hfcf744e3;
		instr_mem[29] = 32'hfec42703;
		instr_mem[30] = 32'hfe842783;
		instr_mem[31] = 32'h00f707b3;
		instr_mem[32] = 32'h00078513;
		instr_mem[33] = 32'h01c12083;
		instr_mem[34] = 32'h01812403;
		instr_mem[35] = 32'h02010113;
		instr_mem[36] = 32'h00008067;

		inst = 32'b0;
		#10;

		for (i = 0; i <= 36; i = i + 1) begin
			inst = instr_mem[i];
			#10;
		end

	end

endmodule
