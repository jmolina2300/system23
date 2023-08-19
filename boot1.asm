%include "equates.inc"


org SYSTEM_SEG
Begin:
    mov   ah, COLOR_BLACK
    mov   al, COLOR_LIGHT_GREY
    mov   dh, 25         ; 20 rows
    mov   dl, 80         ; 80 columns
    call  Cls           ; Clear them all...

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
    mov   ax, [boot_drive]
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
    mov   si, PromptString
    call  Print
    call  GetLine
    call  ProcessKeyBuffer
    call  ClearKeyBuffer
    jmp   .ReadLoop





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
    and ax, 0xff
    mov [drvSecsPerTrack], ax
    call PrintNumBase10
    call PutCrLf

.error:
    call PutCrLf
    ret




;*****************************************************************************
; VGA Clear - clears the vga buffer with a specified color
;
; AL = pixel color
;
;*****************************************************************************
VgaClear:
    pusha
    push es

    xor bx,bx
    ; Load ES with the VGA memory segment
    mov ax, VGA_MEMORY_SEG
    mov es, ax
    xor ax, ax
    mov al, [PixelColor]    ; AL = pixel color
.clear_loop:
    mov [es:bx], al         ; vgamem[bx] = pixel
    inc bx
    cmp bx, 64000
    jne .clear_loop
    pop es
    popa
    ret


;*****************************************************************************
; VGA Test
;
;*****************************************************************************
VgaTest:
    pusha
    mov al, 13h
    mov ah, 0
    int 10h


    ; Set bg color
    mov ah, 0x0B
    mov bh, 0
    mov bl, COLOR_BLUE
    int 10h


    mov bh, 0      ; page 0
    mov al, COLOR_LIGHT_GREEN
    xor si, si
    xor di, di
    xor bl, bl
draw_loop:
    mov cx, si     ; CX = cols
    mov dx, di     ; DX = rows
    call PutPixel


    inc si
    mov bl, byte [si]     ; BL = SI
    and bl, 0x20
    cmp bl, 0x20
    jne .skip
    inc di
.skip:
    cmp si, 500
    jne draw_loop

draw_loop2:
    mov cx, si     ; CX = cols
    mov dx, di     ; DX = rows
    call PutPixel

    dec si
    mov bl, byte [si]     ; BL = SI
    and bl, 0x20
    cmp bl, 0x20
    jne .skip
    inc di
.skip:
    cmp si, 0
    jne draw_loop2

    xor ax,ax
    int 16h

    mov al, VGA_MODE_TEXT
    mov ah, 0
    int 10h
    popa
    ret



;*****************************************************************************
; Print a 0-terminated string
;
;*****************************************************************************
Print:
    push    ax
    push	bx
    push	cx
    push	dx
    push	di
    push    si

    mov ah, 0Eh
    mov cx, 1
.loop:
    lodsb          ; AL = DS:SI
    test al, al    ; AL == 0?
    jz .done
    int 10h
    jmp .loop
.done:

    pop si
    pop	di
    pop	dx
    pop	cx
    pop	bx
    pop ax
    ret


;*****************************************************************************
; Print a 0-terminated string with a newline
;
;
;*****************************************************************************
Println:
    call Print
    push ax
    mov ah, func_tty
    mov al, ASCII_CR
    int 10h
    mov al, ASCII_LF
    int 10h
    pop ax
    ret

;*****************************************************************************
; Putc
;
;   Input:  al = the character
;*****************************************************************************
Putc:
    push ax
    mov ah, 0x0E
    int 10h
    pop ax
    ret

