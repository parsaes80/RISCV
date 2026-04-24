	.file	"prog.c"
	.option nopic
	.attribute arch, "rv32i2p1"
	.attribute unaligned_access, 0
	.attribute stack_align, 16
	.text
	.align	2
	.globl	main
	.type	main, @function
main:
 #APP
# 5 "prog.c" 1
	addi a0, x0, 1
addi a1, x0, 1
addi a2, x0, 4
1:
beq a2, x0, 2f
add a3, a0, x0
add a0, a0, a1
add a1, a3, x0
addi a2, a2, -1
jal x0, 1b
2:
add a0, a0, a1
jalr x0, 0(x1)

# 0 "" 2
 #NO_APP
	.size	main, .-main
	.ident	"GCC: (Arch Linux Repositories) 15.2.0"
	.section	.note.GNU-stack,"",@progbits
