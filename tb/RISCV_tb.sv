import riscv_pkg::*;

`timescale 1ns/1ps

module RISCV_tb;
	logic        clk;
	logic        rst;
	logic [31:0] inst;
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

	RISCV dut (
		.clk(clk),
		.rst(rst),
		.inst(inst),
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
		.take_branch(take_branch)
	);

	// 100 MHz clock
	initial clk = 1;
	always #5 clk = ~clk;

	logic [31:0] instr_mem [0:13];
	integer i;

	initial begin
		$dumpfile("RISCV_tb.vcd");
		$dumpvars(0, RISCV_tb);
	end

	always @(posedge clk) begin
		if (!rst) begin
			$display("t=%0t pc=%h inst=%h x1=%h x2=%h x3=%h x4=%h x5=%h x6=%h x7=%h",
				$time, pc_reg, inst_reg,
				dut.regfile.regs[1], dut.regfile.regs[2], dut.regfile.regs[3],
				dut.regfile.regs[4], dut.regfile.regs[5], dut.regfile.regs[6],
				dut.regfile.regs[7]);
		end
	end

	initial begin
		
		instr_mem[0]  = 32'h00200137;
		instr_mem[1]  = 32'h008000ef;
		instr_mem[2]  = 32'h0000006f;
		instr_mem[3]  = 32'h00100513;
		instr_mem[4]  = 32'h00100593;
		instr_mem[5]  = 32'h00400613;
		instr_mem[6]  = 32'h00060c63;
		instr_mem[7]  = 32'h000506b3;
		instr_mem[8]  = 32'h00b50533;
		instr_mem[9]  = 32'h000685b3;
		instr_mem[10] = 32'hfff60613;
		instr_mem[11] = 32'hfedff06f;
		instr_mem[12] = 32'h00b50533;
		instr_mem[13] = 32'h00008067;

		inst = 32'b0;
		rst = 1;
		#5;
		rst= 0;

		for (i = 0; i <= 13; i = i + 1) begin
			inst = instr_mem[i];
			#10;
		end
	end
	
endmodule