;*****************************************************************************
; Cls (clear screen)
;
;   Input: DH = number of rows
;          DL = number of columns
;          AH = BG color
;          AL = FG color
;*****************************************************************************
Cls:
    push cx
    push bx
    push ax

    mov bh, ah   ; Set background color
    shl bh, 4
    add bh, al   ; Set foreground color
    mov al, 0
    mov ah, 6    ; Scroll function
    dec dh       ; row and col numbers minus 1 since the numbers are 0-based
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
; Write Graphics Pixel
;
; AH = 0Ch
; BH = page number
; AL = pixel color
;   if bit 7 set, value is XOR'ed onto screen except in 256-color modes
; CX = column
; DX = row
;*****************************************************************************
PutPixel:
    push ax
    push bx
    mov bx, 0      ; page = 0
    mov ah, 0x0C   ; write pixel
    int 10h
    pop bx
    pop ax
    ret


;*****************************************************************************
; Do command, if there is one
;
;*****************************************************************************
ProcessKeyBuffer:
    pusha
    push ds

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
    jne  .badCommand
    jmp  .doVGA


.doWrite:
    call  FillDiskBuffer
    call  WriteToDisk
    mov   si, MsgDriveWrite
    call  Println
    jmp   .done

.doBell:
    mov   al, ASCII_BELL
    call  Putc
    jmp   .done

.doVGA:
    call VgaTest
    jmp .done

.badCommand:
    xor   ax,ax
    mov   ds, ax      ; DS=0 (future: bad assumption)
    mov   si, MsgError
    call  Println

.done:
    pop ds
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




PutCrLf:
    push ax
    mov al, ASCII_CR
    mov ah, func_tty
    int 10h
    mov al, ASCII_LF
    int 10h
    pop ax
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
; print a number in decimal (16-bit)
;
; AX = number to print
;
;*****************************************************************************
PrintNumBase10:
    push ax
    push bx
    push cx
    push dx

    mov bx, 10
    xor cx, cx

    ; Loop 1
    ; Continuously divide the number by 10 and save the remainder on the stack
    .loop:
        xor dx, dx  ; DX = 0
        div bx      ; (DX:AX)/BX  --> AX:DX
        push dx     ; keep the remainder
        inc cx
        cmp ax, 0   ; AX = 0?
        jne .loop

    ; Loop 2
    ; Pop the digit values off the stack and print them out, one by one.
    .loop2:
        pop dx
        add dl, '0'
        mov al, dl
        mov ah, func_tty
        int 10h
        loop .loop2

    pop dx
    pop cx
    pop bx
    pop ax
    ret




;*****************************************************************************
; (TEST) write the keyboard buffer to the disk buffer then write the 
;        disk buffer to the disk
;
;*****************************************************************************
FillDiskBuffer:
    push  ax
    push  cx
    push  di
    push  si
    push  es
    push  ds

    xor  ax, ax             ; Set ES=DS=0 (future: not a safe assumption)
    mov  es, ax
    mov  ds, ax
    mov  di, DISK_BUFF_SEG
    mov  cx, KEY_BUFFER_SIZE
    lea  si, kbd_buffer

    rep  movsb              ; copy byte from ds:[si] to es:[di] until cx=0

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
;*****************************************************************************
WriteToDisk:
    pusha
    push es
    xor ax, ax
    mov es, ax
    mov bx, DISK_BUFF_SEG

    ; Write the buffer to LBA 36, where the file data is located
    xor dx, dx
    mov ax, 36
    call LbaToChs

    mov ax, 1
    call DiskWrite
    cmp  ah, DISK_OK
    je  .write_ok
    lea  si, MsgError
    call Print
    mov  al, ':'
    call PrintNumBase10
    call PutCrLf

.write_ok:
    
    pop es
    popa
    ret


;*****************************************************************************
; Disk Write Sectors
;  
; Input:  AX = number of sectors to write
;         
;         Uses the CHS values stored at
;           chsCylinder
;           chsHead
;           chsSector
;
; Output: AH = 0 if successful
; 
;*****************************************************************************
DiskWrite:
    push dx
    push cx

    mov si, ax               ; Save the number of sectors to write

    mov dl, [boot_drive]     ; Select the original boot drive
    xor ax, ax
    int 13h                  ; Reset disk, int 13/ah=0

    mov ax, si               ; al = number of sectors to write
    mov ah, 3                ; Write sectors function
    mov ch, [chsCylinder]    ; cylinder
    mov dh, [chsHead]        ; head
    mov cl, [chsSector]      ; sector 
    call Int13WithRetry

