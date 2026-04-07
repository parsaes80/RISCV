import riscv_pkg::*;

module Decoder(
    input logic[31:0] inst,
    // === Register addresses ===
    output logic [4:0]  rs1, rs2, rd,
    // === Immediate value (sign extended, ready to use) ===
    output logic [31:0] imm,
    // === ALU control ===
    output ALU_OP_TYPE  alu_op,      // which ALU operation
    output logic        alu_src_imm,     // 0 = rs2, 1 = imm
    output logic        alu_src_pc,      // 0 = rs1, 1 = PC
    // === Memory control ===
    output logic        mem_load,    // 1 = load instruction (LW)
    output logic        mem_store,   // 1 = store instruction (SW)
    output LOAD_TYPE    load_op,  // byte/half/word 
    output STORE_TYPE   store_op,  // byte/half/word 
    // === Register writeback ===
    output logic        reg_write,   // 1 = write result back to rd
    output WB_TYPE       wb_src,      // what to write back (ALU / memory / PC+4)
    // === PC control ===
    output logic        branch,      // 1 = this is a branch instruction
    output logic        jump,        // 1 = unconditional jump (JAL/JALR)
    output BRANCH_TYPE  branch_op    // branch condition
     );
     
    localparam logic[6:0] R     = 7'b0110011;
    localparam logic[6:0] I     = 7'b0010011;
    localparam logic[6:0] L     = 7'b0000011;  
    localparam logic[6:0] S     = 7'b0100011; 
    localparam logic[6:0] B     = 7'b1100011;   
    localparam logic[6:0] JAL   = 7'b1101111;  
    localparam logic[6:0] JALR  = 7'b1100111;   
    localparam logic[6:0] LUI   = 7'b0110111;  
    localparam logic[6:0] AUIPC = 7'b0010111;
     
    always_comb begin
    
        logic[6:0] opcode;
        logic[2:0] funct3;
        logic[6:0] funct7;
        logic[11:0] imm12;
        logic[19:0] imm20;
        logic[4:0]  shamt;
                 
        opcode = inst[6:0];
        rd = inst[11:7];
        funct3 = inst[14:12];
        rs1 = inst[19:15];
        rs2 = inst[24:20];
        funct7 = inst[31:25];
        imm12 = inst[31:20];
        imm20 = inst[31:12];
        shamt = inst[24:20];

        // Defaults to avoid latches while cases are being completed.
        alu_op = ALU_ADD;
        alu_src_imm = 1'b0;
        alu_src_pc = 1'b0;
        mem_load = 1'b0;
        mem_store = 1'b0;
        load_op = LB;
        store_op = SW;
        reg_write = 1'b0;
        wb_src = ALU_WB;
        branch = 1'b0;
        jump = 1'b0;
        branch_op = BEQ;
        imm = 32'b0;
        
        case (opcode)
            R: begin
                reg_write = 1;
               case (funct3)
                  3'b000: begin  
                     if (funct7 == 7'b0000000) 
                        alu_op = ALU_ADD;
                     else if (funct7 == 7'b0100000)
                        alu_op = ALU_SUB;
                  end
                  3'b001: alu_op = ALU_SLL;
                  3'b010: alu_op = ALU_SLT;
                  3'b011: alu_op = ALU_SLTU;
                  3'b100: alu_op = ALU_XOR;
                  3'b101: begin
                     if (funct7 == 7'b0000000) 
                        alu_op = ALU_SRL;
                     else if (funct7 == 7'b0100000)
                        alu_op = ALU_SRA;
                  end
                  3'b110: alu_op = ALU_OR;
                  3'b111: alu_op = ALU_AND;
               endcase
            end
            I: begin
               alu_src_imm = 1'b1;
               reg_write = 1;
               if (funct3 == 3'b001) begin
                  alu_op = ALU_SLL;
                  // Shift-immediates use low 5 bits and zero the upper bits.
                  imm = {27'd0, shamt};
               end else if (funct3 == 3'b101) begin
                  if (inst[30] == 1'b1)
                     alu_op = ALU_SRA;
                  else
                     alu_op = ALU_SRL;
                  // Shift-immediates use low 5 bits and zero the upper bits.
                  imm = {27'd0, shamt};
               end else begin
                  case (funct3)
                     3'b000: alu_op = ALU_ADD;
                     3'b010: alu_op = ALU_SLT;
                     3'b011: alu_op = ALU_SLTU;
                     3'b100: alu_op = ALU_XOR;
                     3'b110: alu_op = ALU_OR;
                     3'b111: alu_op = ALU_AND;
                     default:alu_op = ALU_ADD;
                  endcase
                  // Non-shift I-type immediates are sign-extended from 12 bits.
                  imm = {{20{imm12[11]}}, imm12};
               end
            end     
            L: begin
                mem_load = 1;
                reg_write = 1;
               alu_src_imm = 1'b1;
               alu_op = ALU_ADD;
               wb_src = MEM_WB;
                case (funct3)
                    3'b000:  load_op = LB; 
                    3'b001:  load_op = LH; 
                    3'b010:  load_op = LW; 
                    3'b100:  load_op = LBU;
                    3'b101:  load_op = LHU;
                    default: load_op = LB;  
               endcase
               // Load offset is I-type immediate (signed 12-bit).
               imm = {{20{imm12[11]}}, imm12};
            end
            S: begin
                mem_store = 1;
               alu_src_imm = 1'b1;
               alu_op = ALU_ADD;
                imm12 = {inst[31:25],inst[11:7]};
                case (funct3)
                     3'b000: store_op = SB;
                     3'b001: store_op = SH;
                     3'b010: store_op = SW;
                     default: store_op = SB;  
                endcase
               // Store offset is S-type immediate (signed 12-bit).
               imm = {{20{imm12[11]}}, imm12};
            end   
            B: begin
               // Branch target offset is B-type immediate (signed 13-bit with bit0=0).
               imm = {{19{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8], 1'b0};
               case (funct3)
                    3'b000:  branch_op = BEQ;  
                    3'b001:  branch_op = BNE;  
                    3'b100:  branch_op = BLT;  
                    3'b101:  branch_op = BGE;  
                    3'b110:  branch_op = BLTU; 
                    3'b111:  branch_op = BGEU;
                    default: branch_op = BEQ;  
                endcase
                branch = 1'b1;
            end    
            JAL: begin
               // JAL offset is J-type immediate (signed 21-bit with bit0=0).
               reg_write = 1;
               alu_src_pc = 1'b1;
               alu_src_imm = 1'b1;
               alu_op = ALU_ADD;
               wb_src = PC_WB;
               imm = {{11{inst[31]}}, inst[31], inst[19:12], inst[20], inst[30:21], 1'b0};
               jump = 1'b1;
            end   
            JALR: begin
               // JALR uses I-type signed 12-bit immediate.
               reg_write = 1;
               alu_src_imm = 1'b1;
               alu_op = ALU_ADD;
               wb_src = PC_WB;
               imm = {{20{imm12[11]}}, imm12};
               jump = 1'b1;
            end
            LUI: begin
               // U-type immediate is placed in upper 20 bits (lower 12 are zero).
               reg_write = 1'b1;
               // LUI does not use rs1; force x0 so ALU computes 0 + imm.
               rs1 = 5'd0;
               imm = {imm20,12'b0};
               alu_op = ALU_ADD;
               alu_src_imm = 1'b1;
               wb_src = ALU_WB;
            end  
            AUIPC: begin
               // AUIPC uses the same U-type immediate and writes ALU result.
               reg_write = 1'b1;
               imm = {imm20,12'b0};
               alu_op = ALU_ADD;
               alu_src_pc = 1'b1;
               alu_src_imm = 1'b1;
               wb_src = ALU_WB;
            end
            default:
               imm = 32'b0;
        endcase   
   end
endmodule



        //defaults
    //    mem_read=0; 
    //    mem_write=0; 
     //   reg_write=0; 
    //    branch=0; 
    //    jump=0; 
    //    alu_src=0; 
    //    wb_src=alu; 
    //    imm=0; 
    //    branch_op=0; 
    //    mem_funct3=0; 
   //     alu_op=ALU_ADD;





