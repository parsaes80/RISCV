transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog  -work work +incdir+/home/parsa/Data/Coding_Projects/Hardware/RISCV {/home/parsa/Data/Coding_Projects/Hardware/RISCV/s_memory.v}
vlog -sv -work work +incdir+/home/parsa/Data/Coding_Projects/Hardware/RISCV {/home/parsa/Data/Coding_Projects/Hardware/RISCV/RISCV.sv}

