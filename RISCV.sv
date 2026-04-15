import riscv_pkg::*;

module RISCV (
    input  logic        clk,
    input  logic        rst,
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
    output logic        take_branch,
    output logic [31:0] regfile_regs [31:0]
);
    
    logic [31:0] mem_load_data;
    logic [15:0] mem_addr;
    logic [7:0]  mem_store_data;
    logic [7:0]  mem_q;
    logic [31:0] instr_mem [0:13];

    localparam logic [31:0] RESET_PC = 32'h00010094;
    localparam logic [31:0] LAST_INST_PC = RESET_PC + 32'd52;
   
    assign mem_addr = alu_out[15:0];

    assign instr_mem[0]  = 32'h00200137;
    assign instr_mem[1]  = 32'h008000ef;
    assign instr_mem[2]  = 32'h0000006f;
    assign instr_mem[3]  = 32'h00100513;
    assign instr_mem[4]  = 32'h00100593;
    assign instr_mem[5]  = 32'h00400613;
    assign instr_mem[6]  = 32'h00060c63;
    assign instr_mem[7]  = 32'h000506b3;
    assign instr_mem[8]  = 32'h00b50533;
    assign instr_mem[9]  = 32'h000685b3;
    assign instr_mem[10] = 32'hfff60613;
    assign instr_mem[11] = 32'hfedff06f;
    assign instr_mem[12] = 32'h00b50533;
    assign instr_mem[13] = 32'h00008067;

    always_comb begin
        if ((pc_reg >= RESET_PC) && (pc_reg <= LAST_INST_PC))
            inst_reg = instr_mem[(pc_reg - RESET_PC) >> 2];
        else
            inst_reg = 32'h00000013;
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            pc_reg <= RESET_PC;
        end else begin
            pc_reg <= pc_next;
        end
    end
    
    always_comb begin
        alu_in1 = alu_src_pc ? pc_reg : rs1_data; // for the U instruction
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
        end else
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
        end else 
            mem_load_data = 32'b0;
    end

    s_memory memory (
        .address(mem_addr),
        .clock(clk),
        .data(mem_store_data),
        .wren(mem_store),
        .q(mem_q)
    );

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
        .we(wb),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data),
        .regs_out(regfile_regs)
    );
    
    ALU alu (
        .in1(alu_in1),
        .in2(alu_in2),
        .op(alu_op),
        .out(alu_out),
        .zero_flag(zero_flag)
    );

endmodule

