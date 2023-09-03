%include "equates.inc"
%include "macros.asm"
%include "fatfs.inc"
bits 16
org 0x0000
Main:
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
    mov   dh, 25         ; 25 rows
    mov   dl, 80         ; 80 columns
    call  Cls            ; Clear them all...
    call  PrintSystemSummary


 


    
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
%include "string.asm"





PrintSystemSummary:
    pushall

    ; Welcome
    ;=================================================
    mov   si, MsgWelcome
    call  Print
    call  PutCrLf
    call  PutCrLf
    mov   al, ASCII_BELL
    call  Putc

    ; Get lower memory size (int 0x12)
    ;   AX = number of total kilobytes available
    ;=================================================
    mov   si, MsgMemorySize
    call  Print
    int   0x12
    call  PrintNumBase10
    mov   al, 'K'
    call  Putc
    call  PutCrLf

    ; Print Segment locations
    ;=================================================
    call PrintSegmentLocations
    call PutCrLf


    ; Print the RTC time
    ;=================================================
    mov   si, MsgTime
    call  Print
    mov   si, TimeString
    call  GetCurrentTime
    call  Print
    call  PutCrLf
    call  PutCrLf


    ; Print drive parameters
    ;=================================================
    mov   ax, [drvBoot]
    call  PutDriveParams


    ; Draw a nice line to finish off this section
    ;=================================================
    mov   al, '='
    mov   cx, CLI_LIMIT_RIGHT
.DrawLine:
    call  Putc
    loop  .DrawLine
    call  PutCrLf

    popall
    ret


PrintSegmentLocations:
    pushall

    ; Print the Code, Data, and Stack addresses
    ;
    push di               ; Save DI for later
    push si               ; Save SI for later

    mov  ax,4
    call PutIndent
    mov  si,MsgCode
    call Print
    push cs
    pop  ax
    call PrintNumBase16   ; CS
    mov  al,':'
    call Putc
    mov  ax,Main
    call PrintNumBase16
    call PutCrLf

    mov  ax,4
    call PutIndent
    mov  si,MsgDataSrc
    call Print
    push ds
    pop  ax
    call PrintNumBase16   ; DS (SI)
    mov  al,':'
    call Putc
    pop  ax               ; Restore SI
    call PrintNumBase16
    call PutCrLf

    mov  ax,4
    call PutIndent
    mov  si,MsgDataSrc
    call Print
    push ds
    pop  ax
    call PrintNumBase16   ; DS (DI)
    mov  al,':'
    call Putc
    pop  ax               ; Restore DI
    call PrintNumBase16
    call PutCrLf

    mov  ax,4
    call PutIndent
    mov  si,MsgStack
    call Print
    push ss
    pop  ax
    call PrintNumBase16   ; SS
    mov  al,':'
    call Putc
    push sp
    pop  ax
    call PrintNumBase16
    call PutCrLf

    mov  ax,4
    call PutIndent
    mov  si,MsgDiskSegment
    call Print
    mov  ax,SEG_DISKBUFF
    call PrintNumBase16   ; DISKBUFFER
    mov  al,':'
    call Putc
    mov  ax,bx
    call PrintNumBase16
    call PutCrLf

    popall
    ret



;*****************************************************************************
; Dir
;
; Description:
;
;   Poor man's DIR command. Lists all files in the root directory only.
;   File sizes are printed in hex.
;
; Input:
;  
;   DS:SI = 32-byte DirEntry structure
;
; Output:
;
;   None
;
;*****************************************************************************
Dir:
    pushall
    
    ;----
    ; Save the number of sectors to read
    ;----
    mov   word [cs:RemainingSecs], (FAT_RootEntCnt * 32) /  SIZE_SECTOR
    
    ;----
    ; Store the starting sector of the Root Dir
    ;----
    mov   word [cs:CurrentSecNum], FAT_RootDirSecStart
