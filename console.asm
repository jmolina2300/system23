
%ifndef __CONSOLE_ASM__
%define __CONSOLE_ASM__

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
; Put an indent of specified length (MAX: 255)
;
; Input:  AL = Count of spaces to indent by
;
;*****************************************************************************
PutIndent:
    push  ax
    and   ax,0x00FF
    mov   cx,ax
.space:
    mov   al,' '
    call  Putc
    loop  .space
    pop   ax
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
; print a 16-bit number in hexadecimal
;
; Input:  AX = number to print
;*****************************************************************************
PrintNumBase16:
    push   ax
    push   bx
    push   cx
    push   dx
    push   si
    push   ds

    push   cs    ; DS = CS
    pop    ds

    mov    cx,4   ; CX = 4 digits
    mov    si,HexDigit
.getdigits:
    mov    bx,ax  ; BX = AX
    and    bx, 0x000F
    mov    dl, [si + bx]
    and    dx, 0x00FF
    push   dx
    shr    ax,4
    loop   .getdigits


    ; Put the prefix
    mov    ah, func_tty
    mov    si, HexPrefix
    mov    cx, 2
.putprefix:
    lodsb
    int    10h
    loop   .putprefix

    mov    cx,4
.putdigits:
    pop    ax
    mov    ah, func_tty
    int    10h
    loop   .putdigits

    



    pop ds
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

HexPrefix: db "0x"
HexDigit:  db "0123456789ABCDEF"

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

    pop    si
    pop	   di
    pop	   dx
    pop	   cx
    pop	   bx
    pop    ax
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

%endif ; __CONSOLE_ASM__