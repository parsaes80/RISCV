`timescale 1ns/1ps

module RISCV_tb;
	logic        clk;
	logic        rst;
	logic [31:0] inst;

	RISCV dut (
		.clk(clk),
		.rst(rst),
		.inst(inst)
	);

	// 100 MHz clock
	initial clk = 1'b0;
	always #5 clk = ~clk;

	// Program ROM driven by DUT PC.
	function automatic logic [31:0] get_inst(input logic [31:0] pc);
		begin
			unique case (pc)
				32'h00010094: get_inst = 32'h00200137; // lui   sp,0x200
				32'h00010098: get_inst = 32'h008000ef; // jal   ra,100a0
				32'h0001009c: get_inst = 32'h0000006f; // jal   zero,1009c
				32'h000100a0: get_inst = 32'h00100513; // addi  a0,zero,1
				32'h000100a4: get_inst = 32'h00100593; // addi  a1,zero,1
				32'h000100a8: get_inst = 32'h00400613; // addi  a2,zero,4
				32'h000100ac: get_inst = 32'h00060c63; // beq   a2,zero,100c4
				32'h000100b0: get_inst = 32'h000506b3; // add   a3,a0,zero
				32'h000100b4: get_inst = 32'h00b50533; // add   a0,a0,a1
				32'h000100b8: get_inst = 32'h000685b3; // add   a1,a3,zero
				32'h000100bc: get_inst = 32'hfff60613; // addi  a2,a2,-1
				32'h000100c0: get_inst = 32'hfedff06f; // jal   zero,100ac
				32'h000100c4: get_inst = 32'h00b50533; // add   a0,a0,a1
				32'h000100c8: get_inst = 32'h00008067; // jalr  zero,0(ra)
				default:      get_inst = 32'h00000013; // nop
			endcase
		end
	endfunction

	always_comb begin
		inst = get_inst(dut.pc_reg);
	end

	initial begin
		rst = 1'b1;

		repeat (2) @(posedge clk);
		rst = 1'b0;

		// Run long enough for the loop + return path.
		repeat (80) @(posedge clk);

		$display("Final PC = %h", dut.pc_reg);
		$display("a0(x10)  = %0d (0x%08h)", dut.regfile.regs[10], dut.regfile.regs[10]);

		if (dut.regfile.regs[10] === 32'd13)
			$display("PASS: expected a0=13");
		else
			$error("FAIL: expected a0=13, got %0d", dut.regfile.regs[10]);

		$finish;
	end
endmodule
