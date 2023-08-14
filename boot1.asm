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
    mov al, 07h        ; Bell code
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
    push ax
    ; did they hit enter?
    cmp al, KEY_RETURN
    jne .k2
    call tty_line_feed

    jmp .done

.k2:
    cmp al, KEY_TAB
    jne .k3
    call toggle_graphics
    jmp .done

.k3:
    call putchar
    
.done:
    pop ax
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




vga_mode:         db VGA_MODE_GRAPHICS

test_structure:   db 41h, 42h, 43h, 44h,45h, 0

msg_time:         db "RTC Time: ", 0
msg_memory_size:  db "Lower memory available (KiB): ", 0
msg_sec1:         db "Hello, sector 1!", 0
msg_sec2:         db "Hello, sector 2!", 0
msg_welcome:      db "Welcome to System23!", 0

times (SYS_SIZE_SECTORS * SECTOR_SIZE) - ($ - $$) db 0