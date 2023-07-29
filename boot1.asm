; 7E00h from here on out
%include "equates.inc"

stage2:
    mov ah, func_tty
    mov al, 07h        ; Bell code
    int 10h
    
    call line_feed_tty
    
    mov si, sec2_msg
    call print
    call line_feed_tty
    call line_feed_tty
forever:
    call readkey       ; get keystroke
    call processkey    ; process the keystroke

    jmp forever


; Read key input
;
readkey:
    mov ah, 0
    int 16h        
    ret

; Process key input
;
processkey:
    push ax
    ; did they hit enter?
    cmp al, KEY_RETURN
    jne .k2
    call line_feed_tty
    jmp .done

.k2:
    call putchar
    
.done:
    pop ax
    ret


line_feed_tty:
    push ax
    mov al, ASCII_CR
    mov ah, func_tty
    int 10h
    mov al, ASCII_LF
    int 10h
    pop ax
    ret


line_feed:
    push ax
    push dx
    push bx
    ; Get current pos and size
    mov bh, 0
    mov ah, 3
    int 10h

    mov ah, 2
    inc dh
    xor dl,dl
    int 10h

    pop bx
    pop dx
    pop ax
    ret
    