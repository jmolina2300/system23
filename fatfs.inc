%ifndef __FATFS__
%define __FATFS__
;*****************************************************************************
; This file contains the code that deals with the FAT file system
;
;*****************************************************************************

ATTR_READ_ONLY     EQU 0x01
ATTR_HIDDEN        EQU 0x02
ATTR_SYSTEM        EQU 0x04
ATTR_VOLUME_ID     EQU 0x08
ATTR_DIRECTORY     EQU 0x10
ATTR_ARCHIVE       EQU 0x20


DIR_FREE           EQU 0xE5
DIR_ALL_FREE       EQU 0x00



OFFSET_DIR_Name          EQU 0
OFFSET_DIR_Attr          EQU 11
OFFSET_DIR_NTRes         EQU 12
OFFSET_DIR_CrtTimeTenth  EQU 13
OFFSET_DIR_CrtTime       EQU 14
OFFSET_DIR_CrtDate       EQU 16
OFFSET_DIR_LstAccDate    EQU 18
OFFSET_DIR_FstClusHi     EQU 20
OFFSET_DIR_WrtTime       EQU 22
OFFSET_DIR_WrtDate       EQU 24
OFFSET_DIR_FstClusLo     EQU 26
OFFSET_DIR_FileSize      EQU 28

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


%endif   ; __FATFS__