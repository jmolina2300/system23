#+
# Makefile for the boot loader
#
#-
boot: boot.asm
	nasm -o boot.img boot.asm
	truncate -s 1474560 boot.img

run: boot.img
	qemu-system-i386 -drive format=raw,file=boot.img