.write_ok:
    pop cx
    pop dx
    ret


;*****************************************************************************
; INT 13 with 3 retries
;
; Input:   AH = function #
;          AL = Number of sectors
;          CH = Cylinder
;          CL = Sector
;          DH = Head
;          DL = Drive
;
; Output:  CF = 0 if successful
;               1 if error
;*****************************************************************************
Int13WithRetry:

    push cx
    push di
    push si

    mov  di,ax           ; save function call in di
    mov  si,cx           ; save cylinder and sector in si
    mov  cx,3            ; number of retries in cx
    
.do_int13:
    push cx              ; Save loop counter
    mov  cx,si           ; Restore ch=cylinder,cl=sector
    int  13h             ; BIOS diskette service
    pop  cx              ; Restore loop counter
    jc   .time_out
    jmp short .done

.time_out: 
    cmp    ah,DISK_TIMEOUT
    je    .set_carry       ; If timeout error, don't retry
    cmp    cx,0
    je    .set_carry       ; If done all retries and CF=1, stop

.disk_reset:
    xor    ax,ax           ; ax = 0 for disk reset
    int    13h             ; do reset
    mov    ax,di           ; restore int13 arguments
    loop .do_int13         ; retry int13

.set_carry:
    stc                    ; Set CF=1 to show error

.done:
    pop si
    pop di
    pop cx
    ret



;*****************************************************************************
; LBA to CHS
;
; Input:  DX:AX = logical block address (LBA)
;
;*****************************************************************************
LbaToChs:
    push bx
    push ax
    push dx
    ;
    ; let temp = AX
    ;
    lea bx, drvSecsPerTrack
    div word [bx]                ; temp = lba / (sectorspertrack)
    inc dl                       ; adjust for sector 0
    lea bx, chsSector
    mov byte [bx], dl            ; sector = (lba % (sectorspertrack)) + 1
    xor dx, dx 
    lea bx, drvHeads
    ;
    ; at this point, temp (AX) is still the quotient from earlier
    ;
    div word [bx]
    lea bx, chsHead
    mov byte [bx], dl            ; head = temp % (numberofheads)

    lea bx, chsCylinder
    mov byte [bx], al            ; cylinder = temp / (numberofheads)

    pop dx
    pop ax
    pop bx
    ret



kbd_buffer:     times KEY_BUFFER_SIZE  db 0
kbd_buffer_idx:                        db 0


drvSecsPerTrack:     db 0
drvCylinders:        dw 0
drvHeads:            dw 0

chsCylinder:         dw 0
chsHead:             dw 0
chsSector:           db 0


VgaMode:             db VGA_MODE_GRAPHICS
PixelColor:          db COLOR_BLUE


TestStructure:       db 41h, 42h, 43h, 44h,45h, 0

MsgTime:             db "RTC Time: ", 0
MsgMemorySize:       db "Lower memory available: ", 0
MsgDriveParams:      db "Boot drive geometry ",0
MsgDriveParams1:     db "  Drive Number: ",0
MsgDriveParams2:     db "     Cylinders: ",0
MsgDriveParams3:     db "         Sides: ",0
MsgDriveParams4:     db "  SecsPerTrack: ",0
MsgError:            db "An error has occurred",0

MsgDriveWrite:       db "Writing to disk...", 0
MsgWelcome:          db "Welcome to System23!", 0

TimeString:          db "  :  :  ",0

PromptString:        db "@: ",0

times (SYS_SIZE_SECTORS * SECTOR_SIZE) - ($ - $$) db 0