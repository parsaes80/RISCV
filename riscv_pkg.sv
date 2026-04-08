package riscv_pkg;

typedef enum logic [3:0] {
	  ALU_ADD  = 4'b0000,  // funct3=000, bit30=0
	  ALU_SLL  = 4'b0001,  // funct3=001
	  ALU_SLT  = 4'b0010,  // funct3=010
	  ALU_SLTU = 4'b0011,  // funct3=011
	  ALU_XOR  = 4'b0100,  // funct3=100
	  ALU_SRL  = 4'b0101,  // funct3=101, bit30=0
	  ALU_OR   = 4'b0110,  // funct3=110
	  ALU_AND  = 4'b0111,  // funct3=111
	  ALU_SUB  = 4'b1000,  // funct3=000, bit30=1
	  ALU_SRA  = 4'b1101   // funct3=101, bit30=1
} ALU_OP_TYPE;

typedef enum {ALU_WB,MEM_WB} WB_TYPE;
typedef enum {LB,LH,LW,LBU,LHU} LOAD_TYPE;
typedef enum {SW,SH,SB} STORE_TYPE;
typedef enum {BEQ,BNE,BLT,BGE,BLTU,BGEU} BRANCH_TYPE;

endpackage