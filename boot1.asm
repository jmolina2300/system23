%include "equates.inc"


org SYSTEM_SEG
begin:
    mov dh, 20         ; 20 rows
    mov dl, 80         ; 80 columns
    call cls           ; Clear them all...

    mov si, msg_welcome
    call tty_print

    call tty_line_feed
    call tty_line_feed
    mov ah, func_tty
    mov al, ASCII_BELL
    int 10h
    
    mov si, msg_memory_size
    call tty_print

    ; Get lower memory size
    ;   AX will be the number of total kilobytes available
    int 0x12            
    call print_num_base10
    call tty_line_feed

    ; Print the RTC time
    ;
    mov si, msg_time
    call tty_print
    call put_time
    call tty_line_feed


    ; Print drive parameters
    ;
    mov ax, [boot_drive]
    call put_drive_params



    
forever:
    call readkey       ; get keystroke
    call processkey    ; process the keystroke
    jmp forever



vga_index:    dw 0x0000  ; Goes from 0 to 63999
pixel:        db COLOR_BLUE
pixel_loc:    db 0x0

pixel_x:      dw 0
pixel_y:      dw 0



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
put_drive_params:
    push ax
    mov si, msg_drive_params
    call tty_print
    call print_num_base10
    call tty_line_feed

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
    mov si, msg_drive_params_1 ; 1 Number of cylinders
    call tty_print
    call print_num_base10
    call tty_line_feed

    mov si, msg_drive_params_2 ; 2 Number of sides/heads (0-based)
    call tty_print
    pop ax                     ; restore DH=sides
    shr ax, 8
    inc ax
    mov [drvHeads], ax
    call print_num_base10
    call tty_line_feed

    mov si, msg_drive_params_3 ; 3 Sectors per track
    call tty_print
    pop ax                     ; restore CL=SecsPerTrack
    and ax, 0xff
    mov [drvSecsPerTrack], ax
    call print_num_base10
    call tty_line_feed

.error:
    call tty_line_feed
    ret


;*****************************************************************************
; Put a pixel in VGA memory
;
; AX = Y-coordinate
; BX = X-coordinate
;*****************************************************************************
put_pix:
    pusha
    mov dx, 320
    mul dx       ; DX:AX = (Y * 319)

    ; Then add this to the X-coordinate provided, 
    ;  but it could be too large for AX in weird cases
    add ax, bx


    ; Now DX:AX = (Y * 319) + X
    ; Save DX:AX in the vga_index variable
    mov [vga_index], ax
    

    mov bl, COLOR_LIGHT_GREEN
    ; Then place pixel at this coordinate in VGA memory
    mov es:[vga_index], bl

    popa
    ret


;*****************************************************************************
; VGA Clear - clears the vga buffer with a specified color
;
; AL = pixel color
;
;*****************************************************************************
vga_clear:
    pusha
    push es

    xor bx,bx
    ; Load ES with the VGA memory segment
    mov ax, VGA_MEMORY_SEG
    mov es, ax
    xor ax, ax
    mov al, [pixel]    ; AL = pixel color
.clear_loop:
    mov [es:bx], al    ; vgamem[bx] = pixel
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
VGA_TEST:
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
    call put_pixel


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
    call put_pixel

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
tty_print:
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
    cmp al, 0      ; AL == 0?
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
tty_println:
    call tty_print
    mov ah, func_tty
    mov al, ASCII_CR
    int 10h
    mov al, ASCII_LF
    int 10h
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



put_time:
    pusha
    mov ah, 02h
    int 1Ah      ; BIOS read RTC function
    mov al, ch
    and ax, 0xff
    call print_num_base10
    mov al, ':'
    call putchar
    mov al, cl
    call print_num_base10
    mov al, ':'
    call putchar
    mov al, dh 
    call print_num_base10
    call tty_line_feed
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
put_pixel:
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
processKeyBuffer:
    pusha
    push ds

    mov si, kbd_buffer
    lodsb

.isItCommand:
    cmp  al, ':'
    jne  .done    ; Nope, not a command
    
    lodsb         ; Maybe a command -- look at the next byte
    ; Write command
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
    call  write_to_disk_buffer
    call  write_disk_buffer_to_disk
    mov   si, msg_drive_write
    call  tty_println
    jmp   .done

.doBell:
    mov   al, ASCII_BELL
    call  putchar
    jmp   .done

.doVGA:
    call VGA_TEST
    jmp .done

.badCommand:
    xor   ax,ax
    mov   ds, ax      ; DS=0 (future: bad assumption)
    mov   si, msg_err
    call  tty_println

.done:
    pop ds
    popa
    ret


;*****************************************************************************
; Read key input
;
;*****************************************************************************
readkey:
    mov ah, 0
    int 16h        
    ret


