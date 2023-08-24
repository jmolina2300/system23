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