%include "equates.inc"

; Loaded at 0x7C00
org 7C00h
    jmp start
    nop
;=============================================================================
;     Begin DOS 2.0 BPB 
BS_OEMName:          db "JOM     "
BPB_BytesPerSec:     dw 512
BPB_SecPerClus:      db 1
BPB_RsvdSecCnt:      dw 1+SYS_SIZE_SECTORS
BPB_NumFATs:         db 2
BPB_RootEntCnt:      dw 224
BPB_TotSec16:        dw 2880
BPB_Media:           db 0xF0
BPB_FATsz16:         dw 9
;=============================================================================
;     Begin DOS 3.0 BPB stuff
BPB_SecPerTrk:      dw 18
BPB_NumHeads:       dw 2
BPB_HiddSec:        dd 0
BPB_TotSec32:       dd 0
BS_DrvNum:          db 0
BS_Reserved1:       db 0
BS_BootSig:         db 0x29
BS_VolID:           dd 0xDEADCAFE
BS_VolLab:          db "SYSTEM23   "
BS_FilSysType:      db "FAT12   "
;=============================================================================
;     End BPB
start:
    cli
    xor ax, ax
    mov ss, ax
    mov ds, ax
    mov es, ax
    mov sp, STACK_SEG ; Setup a valid stack before starting
    sti

    mov [disk_num], dl ; Save disk number
    
    ; Prepare to read disk sectors by setting up ES:BX location
    mov ax, 0
    mov es, ax
    mov bx, SYSTEM_SEG
    


    ; Start reading in the rest of the system image
ReadDisk:
    mov ax, 0             ; Reset floppy controller
    mov dl, 0
    int 13h
    nop

    mov ah, 2             ; Read sectors function
    mov al, SYS_SIZE_SECTORS
    mov dl, [disk_num]    ; select the disk from earlier
    mov cl, 2             ; sector #2
    mov ch, 0             ; cylinder #0
    mov dh, 0             ; head #0
    int 13h

    mov [disk_status], ah ; save the operation status
    mov si, msg_read_status
    call init_print
    mov ah, [disk_status]

    ; Show operation status code via teletype:
    mov bh, '0'
    add bh, ah
    mov al, bh    ; BH = '0' + (ReturnCode)

    mov ah, 0eh
    mov cx, 1
    int 10h


    mov ah, [disk_status]
    cmp ah, 0
    je read_success
read_failure:
    jmp read_failure

read_success:
    jmp 0x0000:SYSTEM_SEG




msg_read_status:  db "INT 13 read status: ", 0


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


ABSOLUTE boot_drive
    disk_num:    resb 1
    disk_status: resb 1