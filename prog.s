.set noreorder
addi $2, $zero, 0
addi $3, $zero, 36 # 2 insn per loop, 32767 * 18 * 2 ~ 2.4M
addi $1, $zero, 0 
setup:
    addi $2, $2, 32767
    addi $3, $3, -1
bne $3, $zero, setup

    add $3, $2, $zero

loop_outer:
    add $2, $3, $zero
loop_inner:
        addi $2, $2, -1
    bne $2, $zero, loop_inner
    bne $1, $zero, set_zero
        addi $1, $1, 1
        bne $3, $zero, loop_outer
    set_zero:
        addi $1, $zero, 0
        bne $3, $zero, loop_outer