.nextDiskChunk:
    push  SEG_DISKBUFF
    pop   es
    mov   bx, 0                  ; ES:BX = beginning of diskbuffer
    mov   si, 0

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
    mov   [cs:RemainingSecs],cx    ;  Otherwise, save RemainingSecs count


.readEntry:
    push  es
    pop   ds        ; DS = DiskBuffer Segment
    mov   si,bx     ; SI = RootDirectory[bx]
   
    cmp   byte [si], DIR_ALL_FREE
    je    .endOfDirectory
    cmp   byte [si], DIR_FREE
    je    .nextEntry
    cmp   byte [si + OFFSET_DIR_Attr], ATTR_ARCHIVE
    jne   .nextEntry
    
    call  DirEntryPrint


.nextEntry:
    add   bx,32
    ;----
    ; Check if we reached the end of the disk buffer
    ; If so, read another disk buffer worth of sectors
    ;----
    cmp   bx, 0 + (SIZE_DISKBUFFER * SIZE_SECTOR)
    je    .nextDiskChunk
    jmp   .readEntry


.endOfDirectory:

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
;   DS:SI = 32-byte DirEntry structure
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
    
    push  si                 ; Save si
    mov   cx, 8              ; copy 8 bytes for the name
    rep   movsb
    stosb                    ;   space
    mov   cx,3
    rep   movsb              ; copy 3 bytes for the extension
    pop   si                 ; Restore si

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
    mov   ax,word [ds:si + OFFSET_DIR_FileSize]
.rightShift: 
    push  ax
    shr   ax,4
    dec   cx
    jnz  .rightShift
    
    mov   cx,4
.unrollDigits:
    pop   bx
    and   bx,0x000F
    mov   al, byte [cs:HexDigits + bx]
    stosb
    loop  .unrollDigits
    
    push  ds                ; Save DS
    push  es
    pop   ds
    mov   si,DirEntrySummary
    call  Print
    call  PutCrLf
    call  PutCrLf
    pop   ds                ; Restore DS
    
    popall
    ret
    



;*****************************************************************************
; Load Executable
; 
; Description:
;
;   Loads 512-byte executables, by name, into memory at 0000:7C00
;
; Input:  
;
;    DS:SI = executable name
;
; Output:
;
;    AX = CF = 0 if successful
;              1 if error
;
;*****************************************************************************
LoadExecutable:
    push  bx
    push  cx
    push  dx
    push  si
    push  di
    push  ds
    push  es



    ;----
    ; Save the number of sectors to read and number of sectors remaining
    ;----
    mov   word [cs:RemainingSecs], (FAT_RootEntCnt * 32) /  SIZE_SECTOR
    mov   word [cs:CurrentSecNum], FAT_RootDirSecStart
.readDiskChunk:

    push  SEG_DISKBUFF
    pop   es
    mov   bx, 0                    ; ES:BX = beginning of diskbuffer

    xor   dx,dx
    mov   ax,[cs:CurrentSecNum]    ; Set current sector num
    mov   cx,SIZE_DISKBUFFER       ; Set number of sectors to read
    call  DiskRead                 ; Do Disk Read
    cmp   ah, DISK_OK
    jne   .errDiskError

.readOK:
    add   word [cs:CurrentSecNum], SIZE_DISKBUFFER 
    mov   cx,[cs:RemainingSecs]    ; Increment CurrentSecNum by count of sectors we read
    sub   cx,SIZE_DISKBUFFER       ; Decrement RemainingSecs by count of sectors we read
    jz    .errEndOfDirectory       ; If RemainingSecs == 0, then we are done
    mov   [cs:RemainingSecs],cx    ;  Otherwise, save RemainingSecs count


