%include "equates.inc"
%include "macros.asm"
%include "fatfs.inc"

org 0x0000
Begin:
    ; First, make sure DS = CS = ES
    ;
    mov   ax, SEG_SYSTEM
    mov   es, ax
    mov   ds, ax
    
    ; Next, lets save that drive number from earlier
    ;
    mov [drvBoot], dl


    mov   ah, COLOR_BLACK
    mov   al, COLOR_LIGHT_GREY
    mov   dh, 25         ; 20 rows
    mov   dl, 80         ; 80 columns
    call  Cls            ; Clear them all...

    mov   si, MsgWelcome
    call  Print
 
    call  PutCrLf
    call  PutCrLf
    mov   ah, func_tty
    mov   al, ASCII_BELL
    int   10h
    
    mov   si, MsgMemorySize
    call  Print

    ; Get lower memory size
    ;   AX will be the number of total kilobytes available
    int   0x12            
    call  PrintNumBase10
    mov   al, 'K'
    call  Putc
    call  PutCrLf

    ; Print the RTC time
    ;
    mov   si, MsgTime
    call  Print
    mov   si, TimeString
    call  GetCurrentTime
    call  Print
    call  PutCrLf
    call  PutCrLf

    ; Print drive parameters
    ;
    mov   ax, [drvBoot]
    call  PutDriveParams


    ; Draw a nice line to finish off this section
    ;
    mov   al, '='
    mov   cx, CLI_LIMIT_RIGHT
.DrawLine:
    call  Putc
    dec   cx
    test  cx,cx
    jnz   .DrawLine
    call  PutCrLf    



    
.ReadLoop:
    mov   si,PromptString
    call  Print
    call  GetLine
    call  ProcessKeyBuffer
    call  ClearKeyBuffer
    jmp   .ReadLoop

%include "console.asm"
%include "graphics.asm"
%include "disk.asm"


Dir:
    pushall

    mov   ax, SEG_DISKBUFF
    mov   es, ax
    mov   bx, 0              ; ES:BX = diskbuff location
    mov   si, 0              ; DS:SI = diskbuff location too
      
    
    ;----
    ; Save the number of sectors to read
    ;----
    mov  word [cs:RemainingSecs], (FAT16_RootEntCnt * 32) /  SIZE_SECTOR
    

    ;----
    ; Store the starting sector of the Root Dir
    ;----
    mov   word [cs:CurrentSecNum], FAT16_RootDirSecStart
.nextDiskChunk:

    xor   dx,dx
    mov   ax,[cs:CurrentSecNum]  ; Set current sector num
    mov   cx,SIZE_DISKBUFFER     ; Set number of sectors to read
    call  DiskRead               ; Do Disk Read
    cmp   ah, DISK_OK
    je    .readOK
    call  DiskPrintStatus
    jmp   .endOfDirectory
    

.readOK:

    add   word [cs:CurrentSecNum], SIZE_DISKBUFFER 
    mov   cx,[cs:RemainingSecs]    ; Increment CurrentSecNum by count of sectors we read
    sub   cx,SIZE_DISKBUFFER       ; Decrement RemainingSecs by count of sectors we read
    jz    .endOfDirectory          ; If RemainingSecs == 0, then we are done
    mov   [cs:RemainingSecs],cx    ;   Otherwise, save RemainingSecs count


    push  es
    pop   ds
    mov   si,0     ; Reset SI to beginning of segment
.readEntry:

    cmp   byte [si], 0
    je    .endOfDirectory
    cmp   byte [si], 0xE5
    je    .nextEntry

    call  DirEntryRead
.nextEntry:
    add   si,32
    ;----
    ; Check if we reached the end of the disk buffer
    ; If so, read another 2 blocks
    ;----
    cmp   si, 0 + (SIZE_DISKBUFFER * SIZE_SECTOR)
    je    .nextDiskChunk
    jmp   .readEntry


