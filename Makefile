#+
# Makefile for the boot loader
#
#-
CC = gcc
ASM = nasm
FATVER = 12

ifeq ($(FATVER),12)
	DISK_CAPACITY = 1474560
else
	DISK_CAPACITY = 10M
endif



##
## Glue everything together
##
disk: boot.bin boot1.bin fat.bin  rootdir.bin
	cat boot.bin boot1.bin fat.bin  rootdir.bin > disk.img
	truncate -s $(DISK_CAPACITY) disk.img

boot.bin: boot.asm
	$(ASM) -o boot.bin boot.asm

boot1.bin: boot1.asm
	$(ASM) -o boot1.bin boot1.asm


## Generate the 2 FATs using the BPB values
fat.bin: fatgen.c boot.bin
	$(CC) -o fatgen fatgen.c
	./fatgen boot.bin


## Generate the root directory entries
rootdir.bin: rootdir.asm
	$(ASM) -o rootdir.bin rootdir.asm

clean:
	rm -i -f *.bin *.o *.img fatgen

run: disk
	qemu-system-x86_64 -drive format=raw,file=disk.img -m 10M
