%include "equates.inc"

; Loaded at 0x7C00
org 7C00h
    jmp start
    nop

BS_OEMName:          db "JOM     "
BPB_BytesPerSec:     dw FAT_BytesPerSec
BPB_SecPerClus:      db FAT_SecPerClus
BPB_RsvdSecCnt:      dw FAT_RsvdSecCnt
BPB_NumFATs:         db FAT_NumFATs
BPB_RootEntCnt:      dw FAT_RootEntCnt
BPB_TotSec16:        dw FAT_TotSec16
BPB_Media:           db FAT_Media
BPB_FATsz16:         dw FAT_FATsz16
BPB_SecPerTrk:       dw FAT_SecPerTrk
BPB_NumHeads:        dw FAT_NumHeads
BPB_HiddSec:         dd FAT_HiddSec
BPB_TotSec32:        dd FAT_TotSec32
BS_DrvNum:           db FAT_DrvNum
BS_Reserved1:        db 0
BS_BootSig:          db 0x29
BS_VolID:            dd 0xDEADCAFE
BS_VolLab:           db "SYSTEM23   "
BS_FilSysType:       db "FAT16   "


start:
    cli
    mov ax, SEG_BOOT
    mov ss, ax
    mov ds, ax
    mov es, ax
    mov sp, 4096          ; Setup a valid stack before starting
    sti

    mov [DriveNum], dl    ; Save disk number
    
    ; Prepare to read disk sectors by setting up ES:BX location
    mov ax, SEG_SYSTEM
    mov es, ax
    mov bx, 0
    


    ; Start reading in the rest of the system image
ReadDisk:
    mov ax, 0             ; Reset floppy controller
    mov dl, 0
    int 13h
    nop

    mov ah, 2             ; Read sectors function
    mov al, SIZE_SYSTEM
    mov dl, [DriveNum]    ; select the disk from earlier
    mov cl, 2             ; sector #2
    mov ch, 0             ; cylinder #0
    mov dh, 0             ; head #0
    int 13h

    mov [DriveStatus], ah ; save the operation status
    mov si, msg_read_status
    call init_print
    mov ah, [DriveStatus]

    ; Show operation status code via teletype:
    mov bh, '0'
    add bh, ah
    mov al, bh    ; BH = '0' + (ReturnCode)

    mov ah, 0eh
    mov cx, 1
    int 10h


    mov ah, [DriveStatus]
    cmp ah, 0
    je read_success
read_failure:
    int 16h
    int 19h

read_success:
    mov dl, [DriveNum]      ; Keep drive number in DL for next stage
    jmp SEG_SYSTEM:0x0000



DriveNum:          db 1
DriveStatus:       db 1
msg_read_status:   db "INT 13 read status: ", 0


init_print:
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

init_println:
    push ax
    call init_print
    mov al, ASCII_CR
    int 10h
    mov al, ASCII_LF
    int 10h
    pop ax
    ret


times  0200h - 2 - ($ - $$)  db 0
    db 055h
    db 0AAh
