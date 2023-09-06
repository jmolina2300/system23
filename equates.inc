;*****************************************************************************
;    Common equates
;*****************************************************************************

; Color attributes
;  0  0  Black
;  1  1  Blue
;  2  2  Green
;  3  3  Cyan
;  4  4  Red
;  5  5  Magenta
;  6  6  Brown
;  7  7  Light Gray
;  8  8  Dark Gray
;  9  9  Light Blue
; 10  A  Light Green
; 11  B  Light Cyan
; 12  C  Light Red
; 13  D  Light Magenta
; 14  E  Yellow
; 15  F  White

COLOR_BLACK         EQU 0x0
COLOR_BLUE          EQU 0x1
COLOR_GREEN         EQU 0x2
COLOR_CYAN          EQU 0x3
COLOR_RED           EQU 0x4
COLOR_MAGENTA       EQU 0x5
COLOR_BROWN         EQU 0x6
COLOR_LIGHT_GREY    EQU 0x7
COLOR_DARK_GREY     EQU 0x8
COLOR_LIGHT_BLUE    EQU 0x9
COLOR_LIGHT_GREEN   EQU 0xA
COLOR_LIGHT_CYAN    EQU 0xB
COLOR_LIGHT_RED     EQU 0xC
COLOR_LIGHT_MAGENTA EQU 0xD
COLOR_YELLOW        EQU 0xE
COLOR_WHITE         EQU 0xF



;*****************************************************************************
; System organization
;*****************************************************************************
SIZE_DIR_ENTRY         EQU 32   ; in BYTES
SIZE_SECTOR            EQU 512  ; in BYTES
SIZE_DISKBUFFER        EQU 2    ; in sectors
SIZE_SYSTEM            EQU 5    ; in sectors


;*****************************************************************************
; Define FAT version here
;*****************************************************************************
%define __FAT12__
%ifdef __FAT16__
    FAT_BytesPerSec      EQU 512
    FAT_SecPerClus       EQU 2
    FAT_RsvdSecCnt       EQU 1+SIZE_SYSTEM
    FAT_NumFATs          EQU 2
    FAT_RootEntCnt       EQU 512
    FAT_TotSec16         EQU 20480
    FAT_Media            EQU 0xF8
    FAT_FATsz16          EQU 20
    FAT_SecPerTrk        EQU 32
    FAT_NumHeads         EQU 2
    FAT_HiddSec          EQU 0
    FAT_TotSec32         EQU 0
    FAT_DrvNum           EQU 0x80
%elifdef __FAT12__
    FAT_BytesPerSec      EQU 512
    FAT_SecPerClus       EQU 1
    FAT_RsvdSecCnt       EQU 1+SIZE_SYSTEM
    FAT_NumFATs          EQU 2
    FAT_RootEntCnt       EQU 224
    FAT_TotSec16         EQU 2880
    FAT_Media            EQU 0xF0
    FAT_FATsz16          EQU 9
    FAT_SecPerTrk        EQU 18
    FAT_NumHeads         EQU 2
    FAT_HiddSec          EQU 0
    FAT_TotSec32         EQU 0
    FAT_DrvNum           EQU 0x00
%endif

FAT_RootDirSecStart  EQU FAT_RsvdSecCnt+(FAT_FATsz16 * 2)
FAT_RootDirSectors   EQU ((FAT_RootEntCnt * 32) + (FAT_BytesPerSec - 1)) / FAT_BytesPerSec
FAT_FirstDataSector  EQU FAT_RsvdSecCnt + (FAT_NumFATs * FAT_FATsz16) + FAT_RootDirSectors



;*****************************************************************************
; Memory Locations
;*****************************************************************************
SEG_BOOT          EQU 0x07C0
SEG_SYSTEM        EQU 0x0050
SEG_STACK         EQU 0x0800
;SEG_DISKBUFF      EQU 0x2000
SEG_DISKBUFF      EQU ((SEG_SYSTEM << 4) + (SIZE_SYSTEM * SIZE_SECTOR)) >>4




ASCII_BELL       EQU 0x7
ASCII_CR         EQU 0xD
ASCII_LF         EQU 0xA

bios_disk        EQU 0x13
bios_video       EQU 0x10
bios_keyboard    EQU 0x16


func_tty       EQU 0x0E
func_getcursor EQU 0x03
func_setcursor EQU 0x02
func_writechar EQU 0x09


; BIOS scan codes for keyboard
KEY_RETURN     EQU 0x1C0D
KEY_BACKSPACE  EQU 0x0E08
KEY_TAB        EQU 0x0F09
KEY_INS        EQU 0x5200
KEY_ESC        EQU 0x011B

SIZE_KEY_BUFFER    EQU 80



CLI_LIMIT_LEFT     EQU 0
CLI_LIMIT_RIGHT    EQU 80