.endOfDirectory:

    popall
    ret



;*****************************************************************************
; Dir Read Entry
;
; Description:
;
;   Reads the information out of a dir entry and puts it in a buffer to be
;   printed out afterwards
;
; Input:   DS:SI = pointer to dir entry
;
; Output:  ES:DI = buffer with information
; 
;*****************************************************************************
DirEntryRead:
    ;----
    ; Read first 11 bytes for file name
    ; If first byte is one of the markers (0xE5, 0x00, etc) skip it.
    ;----
    pushall

    ;----
    ; Set up output buffer to receive the file information
    ;----
    push  cs
    pop   es
    mov   di, DirEntryReal

    ;----
    ; Read in one 32-byte entry
    ;----
    mov   cx, SIZE_DIR_ENTRY
    rep   movsb

    
    ;----
    ; Print out whatever is inside the buffer
    ;----
    push  cs
    pop   ds
    mov   si, DirEntryReal
    call  DirEntryPrint

    popall
    ret
    



;*****************************************************************************
; DirEntryPrint
;
; Description:
;
;   Pulls out the contents of a directory entry in DS:SI and prints them out 
;   in one nicely-formatted string
;
; Input:    
;  
;   DS:SI = real Directory Entry
;
; Output:
;
;   None
;
;*****************************************************************************
DirEntryPrint:
    pushall
    
    push  cs
    pop   es
    mov   di,DirEntrySummary ; ES:DI = Dir Entry summary buffer
    mov   al,'-'
    stosb
    stosb
    mov   al,' '
    stosb
    
    mov   cx, 11             ; 11 bytes for the name
    rep   movsb              ; copy it over to DirEntrySummary
    
    mov   ax, ' '
    stosb
    stosb 
    stosb
    mov   al,'s'
    stosb
    mov   al,'i'
    stosb
    mov   al,'z'
    stosb
    mov   al,'e'
    stosb
    mov   al, ':'
    stosb
    mov   al, ' '
    stosb
.putSizeInHex:               ; Print the file size in bytes (in hex for now)
    mov   cx,4               ; CX = Number of 4-bit shifts to perform
    mov   si,DirEntryReal+DIR_FileSize
    mov   ax,word [si]
.rightShift: 
    push  ax
    shr   ax,4
    dec   cx
    jnz  .rightShift
    
    mov   cx,4
.unrollDigits:
    pop   bx
    and   bx,0x000F
    mov   al, byte [HexDigits + bx]
    stosb
    dec   cx
    jnz   .unrollDigits
    
    
    mov   si,DirEntrySummary
    call  Print
    call  PutCrLf
    call  PutCrLf
    
    popall
    ret
    



;*****************************************************************************
; Load Executable
; 
; Description:
;
;   Loads 128-sector executables into memory.
;
; Input:  
;
;      AX = Start sector of the executable on disk
;   ES:BX = Location in memory where to load
;
;
; Output:
;
;      AX = 0 if successful
;           1 if error
;
;*****************************************************************************
LoadExecutable:
    push  cx
    push  dx

    mov   ax, SEG_DISKBUFF
    mov   es, ax
    mov   bx, 100h


    xor   dx,dx
    mov   ax, 78
    mov   cx, 128
    call  DiskRead
    cmp   ah, DISK_OK
    je    .LoadSuccess


.LoadSuccess:
    pop   dx
    pop   cx
    ret