.readEntry:
    cmp   byte [es:bx], DIR_ALL_FREE
    je    .errEndOfDirectory
    cmp   byte [es:bx], DIR_FREE
    je    .nextEntry
    cmp   byte [es:bx + OFFSET_DIR_Attr], ATTR_ARCHIVE
    jne   .nextEntry
    

    ;----
    ; Move the offset of DIR_Name into di
    ;
    ; AX = StrNCompare(di, si, 8)
    ;----
    mov   di,bx
    mov   cx,8
    call  StrNCompare
    cmp   ax,1
    jne   .nextEntry


    ;----
    ; Grab the cluster number and use it to locate the 
    ; first data sector for this file
    ;----
    mov   ax,[es:bx + OFFSET_DIR_FstClusLo]  ; In:  AX = cluster number
    call  DirLocateFirstDataSector           ; Out: AX = starting sector
    test  ax,ax
    jz    .errInvalidSector

    ;----
    ; Hurray, we found the file data!
    ;----
    push  cs
    pop   ds                                 ; Prepare DS for printing messages
    mov   si,MsgFileFound
    call  Print
    call  PrintNumBase10
    call  PutCrLf

    ;----
    ; Load the file into memory (1 sector of it anyway)
    ;----
    push  SEG_BOOT
    pop   es
    mov   bx,0     ; Set ES:BX to the boot sector
    mov   cx,1     ; read 1 sector
    ;              ; DL = drive to read from (future: make this a parameter!)
    call  DiskRead
    cmp   ah,DISK_OK
    jne   .errDiskError

    ;----
    ; File loaded successfully
    ;----
    mov   si,MsgFileLoaded
    call  Println
    mov   ax,0
    jmp   .done



.nextEntry:
    add   bx,32
    ;----
    ; Check if we reached the end of the disk buffer
    ; If so, read another disk buffer worth of sectors
    ;----
    cmp   bx, (SIZE_DISKBUFFER * SIZE_SECTOR)
    je    .readDiskChunk
    jmp   .readEntry



    ;----
    ; Error cases 
    ;
    ; All should set AX to something other than 0
    ;----
.errDiskError:
    call  DiskPrintStatus
    mov   ax,1
    jmp   .done

.errInvalidSector:
    push  cs
    pop   ds
    mov   si,MsgFileInvalidSec
    call  Println
    mov   ax,2
    jmp   .done

.errEndOfDirectory:
    push  cs
    pop   ds
    mov   si,MsgFileNotFound
    call  Println
    mov   ax,3


.done:
    test  ax,ax      ; Set flags appropriately

    pop   es
    pop   ds
    pop   di
    pop   si
    pop   dx
    pop   cx
    pop   bx
    ret
SavedSegment:  dw 0



