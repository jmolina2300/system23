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
    push  ds
    mov   al, 13h
    mov   ah, 0
    int   10h


    ; Switch DS to video segment
    mov   ax,SEG_VGA
    mov   ds,ax
    mov   si,0x0
    xor   bx,bx

    ; Draw weird rainbow pattern
.again:
    mov   bx,si
    mov   cx,si
    and   cx,0x000f
    ror   bx,cl
    mov   [ds:si],bx
    inc   si
    cmp   si,63999
    jne   .again


    xor   ax,ax
    int   16h

    mov   al, VGA_MODE_TEXT
    mov   ah, 0
    int   10h
    pop   ds
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