;*****************************************************************************
; Print out drive parameters for a selected drive
;  
; Input:
;
;  AL = drive number
;
; Parameters are stored in the following memory locations:
;
;  drvCylinders
;  drvSecsPerTrack
;  drvHeads
;
;*****************************************************************************
PutDriveParams:
    pushall

    push ax
    mov  si, MsgDriveParams
    call Print
    call PutCrLf

    mov si, MsgDriveParams1
    call Print
    call PrintNumBase10
    call PutCrLf


    
    ;---
    ; BIOS function 13/8 - Get drive parameters
    ;
    ; Input: 
    ; DL = Drive Number
    ;
    ; Return:
    ; CH = Cylinders 
    ; CL = SecsPerTrack
    ; DH = Sides/Heads
    ; DL = drives attached 
    ;
    ;---
    pop dx
    mov ah, 0x8 
    int 13h
    jc .error

    push cx             ; save CL=SecsPerTrack
    push dx             ; save DH=Sides

    ;---
    ; The 10-bit number of cylinders is stored in both CH and CL:
    ;           LLLLLLLL HHxxxxxx
    ;               ch       cl
    ;
    ; to print the number, we need to store the following in AX:
    ;  
    ;      AX = 000000HH LLLLLLLL
    ;
    ;---
    xor ax, ax
    add al, ch 
    and cx, 0b11000000
    shl cx, 2
    add ax, cx                 ; AX = CH + ((CL & 0xC0) << 2)
    inc ax
    mov [drvCylinders], ax
    mov si, MsgDriveParams2    ; 1 Number of cylinders
    call Print
    call PrintNumBase10
    call PutCrLf

    mov si, MsgDriveParams3    ; 2 Number of sides/heads (0-based)
    call Print
    pop ax                     ; restore DH=sides
    shr ax, 8
    inc ax
    mov [drvHeads], ax
    call PrintNumBase10
    call PutCrLf

    mov si, MsgDriveParams4    ; 3 Sectors per track
    call Print
    pop ax                     ; restore CL=SecsPerTrack
    and ax, 0x3f
    mov [drvSecsPerTrack], ax
    call PrintNumBase10
    call PutCrLf

.error:
    call PutCrLf

    popall
    ret










;*****************************************************************************
; BCD to Decimal
;
; Input:  BCD byte in AL
;
; Output: AH = 10s place digit
;         AL = 1s place digit
;
;*****************************************************************************
BcdToDec:
    mov  ah, al
    and  al, 0x0F   ; Keep lower nibble in AL
    shr  ah, 4      ; Keep top nibble in AH
    ret


;*****************************************************************************
; Get Current RTC time string
;
; Input:   DS:SI = Array to hold time string
;
; Output:  Time stored in TimeString
;
;*****************************************************************************
GetCurrentTime:
    pusha
    mov  ah, 02h
    int  1Ah            ; BIOS read RTC function
    jc  .error

    mov  al, ch         ; AL = Hours
    call BcdToDec
    add  al, '0'
    add  ah, '0'
    mov [si + 0], ah
    mov [si + 1], al
    mov [si + 3], byte ':'

    mov  al, cl         ; AL = Minutes
    call BcdToDec
    add  al, '0'
    add  ah, '0'
    mov [si + 3], ah
    mov [si + 4], al
    mov [si + 5], byte ':'

    mov  al, dh         ; AL = seconds
    call BcdToDec
    add  al, '0'
    add  ah, '0'
    mov [si + 6], ah
    mov [si + 7], al
.error:
    popa
    ret





;*****************************************************************************
; Do command, if there is one
;
;*****************************************************************************
ProcessKeyBuffer:
    pusha

    mov si, kbd_buffer
    lodsb

.isItCommand:
    cmp  al, ' '
    je  .done     ; Nope, not a command

    test al,al
    jz  .done
    

    ; Write command (is there anything to write in the keyboard buffer?)
.command1:
    cmp  al, 'w'
    jne  .command2
    jmp  .doWrite


    ; Bell command
.command2:
    cmp  al, 'b'
    jne  .command3
    jmp  .doBell

    ; VGA test
.command3:
    cmp   al, 'v'
    jne  .command4
    jmp  .doVGA

.command4:
    cmp al, 'd'
    jne  .badCommand
    jmp  .doDir


