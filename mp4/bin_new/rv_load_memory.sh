#!/bin/bash

# Settings
TARGET_FILE=$PWD/../sim/memory.lst
ASSEMBLER=/class/ece411/software/riscv-tools/bin/riscv32-unknown-elf-gcc
OBJCOPY=/class/ece411/software/riscv-tools/bin/riscv32-unknown-elf-objcopy
OBJDUMP=/class/ece411/software/riscv-tools/bin/riscv32-unknown-elf-objdump
ADDRESSABILITY=32

# Command line parameters
IN_FILE=$1

# Assemble code
"$ASSEMBLER" -ffreestanding -nostdlib -T link.ld -Os -Wall -Wextra -Wno-unused -march=rv32im -Wl,--no-relax startup.s "$IN_FILE"

"$OBJDUMP" -S a.out -Mnumeric
"$OBJCOPY" -O binary a.out a.bin
#hexdump a.bin


# Write memory to file
function log2 {
    local x=0
    for (( y=$1-1 ; $y > 0; y >>= 1 )) ; do
        let x=$x+1
    done
    echo $x
}

z=$( log2 $ADDRESSABILITY )
hex="0x00000060"
result=$(( hex >> $z ))
mem_start=$(printf "@%08x\n" $result)

{
    echo $mem_start
    hexdump -ve $ADDRESSABILITY'/1 "%02X " "\n"' a.bin \
        | awk '{for (i = NF; i > 0; i--) printf "%s", $i; print ""}'
} > "$TARGET_FILE"

echo "Assembled $ASM_FILE and wrote memory contents to $TARGET_FILE"

#cp $PWD/memory.lst ../sim/
