#+
# Makefile for the boot loader
#
#-

disk: boot boot1
	cat boot.img boot1.img > disk.img
	truncate -s 1474560 disk.img

boot: boot.asm
	nasm -o boot.img boot.asm

boot1: boot1.asm
	nasm -o boot1.img boot1.asm



run: disk
	qemu-system-i386 -drive format=raw,file=disk.img -m 10M
