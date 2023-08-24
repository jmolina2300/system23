%ifndef __GRAPHICS_ASM__
%define __GRAPHICS_ASM__

SEG_VGA            EQU 0xA000
VGA_MODE_GRAPHICS  EQU 13h
VGA_MODE_TEXT      EQU 03h

VgaMode:           db VGA_MODE_GRAPHICS
PixelColor:        db COLOR_BLUE

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
    mov ax, SEG_VGA
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

%endif  ; __GRAPHICS_ASM__