;*****************************************************************************
;
; DirLocateFirstDataSector
;
;   This function locates the starting data sector given a cluster number N
;
;   FirstSectorOfCluster = ((N-2) * BPB_SecPerClus) + FirstDataSec
;
; Limitations: 
;
;   Input only takes the lower 16-bits of cluster N (DIR_FstClusLo), so for
;   cluster numbers greater than 0xFFFF, this does not work.
;
; Input:
;   AX = cluster number N
;
; Output:
;
;   AX = the sector number
;      = 0, if error, or the entry is a LFN so it has no cluster
;
;*****************************************************************************
DirLocateFirstDataSector:
    push  dx
    push  bx
    
    xor   dx,dx
    sub   ax,2                    ; N - 2
    js    .InvalidCluster         ; Too large, or the sub caused a rollover
    mov   bx,FAT_SecPerClus
    mul   bx                      ; * SecPerClus
    add   ax,FAT_FirstDataSector  ; += FirstDataSec
    test  dx,dx
    jnz   .InvalidCluster         ; Sector number exceeded 16 bits :(
    jmp   .Done                   ; Sector number is in AX

.InvalidCluster:
    mov   ax,0
    jmp  .Done

.Done:

    pop  bx
    pop  dx
    ret



;*****************************************************************************
; Print out drive parameters for a selected drive
;  
; Input:
;
;  AL = drive number
;
;*****************************************************************************
PutDriveParams:
    pushall

    and   ax,0xff                ; drive number in the lower 8 bits
    mov   si, MsgDriveParams
    call  Print
    call  PutCrLf

    mov   si, MsgDriveParams1
    call  Print
    
    call  PrintNumBase16
    call  PutCrLf

    call  GetDriveParams

    ; AX = cylinders
    ; BX = secspertrack
    ; CX = heads
    mov   si, MsgDriveParams2     ; 1. AX = Number of cylinders
    call  Print
    call  PrintNumBase10
    call  PutCrLf

    mov   ax,cx
    mov   si, MsgDriveParams3     ; 2. CX = Number of sides/heads
    call  Print
    call  PrintNumBase10
    call  PutCrLf

    mov   ax,bx
    mov   si, MsgDriveParams4     ; 3. BX = Sectors per track
    call  Print
    call  PrintNumBase10
    call  PutCrLf

.error:
    call  PutCrLf

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
    push es

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
    jne  .command5
    jmp  .doDir

.command5:
    cmp   al,'l'     ; SI = "ld program"
    jne  .badCommand
    lodsb 
    cmp   al,'d'     ; SI = "d program"
    jne  .badCommand
    lodsb 
    cmp   al,' '     ; SI = " program"
    jne  .badCommand

    jmp  .doLoad


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

.doLoad:

    call LoadExecutable  ; LoadExecutable(ds:si)
    jnz  .done

    xor  ax,ax
    int  16h


    push 0
    push 0x7C00
    retf
    jmp .done


.badCommand:
    mov   si, MsgError
    call  Println

.done:

    pop es
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
    cmp    byte [cs:kbd_buffer_idx], 0
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
    mov   bl, [cs:kbd_buffer_idx]  ; BL = kbd_buffer_idx
    cmp   bl, SIZE_KEY_BUFFER
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
    push es

    push cs
    pop  es                           ; Switch to code segment
    mov byte [cs:kbd_buffer_idx], 0   ; Reset keyboard buffer index
    mov cx, SIZE_KEY_BUFFER

    mov di, kbd_buffer
    mov al, 0                         ; Fill with spaces
    cld
    repnz stosb

    pop es
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
    mov    bl, [cs:kbd_buffer_idx]
    dec    bl 
    mov   [cs:kbd_buffer_idx], bl

    ; Replace the character at this position with null
    mov    al, 0
    lea    si, [cs:kbd_buffer + bx]
    mov   [cs:si], al

    pop    ax
    pop    bx
    ret

; AL = character to insert
KeyBufferInsert:
    push   di
    push   bx

    mov    bl, [cs:kbd_buffer_idx]  ; BL = kbd_buffer_idx
    lea    di, cs:kbd_buffer
    add    di, bx
    mov   [cs:di], al               ; Store the key pressed
    inc    bl                       ; kbd_buffer_idx +=1 
    mov   [cs:kbd_buffer_idx], bl

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

    mov  cx, SIZE_KEY_BUFFER
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

    ; Write the buffer to LBA where the file data is located
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





kbd_buffer:     times SIZE_KEY_BUFFER  db 0
kbd_buffer_idx:                        db 0


drvBoot:             db 0


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

MsgStack:            db "  stack ",0
MsgDataSrc:          db "   data ",0
MsgCode:             db "   code ",0
MsgDiskSegment:      db "diskbuf ",0

TimeString:          db "00:00:00",0

PromptString:        db "@: ",0


MsgFileLoaded:       db "File loaded",0
MsgFileFound:        db "File found - Data sector ",0
MsgFileNotFound:     db "File not found!",0
MsgFileInvalidSec:   db "File data resides at an invalid sector!",0



;
; File/Directory Stuff
;
CurrentSecNum:       dw 0
RemainingSecs:       dw 0
HexDigits:           db "0123456789ABCDEF"


SIZE_DIR_ENTRY_SUMMARY    EQU   32
DirEntrySummary:          times SIZE_DIR_ENTRY_SUMMARY db 0




times (SIZE_SYSTEM * SIZE_SECTOR) - ($ - $$) db 0
