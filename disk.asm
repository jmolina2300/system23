%ifndef __DISK_ASM__
%define __DISK_ASM__


DISK_OK          EQU 0
DISK_TIMEOUT     EQU 0x80


;*****************************************************************************
; Disk Write Sectors
;  
; Input:    AX = logical starting sector
;           CX = number of sectors to write
;        ES:BX = disk buffer pointer
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
    
    call LbaToChs

    mov dl, [drvBoot]        ; Select the original boot drive
    xor ax, ax
    int 13h                  ; Reset disk, int 13/ah=0

    mov ax, cx               ; al = number of sectors to write
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
; Disk Read Sectors
;  
; Input:    AX = logical starting sector
;           CX = number of sectors to read
;        ES:BX = disk buffer pointer
;         
;        Uses the CHS values stored at
;           chsCylinder
;           chsHead
;           chsSector
;
; Output: AH = 0 if successful
; 
;*****************************************************************************
DiskRead:
    push dx
    push cx

    
    call LbaToChs            ; First, convert the LBA in AX to CHS

    mov dl, [drvBoot]        ; Select the original boot drive
    xor ax, ax
    int 13h                  ; Reset disk

    mov ax, cx               ; al = number of sectors to read
    mov ah, 2                ; Read sectors function
    mov ch, [chsCylinder]    ; cylinder
    mov dh, [chsHead]        ; head
    mov cl, [chsSector]      ; sector 
    call Int13WithRetry

    pop cx
    pop dx
    ret


DiskPrintStatus:
    push  ax
    push  ds
    push  si

    mov   ah,1
    int   13h
    push  cs
    pop   ds
    mov   si, MsgDriveError
    call  Print
    and   ax, 0xFF
    call  PrintNumBase10
    call  PutCrLf

    pop   si
    pop   ds
    pop   ax
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
    jmp  .done

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
; WARNING: Be sure to CLEAR DX before the call if the LBA is only 16 bits!
;
; Input:  DX:AX = logical block address (LBA)
;
;      
; 
;*****************************************************************************
LbaToChs:
    push bx
    push ax
    push dx
    push ds
    
    push  cs
    pop   ds                      ; Make sure DS=CS since all the labels are here
    ;
    ; let temp = AX
    ;
    div word [drvSecsPerTrack]    ; temp = lba / (sectorspertrack)
    inc dl                        ; adjust for sector 
    mov byte [chsSector], dl      ; sector = (lba % (sectorspertrack)) + 1
    xor dx, dx 
    ;
    ;   Head will be in AX
    ;   Remainder is in DX
    ;
    div word [drvHeads]
    mov byte [chsHead], dl        ; head = temp % (numberofheads)
    mov byte [chsCylinder], al    ; cylinder = temp / (numberofheads)

    pop ds
    pop dx
    pop ax
    pop bx
    ret


;*****************************************************************************
; Get drive parameters for a selected drive
;  
; Input:
;
;  AL = drive number
;
; Output:
;  
;  AX = drvCylinders
;  BX = drvSecsPerTrack
;  CX = drvHeads
;
;*****************************************************************************
GetDriveParams:
    push dx
    
    ;---
    ; BIOS function 13/8 - Get drive parameters
    ;
    ; Input: 
    ; DL = Drive Number
    ;
    ; Return:
    ; CH = Cylinders 
    ; CL = SecsPerTrack
    ; DH = Sides/Heads
    ; DL = drives attached 
    ;
    ;---
    push ax
    pop  dx
    mov  ah, 0x8 
    int  13h
    jc   .error

    push cx                     ; save CL=SecsPerTrack

    xor  ax, ax
    add  al, ch 
    and  cx, 0b11000000
    shl  cx, 2
    add  ax, cx                 ; AX = CH + ((CL & 0xC0) << 2)
    inc  ax                     ; AX = Cylinders    
    mov  [drvCylinders],ax

    shr  dx,8
    inc  dx
    mov  cx,dx                  ; CX = Heads
    mov  [drvHeads],cx

    pop  bx                     ; restore CL=SecsPerTrack
    and  bx, 0x3f
    mov  [drvSecsPerTrack],bx

.error:
    pop dx

    ret

;
; Cached Drive parameters
;
drvSecsPerTrack:     db 0
drvCylinders:        dw 0
drvHeads:            dw 0


chsCylinder:         dw 0
chsHead:             dw 0
chsSector:           db 0
%endif ; __DISK_ASM__