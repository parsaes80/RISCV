#!/usr/bin/env bash
set -euo pipefail

"riscv64-elf-gcc" -march=rv32i -mabi=ilp32 -S "prog.c" -o "prog.s"

"riscv64-elf-gcc" -march=rv32i -mabi=ilp32 -c "prog.s" -o "prog.o"

"riscv64-elf-gcc" -march=rv32i -mabi=ilp32 -c "crt0.s" -o "crt0.o"

"riscv64-elf-gcc" -march=rv32i -mabi=ilp32 -nostdlib -nostartfiles -Wl,-e,_start "crt0.o" "prog.o" -o "prog"

riscv64-elf-objdump -d -S -M no-aliases prog > instructions.txt
 