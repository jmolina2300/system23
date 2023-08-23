;*****************************************************************************
; Hard-coded Root Directory
;
; To be appended after the boot code and system code like so:
;
; +-----+---------+-------+-------+---------------+--------------------+
; |boot |system   |FAT1   |FAT2   |RootDir        |Data                |
; +-----+---------+-------+-------+---------------+--------------------+
;
; 
;*****************************************************************************
%include "equates.inc"


struc   DirEntry
    DIR_Name:          resb 11
    DIR_Atrr:          resb 1
    DIR_NTRes:         resb 1
    DIR_CrtTimeTenth:  resb 1
    DIR_CrtTime:       resw 1
    DIR_CrtDate:       resw 1
    DIR_LstAccDate:    resw 1
    DIR_FstClusHi:     resw 1
    DIR_WrtTime:       resw 1
    DIR_WrtDate:       resw 1
    DIR_FstClusLo:     resw 1
    DIR_FileSize:      resd 1
endstruc


VolumeID:
    istruc DirEntry
        at DIR_Name,          db "VolumeID   "
        at DIR_Atrr,          db 0x28
        at DIR_NTRes,         db 0x00
        at DIR_CrtTimeTenth,  db 0x00
        at DIR_CrtTime,       dw 0x9912
        at DIR_CrtDate,       dw 0x570D
        at DIR_LstAccDate,    dw 0x570D
        at DIR_FstClusHi,     dw 0xFFFF
        at DIR_WrtTime,       dw 0xFFFF
        at DIR_WrtDate,       dw 0xFFFF
        at DIR_FstClusLo,     dw 0x0000
        at DIR_FileSize,      dd 0xFFFFFFFF
    iend

;
; Fill the remaining directory entries with 0
;
times (FAT16_RootEntCnt - 1) * SIZE_DIR_ENTRY db 0
