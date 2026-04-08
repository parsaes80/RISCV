import riscv_pkg::*;

module RISCV (
    input  logic        clk,
    input  logic        rst,
    input  logic [31:0] inst,
    output logic [31:0] pc_reg,
    output logic [31:0] pc_next,
    output logic [31:0] wb_reg,
    output logic [31:0] inst_reg,
    output logic [4:0]  rs1,
    output logic [4:0]  rs2,
    output logic [4:0]  rd,
    output logic [31:0] imm,
    output ALU_OP_TYPE  alu_op,
    output logic        alu_src_imm,
    output logic        alu_src_pc,
    output logic        mem_load,
    output logic        mem_store,
    output LOAD_TYPE    load_op,
    output STORE_TYPE   store_op,
    output logic        wb,
    output WB_TYPE      wb_src,
    output logic        branch,
    output logic        jump,
    output BRANCH_TYPE  branch_op,
    output logic [31:0] rs1_data,
    output logic [31:0] rs2_data,
    output logic [31:0] alu_in1,
    output logic [31:0] alu_in2,
    output logic [31:0] alu_out,
    output logic        zero_flag,
    output logic        take_branch
);
    
    logic [31:0] mem_load_data;
    logic [15:0] mem_addr;
    logic [7:0]  mem_store_data;
    logic [7:0]  mem_q;

    localparam logic [31:0] RESET_PC = 32'h00010094;
   
    assign mem_addr = alu_out[15:0];

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            // Start at program entry and hold a NOP until first fetch after reset.
            pc_reg   <= RESET_PC;
            inst_reg <= 32'h00000013;
        end else begin
            inst_reg <= inst;
            pc_reg   <= pc_next;
        end
    end
    
    always_comb begin
        alu_in1 = alu_src_pc ? pc_reg : rs2_data;
        alu_in2 = alu_src_imm ? imm : rs2_data;
    end     
    
    always_comb begin
        if (wb) begin
            unique case (wb_src)
                ALU_WB: wb_reg = alu_out;
                MEM_WB: wb_reg = mem_load_data;
            endcase
        end else 
            wb_reg = alu_out;
    end
    
    always_comb begin
        pc_next = pc_reg + 32'd4;
        take_branch = 1'b0;
        if (jump) begin
            if (alu_src_pc)
                pc_next = pc_reg + imm;
            else
                pc_next = {alu_out[31:1], 1'b0};
        end else if (branch) begin
            unique case (branch_op)
                BEQ:  take_branch = (rs1_data == rs2_data);
                BNE:  take_branch = (rs1_data != rs2_data);
                BLT:  take_branch = ($signed(rs1_data) <  $signed(rs2_data));
                BGE:  take_branch = ($signed(rs1_data) >= $signed(rs2_data));
                BLTU: take_branch = (rs1_data <  rs2_data);
                BGEU: take_branch = (rs1_data >= rs2_data);
                default: take_branch = 1'b0;
            endcase
            if (take_branch)
                pc_next = pc_reg + imm;
        end
    end
    
    always_comb begin
        if(mem_store) begin
            unique case (alu_out[1:0])
                2'b00: mem_store_data = rs2_data[7:0];
                2'b01: mem_store_data = rs2_data[15:8];
                2'b10: mem_store_data = rs2_data[23:16];
                default: mem_store_data = rs2_data[31:24];
            endcase
        end
        else
            mem_store_data = 8'b0;
            
        if(mem_load) begin
            unique case (load_op)
                LB:  mem_load_data = {{24{mem_q[7]}}, mem_q};
                LBU: mem_load_data = {24'b0, mem_q};
                LH:  mem_load_data = {{24{mem_q[7]}}, mem_q};
                LHU: mem_load_data = {24'b0, mem_q};
                LW:  mem_load_data = {{24{mem_q[7]}}, mem_q};
                default: mem_load_data = 32'b0;
            endcase
        end
        else 
            mem_load_data = 32'b0;
    end

    // s_memory memory (
    //     .address(mem_addr),
    //     .clock(clk),
    //     .data(mem_store_data),
    //     .wren(mem_store),
    //     .q(mem_q)
    // );

    Decoder decoder (
        .inst(inst_reg),
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
        .branch_op(branch_op)
    );

    Reg_file regfile (
        .clk(clk),
        .rst(rst),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .write_data(wb_reg),
        .we(reg_write),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data)
    );
    
    ALU alu (
        .in1(alu_in1),
        .in2(alu_in2),
        .op(alu_op),
        .out(alu_out),
        .zero_flag(zero_flag)
    );

endmodule

