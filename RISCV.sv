import riscv_pkg::*;

module RISCV (
    input  logic        clk,
    input  logic [31:0] inst
);
    logic [31:0] pc_reg;
    logic [31:0] pc_next;
    logic [31:0] pc_plus4;

    logic [4:0]  rs1_addr, rs2_addr, rd_addr;
    logic [31:0] imm;
    ALU_OP_TYPE  alu_op;
    logic        alu_src_imm;
    logic        alu_src_pc;
    logic        mem_load;
    logic        mem_store;
    LOAD_TYPE    load_op;
    STORE_TYPE   store_op;
    logic        reg_write;
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
    logic [31:0] wb_data;
    logic [31:0] mem_read_data;
    logic [15:0] mem_addr;
    logic [7:0]  mem_wdata;
    logic [7:0]  mem_q;

    assign mem_addr = alu_out[15:0];

    // Single-port memory is byte-wide, so choose the addressed byte lane.
    always_comb begin
        unique case (alu_out[1:0])
            2'b00: mem_wdata = rs2_data[7:0];
            2'b01: mem_wdata = rs2_data[15:8];
            2'b10: mem_wdata = rs2_data[23:16];
            default: mem_wdata = rs2_data[31:24];
        endcase
    end

    always_comb begin
        unique case (load_op)
            LB:  mem_read_data = {{24{mem_q[7]}}, mem_q};
            LBU: mem_read_data = {24'b0, mem_q};
            LH:  mem_read_data = {{24{mem_q[7]}}, mem_q};
            LHU: mem_read_data = {24'b0, mem_q};
            LW:  mem_read_data = {{24{mem_q[7]}}, mem_q};
            default: mem_read_data = 32'b0;
        endcase
    end

    s_memory memory (
        .address(mem_addr),
        .clock(clk),
        .data(mem_wdata),
        .wren(mem_store),
        .q(mem_q)
    );

    Decoder decoder (
        .inst(inst),
        .rs1(rs1_addr),
        .rs2(rs2_addr),
        .rd(rd_addr),
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

    Reg_file regfile (
        .clk(clk),
        .rs1(rs1_addr),
        .rs2(rs2_addr),
        .rd(rd_addr),
        .write_data(wb_data),
        .we(reg_write),
        .rd1(rs1_data),
        .rd2(rs2_data)
    );
    
    ALU alu (
        .in1(alu_in1),
        .in2(alu_in2),
        .op(alu_op),
        .out(alu_out),
        .zero_flag(zero_flag)
    );


endmodule