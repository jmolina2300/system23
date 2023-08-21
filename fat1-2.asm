;*****************************************************************************
; Hard-coded FATs and Root Directory + File
;
; To be appended after the boot code and system code like so:
;
; +-----+---------+-------+-------+---------------+--------------------+
; |boot |system   |FAT1   |FAT2   |RootDir        |Data                |
; +-----+---------+-------+-------+---------------+--------------------+
;
; We shall only read part of this into MEMORY though so we don't waste space.
; In particular, we will read the following contents:
;
;   0. boot         1 sectors
;   1. system       3 sectors*
;   2. FAT #1       9 sectors
;
;   (*) Not sure how many yet
;  
;
; This would result in the following memory map:
; +-----+---------+------+---------------------------------------------+
; |boot |system   |FAT1  |                                             |
; +-----+---------+------+---------------------------------------------+
;
;
;*****************************************************************************
%include "equates.inc"
org SYSTEM_SEG + (FAT_SIZE_SECTORS)

; FAT #1
db 0xF0,0xFF,0xFF,0x00,0xF0,0xFF,0,0,0,0,0,0,0,0,0,0
times ((FAT_SIZE_SECTORS * SECTOR_SIZE) - 16)  db 0x00

; FAT #2
db 0xF0,0xFF,0xFF,0x00,0xF0,0xFF,0,0,0,0,0,0,0,0,0,0
times ((FAT_SIZE_SECTORS * SECTOR_SIZE) - 16)  db 0x00



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

MainFile:
    istruc DirEntry
        at DIR_Name,          db "MAINFILETXT"
        at DIR_Atrr,          db 0x21
        at DIR_NTRes,         db 0x00
        at DIR_CrtTimeTenth,  db 0x00
        at DIR_CrtTime,       dw 0x9912
        at DIR_CrtDate,       dw 0x570D
        at DIR_LstAccDate,    dw 0x570D
        at DIR_FstClusHi,     dw 0x0000
        at DIR_WrtTime,       dw 0x9912
        at DIR_WrtDate,       dw 0x570D
        at DIR_FstClusLo,     dw 0x0002
        at DIR_FileSize,      dd KEY_BUFFER_SIZE
    iend

;
; Fill the remaining directory entries with 0
;
times (DIR_ENTRIES - 1) * DIR_ENTRY_SIZE db 0


;++
; Data Region with the file data
;--
data:  db "Hello, World!    :D",0xA




