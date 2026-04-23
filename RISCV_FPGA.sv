import riscv_pkg::*;

module RISCV_FPGA (
    input  logic        CLOCK_50,
    input  logic [3:0]  KEY,
    output logic [17:0] LEDR
);

    localparam int unsigned CLK_DIVISOR  = 1_000_000;
    localparam int unsigned HALF_DIVISOR = CLK_DIVISOR / 2;

    logic [31:0] pc_reg;
    logic [31:0] regfile_regs [31:0];
    logic [19:0] clk_div_counter;
    logic        core_clk;

    always_ff @(posedge CLOCK_50 or negedge KEY[1]) begin
        if (!KEY[1]) begin
            clk_div_counter <= 20'd0;
            core_clk <= 1'b0;
        end else begin
            if (clk_div_counter == HALF_DIVISOR - 1) begin
                clk_div_counter <= 20'd0;
                core_clk <= ~core_clk;
            end else begin
                clk_div_counter <= clk_div_counter + 20'd1;
            end
        end
    end

    RISCV core (
        .clk(core_clk),
        .rst(~KEY[1]),
        .pc_reg(pc_reg),
        .pc_next(),
        .wb_reg(),
        .inst_reg(),
        .rs1(),
        .rs2(),
        .rd(),
        .imm(),
        .alu_op(),
        .alu_src_imm(),
        .alu_src_pc(),
        .mem_load(),
        .mem_store(),
        .load_op(),
        .store_op(),
        .wb(),
        .wb_src(),
        .branch(),
        .jump(),
        .branch_op(),
        .rs1_data(),
        .rs2_data(),
        .alu_in1(),
        .alu_in2(),
        .alu_out(),
        .zero_flag(),
        .take_branch(),
        .regfile_regs(regfile_regs),
        .mem_load_data(),
        .mem_addr(),
        .mem_store_data(),
        .mem_byte_en(),
        .mem_q(),
        .load_byte(),
        .load_half(),
        .instr_mem()
    );

    // x10 is ABI register a0.
    assign LEDR = regfile_regs[10][17:0];

endmodule
