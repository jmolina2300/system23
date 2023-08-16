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
;   3. Root Dir    14 sectors
;   4. Data         1 sectors*
;
;   (*) Not sure how many yet
;  
;
; This would result in the following memory map:
; +-----+---------+------+---------------+--------------------+--------+
; |boot |system   |FAT1  |RootDir        |Data                |        |
; +-----+---------+------+---------------+--------------------+--------+
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


;++
; Root Directory with one 32-byte entry
;
; This entry describes the one and only file on disk
;--
DIR_Name:          db "MAINFILETXT"
DIR_Atrr:          db 0x21
DIR_NTRes:         db 0x00
DIR_CrtTimeTenth:  db 0x00
DIR_CrtTime:       dw 0x9912
DIR_CrtDate:       dw 0x570D
DIR_LstAccDate:    dw 0x570D
DIR_FstClusHi:     dw 0x0000
DIR_WrtTime:       dw 0x9912
DIR_WrtDate:       dw 0x570D
DIR_FstClusLo:     dw 0x0002
DIR_FileSize:      dd 20
;
; Fill the remaining directory entries with 0
;
times (DIR_ENTRIES - 1) * DIR_ENTRY_SIZE db 0


;++
; Data Region with the file data
;--
data:  db "Hello, World!", 0xA




