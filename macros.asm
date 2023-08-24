%ifndef __MACROS__
%define __MACROS__

;****************************************************************
; PUSH/POP for all GPRs + segment registers
;****************************************************************
%macro  pushall 0
    pusha
    push  ds
    push  es
%endmacro

%macro  popall 0
    pop es
    pop ds
    popa
%endmacro



%endif ; __MACROS__