.doWrite:
    mov   si, MsgDriveWrite
    call  Println
    call  WriteKeyBufferToDisk  ; Write the keybuffer to disk
    cmp   ah, DISK_OK
    je    .writeOK
    call  DiskPrintStatus       ; Print Drive status if error
.writeOK:
    jmp   .done

.doBell:
    mov   al, ASCII_BELL
    call  Putc
    jmp   .done

.doVGA:
    call VgaTest
    jmp .done

.doDir:
    call Dir
    jmp .done

.badCommand:
    mov   si, MsgError
    call  Println

.done:

    popa
    ret


;*****************************************************************************
; GetLine
;
;*****************************************************************************
GetLine:
    push   ax
    push   bx
    push   di
    push   cx

.getKey:
    mov ah, 0
    int 16h

    ;------------------------------
    ; ENTER/RETURN
    ;------------------------------
.k1:
    cmp   ax, KEY_RETURN
    jne   .k2
    call  PutCrLf      ; Advance the line
    jmp   .done

    ;------------------------------
    ; Backspace
    ;------------------------------
.k2:
    cmp   ax, KEY_BACKSPACE
    jne   .k3

    xor   bx,bx     ; Get cursor position...
    mov   ah, 3
    int   10h

    cmp    dl,CLI_LIMIT_LEFT
    je    .getKey
    cmp    byte [kbd_buffer_idx], 0
    je    .getKey

    dec   dl        ; Move back 1 space...
    mov   ah, 2
    int   10h

    mov   cx, 1     ; And put a null character
    mov   al, 0
    mov   ah, 0xA
    int   10h
    call  KeyBufferRemove
    jmp   .getKey

    ;------------------------------
    ; Any other key was pressed
    ;------------------------------
.k3:
    xor   bx, bx
    mov   bl, [kbd_buffer_idx]  ; BL = kbd_buffer_idx
    cmp   bl, KEY_BUFFER_SIZE
    je    .getKey               ; kbd_buffer_idx == kbd_buffer_size?


    ;------------------------------
    ; Ensure that AL is printable
    ;------------------------------
    cmp    al, 31
    jle    .getKey
    cmp    al, 127
    jge    .getKey
    call   KeyBufferInsert     ; save the character
    call   Putc                ; print the character

    jmp    .getKey             ; Get the next key

.done:
    pop   cx
    pop   di
    pop   bx
    pop   ax
    ret


;*****************************************************************************
; Clear Key Buffer
;
;*****************************************************************************
ClearKeyBuffer:
    push ax
    push cx
    push si
    push di

    mov byte [kbd_buffer_idx], 0   ; Reset keyboard buffer index
    mov cx, KEY_BUFFER_SIZE

    mov di, kbd_buffer
    mov al, ' '                    ; Fill with spaces
    cld
    repnz stosb

    pop di
    pop si
    pop cx
    pop ax
    ret


KeyBufferRemove:
    push   bx
    push   ax

    ; Decrement the current buffer index by 1
    xor    bx,bx
    mov    bl, [kbd_buffer_idx]
    dec    bl 
    mov   [kbd_buffer_idx], bl

    ; Replace the character at this position with null
    mov    al, 0
    lea    si, [kbd_buffer + bx]
    mov   [si], al

    pop    ax
    pop    bx
    ret

; AL = character to insert
KeyBufferInsert:
    push   di
    push   bx

    mov    bl, [kbd_buffer_idx]  ; BL = kbd_buffer_idx
    lea    di, kbd_buffer
    add    di, bx
    mov   [di], al               ; Store the key pressed
    inc    bl                    ; kbd_buffer_idx +=1 
    mov   [kbd_buffer_idx], bl

    pop    bx
    pop    di
    ret



;*****************************************************************************
; Toggle between graphics or text mode
;
;*****************************************************************************
ToggleGraphics:
    push ax
    mov  al, [VgaMode]
    cmp  al, VGA_MODE_GRAPHICS
    je  .to_text_mode
