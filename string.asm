%ifndef __STRING_ASM__
%define __STRING_ASM__


;*****************************************************************************
; StrCompareFilename - compare 2 strings 
;
;
; This function will return true if at least a DOS filename worth of bytes
; were equal between the two strings 
;
; 
;
; Input:
;
;    DS:SI = string1
;    ES:DI = string2
; 
; Output:
;
;    AL = 1 if strings are equal
;       = 0 if not
;
;
;*****************************************************************************
StrCompareFilename:
    push   si
    push   di
    push   dx
    push   cx
    
    xor  ax,ax
    xor  cx,cx
.loop:
	mov  dl, [es:di]   ; DL = next byte of DI
	mov  al, [ds:si]   ; AL = next byte of SI


	cmp   dl, al
	je    .continue

    cmp   cx,8      ; Not equal, but was the length at least 8?
    jge   .equal
    jmp   .notequal

.continue:
    or    al,dl
	cmp   al,0
	je    .equal   ;  end

	inc   di
	inc   si
    inc   cx
	jmp   .loop
	

.notequal:
	mov   al,0
    jmp   .done

.equal:
    mov   al,1

.done:
    pop   cx
    pop   dx
    pop   di
    pop   si
	ret




%endif