;*****************************************************************************
; Process key input
;
;*****************************************************************************
processkey:
    push   ax
    push   bx
    push   di
    push   cx

    ;------------------------------
    ; ENTER/RETURN
    ;------------------------------
    cmp   ax, KEY_RETURN
    jne   .k2
    call  tty_line_feed      ; Advance the line
    call  processKeyBuffer   ; Check the key buffer for commands
    call  keybuffer_empty    ; Empty the key buffer

    jmp   .done

    ;------------------------------
    ; TAB
    ;------------------------------
.k2:
    cmp   ax, KEY_TAB
    jne   .k3
    call  toggle_graphics
    jmp   .done


    ;------------------------------
    ; Backspace
    ;------------------------------
.k3:
    cmp   ax, KEY_BACKSPACE
    jne   .k4

    xor   bx,bx     ; Get cursor position...
    mov   ah, 3
    int   10h

    cmp    dl,CLI_LIMIT_LEFT
    je    .done
    dec   dl        ; Move back 1 space...
    mov   ah, 2
    int   10h

    mov   cx, 1     ; And put a null character
    mov   al, 0
    mov   ah, 0xA
    int   10h
    call  keybuffer_remove
    jmp   .done


    ;------------------------------
    ; INSERT
    ;------------------------------
.k4:
    cmp   ax, KEY_INS
    jne   .k5
    ;call  write_to_disk_buffer
    ;call  write_disk_buffer_to_disk
    jmp   .done

    ;------------------------------
    ; Any other key was pressed
    ;------------------------------
.k5:
    xor   bx, bx
    mov   bl, [kbd_buffer_idx]  ; BL = kbd_buffer_idx
    cmp   bl, KEY_BUFFER_SIZE
    je    .done                 ; kbd_buffer_idx == kbd_buffer_size?

    call   keybuffer_insert     ; save the character
    call   putchar              ; print the character

.done:
    pop   cx
    pop   di
    pop   bx
    pop   ax
    ret



keybuffer_empty:
    push ax
    push cx
    push si
    push di

    mov byte [kbd_buffer_idx], 0   ; Reset keyboard buffer index
    mov cx, KEY_BUFFER_SIZE
    lea si, empty_buffer
    lea di, kbd_buffer

    rep movsb

    pop di
    pop si
    pop cx
    pop ax
    ret


keybuffer_remove:
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
keybuffer_insert:
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




tty_line_feed:
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
toggle_graphics:
    push ax
    mov al, [vga_mode]
    cmp al, VGA_MODE_GRAPHICS
    je .to_text_mode
.to_graphics_mode:
    mov al, VGA_MODE_GRAPHICS
    jmp .done
.to_text_mode:
    mov al, VGA_MODE_TEXT
    jmp .done

.done:
    mov [vga_mode], al
    mov ah, 0
    int 10h
    pop ax
    ret


;*****************************************************************************
; print a number in decimal (16-bit)
;
; AX = number to print
;
;*****************************************************************************
print_num_base10:
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
write_to_disk_buffer:
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
write_disk_buffer_to_disk:
    pusha
    push es
    xor ax, ax
    mov es, ax
    mov bx, DISK_BUFF_SEG

    ; Write the buffer to LBA 36, where the file data is located
    xor dx, dx
    mov ax, 36
    call lba_to_chs

    mov ax, 1
    call disk_write
    cmp  ah, DISK_OK
    je .write_ok
    lea  si, msg_err
    call tty_print
    call print_num_base10
    call tty_line_feed

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
disk_write:
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
    call int13_with_retry

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
int13_with_retry:

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
lba_to_chs:
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



empty_buffer:   times KEY_BUFFER_SIZE  db 0
kbd_buffer:     times KEY_BUFFER_SIZE  db 0
kbd_buffer_idx:                        db 0
kbd_enter:                             db 0


drvSecsPerTrack:     db 0
drvCylinders:        dw 0
drvHeads:            dw 0

chsCylinder:         dw 0
chsHead:             dw 0
chsSector:           db 0


vga_mode:            db VGA_MODE_GRAPHICS

test_structure:      db 41h, 42h, 43h, 44h,45h, 0

msg_time:            db "RTC Time: ", 0
msg_memory_size:     db "Lower memory available (KiB): ", 0
msg_drive_params:    db "Disk parameters - drive ",0
msg_drive_params_1:  db "    Cylinders = ",0
msg_drive_params_2:  db "        Sides = ",0
msg_drive_params_3:  db " SecsPerTrack = ",0
msg_err:             db "An error has occurred: ",0

msg_drive_write:     db "Writing to disk...", 0


msg_sec1:         db "Hello, sector 1!", 0
msg_sec2:         db "Hello, sector 2!", 0
msg_welcome:      db "Welcome to System23!", 0


times (SYS_SIZE_SECTORS * SECTOR_SIZE) - ($ - $$) db 0