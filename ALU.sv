import riscv_pkg::*;

module ALU(input logic[31:0] in1,
				input logic[31:0] in2,
				input ALU_OP_TYPE op,
				output logic[31:0] out,
				output logic zero_flag );
	
    always_comb begin
        case(op)
        ALU_ADD:  out = in1 + in2;
        ALU_SLL:  out = in1 << in2[4:0];
        ALU_SLT:  out = ($signed(in1) < $signed(in2)) ? 32'd1 : 32'd0;
        ALU_SLTU: out = (in1 < in2) ? 32'd1 : 32'd0;
        ALU_XOR:  out = in1 ^ in2;
        ALU_SRL:  out = in1 >> in2[4:0];
        ALU_OR:   out = in1 | in2;
        ALU_AND:  out = in1 & in2;
        ALU_SUB:  out = in1 - in2;
        ALU_SRA:  out = $signed(in1) >>> in2[4:0];
		default:  out = 32'd0;
        endcase	
		  
		if (out == 0)
			zero_flag = 1'b1;
		else
			zero_flag = 1'b0;
		end			
endmodule