.to_graphics_mode:
    mov  al, VGA_MODE_GRAPHICS
    jmp  .done
.to_text_mode:
    mov  al, VGA_MODE_TEXT
    jmp  .done

.done:
    mov  [VgaMode], al
    mov  ah, 0
    int  10h
    pop  ax
    ret



;*****************************************************************************
; (TEST) write the keyboard buffer to the disk buffer then write the 
;        disk buffer to the disk
;
;*****************************************************************************
CopyKeyBufferToDiskBuffer:
    push  ax
    push  cx
    push  di
    push  si
    push  es
    push  ds

    mov  ax, SEG_DISKBUFF
    mov  es, ax
    mov  di, 0         ; ES:DI = &DISKBUFF

    push cs
    pop  ds            ; DS = CS

    mov  cx, KEY_BUFFER_SIZE
    lea  si, kbd_buffer

    rep  movsb         ; copy byte from ds:[si] to es:[di] until cx=0

    pop  ds
    pop  es
    pop  si
    pop  di
    pop  cx
    pop  ax
    ret

;*****************************************************************************
; (TEST) write the contents of ES:BX to disk
;
; Output:
;
;   AH = status of write
;
;*****************************************************************************
WriteKeyBufferToDisk:
    push dx
    push es

    call CopyKeyBufferToDiskBuffer

    mov ax, SEG_DISKBUFF
    mov es, ax
    mov bx, 0

    ; Write the buffer to LBA 36, where the file data is located
    ;   FAT12, LBA = 36
    ;   FAT16, LBA = 78

    xor dx, dx
    mov ax, 78        ; Start at sector 78
    mov cx, 1         ; Write 1 sector
    call DiskWrite
                    ; Leave status code in AX register
    

    pop es 
    pop dx
    ret





kbd_buffer:     times KEY_BUFFER_SIZE  db 0
kbd_buffer_idx:                        db 0


drvBoot:             db 0
drvSecsPerTrack:     db 0
drvCylinders:        dw 0
drvHeads:            dw 0




TestStructure:       db 41h, 42h, 43h, 44h,45h, 0

MsgTime:             db "RTC Time: ", 0
MsgMemorySize:       db "Lower memory available: ", 0
MsgDriveParams:      db "Boot drive geometry ",0
MsgDriveParams1:     db "  Drive Number: ",0
MsgDriveParams2:     db "     Cylinders: ",0
MsgDriveParams3:     db "         Sides: ",0
MsgDriveParams4:     db "  SecsPerTrack: ",0
MsgError:            db "An error has occurred",0
MsgDriveError:       db "Drive status: ",0

MsgDriveWrite:       db "Writing to disk...", 0
MsgWelcome:          db "Welcome to System23!", 0

TimeString:          db "  :  :  ",0

PromptString:        db "@: ",0

;
; File/Directory Stuff
;
CurrentSecNum:       dw 0
RemainingSecs:       dw 0
HexDigits:           db "0123456789ABCDEF"


SIZE_DIR_ENTRY_SUMMARY    EQU   32
DirEntrySummary:          times SIZE_DIR_ENTRY_SUMMARY db 0
DirEntryReal:
istruc DirEntry
    at DIR_Name,          db "           "
    at DIR_Atrr,          db 0x00
    at DIR_NTRes,         db 0x00
    at DIR_CrtTimeTenth,  db 0x00
    at DIR_CrtTime,       dw 0x0000
    at DIR_CrtDate,       dw 0x0000
    at DIR_LstAccDate,    dw 0x0000
    at DIR_FstClusHi,     dw 0x0000
    at DIR_WrtTime,       dw 0x0000
    at DIR_WrtDate,       dw 0x0000
    at DIR_FstClusLo,     dw 0x0000
    at DIR_FileSize,      dd 0x00000000
iend



times (SIZE_SYSTEM * SIZE_SECTOR) - ($ - $$) db 0
