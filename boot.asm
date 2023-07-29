; Loaded at 0x7C00
org 7C00h
	jmp start
    nop
;=============================================================================
;     Begin DOS 2.0 BPB 
db 0,0,0,0,0,0,0,0
BytesPerSector:     dw 512     ; sector size in bytes
SectorsPerCluster:  db 1       ; sectors per cluster
ReservedSectors:    dw 1       ; number of reserved sectors for boot code
NumFATs:            db 2       ; number of FATs 
NumDirEntries:      dw 224     ; number of directory entries in the FAT
TotalSectors_16:    dw 2880    ; total sectors (if number fits in 16 bits)
MediaByte:          db 0xF1    ; media description byte
NumSectorsPerFAT:   dw 9       ; sectors per FAT
;=============================================================================
;     Begin DOS 3.0 BPB stuff
NumSectorsPerTrack: dw 18             ; sectors per track
NumHeads:           dw 2              ; heads per cylinder
NumHiddenSectors:   dd 0              ; number of hidden sectors
TotalSectors_32:    dd 0              ; total sectors (if its a 32-bit number)
BootDrive:          db 0              ; drive number (0 for now)
Unused:             db 0
BpbVersion:         db 0x29           ; BIOS parameter block version
VolumeSerial:       dd 0              ; volume serial number
VolumeLabel:        db "SYSTEM23   "  ; volume label
FileSystemType:     db "FAT12   "     ; file system type
;=============================================================================
;     End BPB
start:
    cli
    mov [diskNum], dl ; Save disk number
    xor ax, ax
    mov ss, ax
    mov ds, ax
    mov es, ax
    mov sp, 7000h     ; Setup a valid stack before starting
    sti

    mov dh, 20
    mov dl, 80
    call cls

    
    mov si, sec1_msg
    call println
    
    ; Prepare to read disk sectors by setting up ES:BX location
    mov ax, 0
    mov es, ax
    mov bx, 7E00h
    
ReadDisk:
    mov ax, 0             ; Reset floppy controller
    mov dl, 0
    int 13h
    nop

    mov ah, 2             ; Read sectors function
    mov al, 1             ; Read 1 sector
    mov dl, [diskNum]     ; select the disk from earlier
    mov cl, 2             ; sector #2
    mov ch, 0             ; cylinder #0
    mov dh, 0             ; head #0
    int 13h

    ; Show operation status code via teletype:
    mov bh, '0'
    add bh, ah
    mov al, bh    ; BH = '0' + (ReturnCode)

    mov ah, 0eh
    mov cx, 1
    int 10h

.ReadFailure:
    jc .ReadFailure

    jmp 0x0000:stage2





sec1_msg: db "Hello, sector 1!", 0
sec2_msg: db  "Hello, sector 2!", 0

diskNum:  db 0

print:
    push	bx
    push	cx
    push	dx
    push	di

    mov ah, 0Eh
    mov cx, 1
.loop:
    lodsb          ; AL = DS:SI
    cmp al, 0      ; AL == 0?
    jz .done
    int 10h
    jmp .loop
.done:

    pop	di
    pop	dx
    pop	cx
    pop	bx
    ret 

println:
    push ax
    call print
    mov al, 0xD ; CR
    int 10h
    mov al, 0xA ; LF
    int 10h
    pop ax
    ret

;*****************************************************************************
; putchar
;
;   Input:  al = the character
;*****************************************************************************
putchar:
    push ax
    mov ah, 0x0E
    int 10h
    pop ax
    ret

;*****************************************************************************
; cls (clear screen)
;
;   Input: dh = number of rows
;          dl = number of columns
;*****************************************************************************
cls:
    push cx
    push bx
    push ax

    mov bh, COLOR_BLACK  ; Set background color
    shl bh, 4
    add bh, COLOR_WHITE  ; Set foreground color

    mov al, 0
    mov ah, 6    ; Scroll function

    dec dh       ; minus 1 since the row/column numbers are 0-based
    dec dl
 
    xor ch, ch   ; upper row number = 0
    xor cl, cl   ; left column = 0
    int 10h

    ; move cursor to the top left of the screen
    xor bh,bh    ; BH = page 0
    xor dh,dh    ; DH = row 0
    xor dl,dl    ; DL = col 0
    mov ah, 2    
    int 10h

    pop ax
    pop bx
    pop cx
    ret

    
times  0200h - 2 - ($ - $$)  db 0
    db 055h
    db 0AAh

%include "boot1.asm"
