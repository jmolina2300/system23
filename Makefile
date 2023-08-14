#+
# Makefile for the boot loader
#
#-

disk: boot boot1 fat1-2
	cat boot.bin boot1.bin fat1-2.bin > disk.img
	truncate -s 1474560 disk.img

boot: boot.asm
	nasm -o boot.bin boot.asm

boot1: boot1.asm
	nasm -o boot1.bin boot1.asm

fat1-2: fat1-2.asm
	nasm -o fat1-2.bin fat1-2.asm



run: disk
	qemu-system-i386 -drive format=raw,file=disk.img -m 10M
