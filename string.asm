%ifndef __STRING_ASM__
%define __STRING_ASM__


;*****************************************************************************
; StrNCompare 
;
; This function will return true (1) if at least N characters are the same
; between string1 and string2
;
; Input:
;    CX    = number of characters
;    DS:SI = string1
;    ES:DI = string2
; 
; Output:
;
;    AL = 1 if strings are equal
;       = 0 if not
;
; Flags Affected: 
;
;    ZF
;
;*****************************************************************************
StrNCompare:
    push  si
    push  di
    push  dx
    push  cx
    
    xor   ax,ax
.loop:
	mov   dl, [es:di]   ; DL = next byte of DI
	mov   al, [ds:si]   ; AL = next byte of SI

	cmp   dl, al
	jne    .checklength

.continue:
    or    al,dl
	cmp   al,0         ; Did we hit the null char?
	je    .equal

	inc   di
	inc   si
    dec   cx
	jmp   .loop


.checklength:
    cmp   cx,0         ; Not equal, but was the length at least cx?
    jle   .equal

	mov   al,0
    jmp   .done

.equal:
    mov   al,1
    
.done:
    test  al,al
    
    pop   cx
    pop   dx
    pop   di
    pop   si
	ret



;*****************************************************************************
; StrLen
;
; Returns the length of a null-terminated string in DS:SI
;
; Input:
; 
;   DS:SI = string 
; 
; Output:
;
;   CX = Length of string
;
;
;*****************************************************************************
StrLen:
    push  si
    push  ax
    
    xor   cx,cx
.NextChar:
    lodsb
    test  al,al
    jz    .Done
    inc   cx
    jmp   .NextChar
    
.Done:
    
    pop   ax
    pop   si
    ret



%endif