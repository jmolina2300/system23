%include "equates.inc"

; Loaded at 0x7C00
org 7C00h
    jmp start
    nop
;=============================================================================
;     Begin DOS 2.0 BPB 
db 0,0,0,0,0,0,0,0
BytesPerSector:     dw 512     ; sector size in bytes
SectorsPerCluster:  db 1       ; sectors per cluster
ReservedSectors:    dw 1+SYS_SIZE_SECTORS  ; number of reserved sectors
NumFATs:            db 2       ; number of FATs 
NumDirEntries:      dw 224     ; number of entries in root directory
TotalSectors_16:    dw 2880    ; total sectors (if number fits in 16 bits)
MediaByte:          db 0xF0    ; media description byte
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
VolumeSerial:       dd 0xDEADCAFE     ; volume serial number
VolumeLabel:        db "SYSTEM23   "  ; volume label
FileSystemType:     db "FAT12   "     ; file system type
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




msg_read_status:  db "INT 13 read status: ",0
disk_num:         db 0
disk_status:      db 0


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

