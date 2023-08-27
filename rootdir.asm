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
%include "fatfs.inc"





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
        at DIR_FstClusLo,     dw 0x0045
        at DIR_FileSize,      dd 0xBAADFACE
    iend
TestFile:
    istruc DirEntry
        at DIR_Name,          db "AAAAAAAABBB"
        at DIR_Atrr,          db 0x20
        at DIR_NTRes,         db 0x00
        at DIR_CrtTimeTenth,  db 0x00
        at DIR_CrtTime,       dw 0x9912
        at DIR_CrtDate,       dw 0x570D
        at DIR_LstAccDate,    dw 0x570D
        at DIR_FstClusHi,     dw 0x0000
        at DIR_WrtTime,       dw 0x0000
        at DIR_WrtDate,       dw 0x570D
        at DIR_FstClusLo,     dw 0x0003
        at DIR_FileSize,      dd 0x00000055
    iend
;
; Fill the remaining directory entries with 0
;
times (FAT_RootEntCnt - 2) * SIZE_DIR_ENTRY db 0

