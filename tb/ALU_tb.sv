`timescale 1ns/1ps

import riscv_pkg::*;

module ALU_tb;
    logic [31:0] in1;
    logic [31:0] in2;
    ALU_OP_TYPE   op;
    logic [31:0] out;
    logic        zero_flag;

    int total_tests;
    int error_count;

    ALU dut (
        .in1(in1),
        .in2(in2),
        .op(op),
        .out(out),
        .zero_flag(zero_flag)
    );

    function automatic logic [31:0] model_alu(
        input logic [31:0] a,
        input logic [31:0] b,
        input ALU_OP_TYPE  alu_op
    );
        case (alu_op)
            ALU_ADD:  model_alu = a + b;
            ALU_SLL:  model_alu = a << b[4:0];
            ALU_SLT:  model_alu = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
            ALU_SLTU: model_alu = (a < b) ? 32'd1 : 32'd0;
            ALU_XOR:  model_alu = a ^ b;
            ALU_SRL:  model_alu = a >> b[4:0];
            ALU_OR:   model_alu = a | b;
            ALU_AND:  model_alu = a & b;
            ALU_SUB:  model_alu = a - b;
            ALU_SRA:  model_alu = $signed(a) >>> b[4:0];
            default:  model_alu = 32'd0;
        endcase
    endfunction

    task automatic check_case(
        input logic [31:0] a,
        input logic [31:0] b,
        input ALU_OP_TYPE  alu_op,
        input string       name
    );
        logic [31:0] expected_out;
        logic        expected_zero;

        expected_out  = model_alu(a, b, alu_op);
        expected_zero = (expected_out == 32'd0);

        in1 = a;
        in2 = b;
        op  = alu_op;
        #1;

        total_tests++;
        if ((out !== expected_out) || (zero_flag !== expected_zero)) begin
            error_count++;
            $display("[FAIL] %s | op=%0d in1=0x%08h in2=0x%08h | exp_out=0x%08h got_out=0x%08h | exp_zero=%0b got_zero=%0b",
                     name, alu_op, a, b, expected_out, out, expected_zero, zero_flag);
        end
    endtask

    task automatic run_directed_tests;
        begin
            // Directed edge/corner tests per operation.
            check_case(32'h00000000, 32'h00000000, ALU_ADD,  "ADD zero");
            check_case(32'hFFFFFFFF, 32'h00000001, ALU_ADD,  "ADD wrap");

            check_case(32'h00000001, 32'h0000001F, ALU_SLL,  "SLL max shamt");
            check_case(32'h12345678, 32'h00000004, ALU_SLL,  "SLL normal");

            check_case(32'hFFFFFFFF, 32'h00000001, ALU_SLT,  "SLT -1 < 1");
            check_case(32'h7FFFFFFF, 32'h80000000, ALU_SLT,  "SLT signed boundary");

            check_case(32'h00000001, 32'hFFFFFFFF, ALU_SLTU, "SLTU unsigned");
            check_case(32'hFFFFFFFF, 32'hFFFFFFFF, ALU_SLTU, "SLTU equal");

            check_case(32'hAAAAAAAA, 32'h55555555, ALU_XOR,  "XOR checker");
            check_case(32'h00000000, 32'h00000000, ALU_XOR,  "XOR zero");

            check_case(32'h80000000, 32'h0000001F, ALU_SRL,  "SRL logical fill");
            check_case(32'h12345678, 32'h00000008, ALU_SRL,  "SRL normal");

            check_case(32'h0F0F0000, 32'h00F000F0, ALU_OR,   "OR mix");
            check_case(32'h00000000, 32'h00000000, ALU_OR,   "OR zero");

            check_case(32'hF0F0F0F0, 32'h0FF00FF0, ALU_AND,  "AND mix");
            check_case(32'hFFFFFFFF, 32'h00000000, ALU_AND,  "AND zero result");

            check_case(32'h00000003, 32'h00000003, ALU_SUB,  "SUB zero result");
            check_case(32'h00000000, 32'h00000001, ALU_SUB,  "SUB underflow");

            check_case(32'h80000000, 32'h0000001F, ALU_SRA,  "SRA sign extend");
            check_case(32'h7FFFFFFF, 32'h00000001, ALU_SRA,  "SRA positive");
        end
    endtask

    task automatic run_random_tests_for_op(
        input ALU_OP_TYPE alu_op,
        input int         count
    );
        int i;
        logic [31:0] a;
        logic [31:0] b;
        begin
            for (i = 0; i < count; i++) begin
                a = $urandom;
                b = $urandom;
                check_case(a, b, alu_op, "random");
            end
        end
    endtask

    initial begin
        total_tests = 0;
        error_count = 0;

        // Initialize inputs to avoid X-propagation at time 0.
        in1 = '0;
        in2 = '0;
        op  = ALU_ADD;
        #1;

        run_directed_tests();

        // Sweep random testing across every ALU operation.
        run_random_tests_for_op(ALU_ADD,  100);
        run_random_tests_for_op(ALU_SLL,  100);
        run_random_tests_for_op(ALU_SLT,  100);
        run_random_tests_for_op(ALU_SLTU, 100);
        run_random_tests_for_op(ALU_XOR,  100);
        run_random_tests_for_op(ALU_SRL,  100);
        run_random_tests_for_op(ALU_OR,   100);
        run_random_tests_for_op(ALU_AND,  100);
        run_random_tests_for_op(ALU_SUB,  100);
        run_random_tests_for_op(ALU_SRA,  100);

        if (error_count == 0) begin
            $display("[PASS] ALU_tb completed: %0d tests, %0d failures", total_tests, error_count);
        end else begin
            $display("[FAIL] ALU_tb completed: %0d tests, %0d failures", total_tests, error_count);
            $fatal(1, "ALU functional mismatches detected");
        end

        $finish;
    end

endmodule