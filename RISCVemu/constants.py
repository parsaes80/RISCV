from enum import IntEnum
 
class Opcode(IntEnum):
    # instruction opcodes
    R     = 0b0110011   # register-register  (ADD, SUB, AND, OR, XOR, SLT...)
    I     = 0b0010011   # immediate arith    (ADDI, ANDI, ORI, XORI, SLTI...)
    L     = 0b0000011   # loads              (LW, LH, LB, LHU, LBU)
    S     = 0b0100011   # stores             (SW, SH, SB)
    B     = 0b1100011   # branches           (BEQ, BNE, BLT, BGE, BLTU, BGEU)
    JAL   = 0b1101111   # jump and link
    JALR  = 0b1100111   # jump and link register
    LUI   = 0b0110111   # load upper immediate
    AUIPC = 0b0010111   # add upper immediate to PC
 

    ALU_ADD  = 0b0000   # funct3=000, bit30=0
    ALU_SLL  = 0b0001   # funct3=001
    ALU_SLT  = 0b0010   # funct3=010
    ALU_SLTU = 0b0011   # funct3=011
    ALU_XOR  = 0b0100   # funct3=100
    ALU_SRL  = 0b0101   # funct3=101, bit30=0
    ALU_OR   = 0b0110   # funct3=110
    ALU_AND  = 0b0111   # funct3=111
    ALU_SUB  = 0b1000   # funct3=000, bit30=1  ← same as ADD but bit30 set
    ALU_SRA  = 0b1101   # funct3=101, bit30=1  ← same as SRL but bit30 set

    SPidx = 2
    RAidx = 1