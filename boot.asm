; Loaded at 0x7C00
org 7C00h
	jmp 0x0000:start
;=============================================================================
;     Begin DOS 2.0 BPB 
db 0  
db 0
db 0
db 0
db 0
db 0
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




sec1_msg: db "Hello, sector 1!", 0
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

start:  
    mov [diskNum], dl ; Save disk number
    ;cli              
    xor ax, ax
    mov ss, ax
    mov ds, ax
    mov es, ax
    mov sp, 7000h     ; Setup a valid stack before starting
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    
	mov cx, 1
	xor dx, dx
    
    
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

    
times  0200h - 2 - ($ - $$)  db 0
    db 055h
    db 0AAh

; 7E00h from here on out
stage2:
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    jmp short start_stage2

sec2_msg: db  "Hello, sector 2!", 0


start_stage2:
    
    mov ah, 0Eh
    mov cx, 1
    mov al, 07h    ; Bell code
    int 10h
    
    mov al, 0xD    ; CR
    int 10h
    mov al, 0xA    ; LF
    int 10h
    
    mov si, sec2_msg
    call print
    

    
very_end:
    jmp very_end
    