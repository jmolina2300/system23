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

COLOR_BLACK       EQU 0x0
COLOR_BLUE        EQU 0x1
COLOR_GREEN       EQU 0x2
COLOR_CYAN        EQU 0x3
COLOR_RED         EQU 0x4
COLOR_WHITE       EQU 0xF
COLOR_LIGHT_GREEN EQU 0xA
COLOR_LIGHT_BLUE  EQU 0x9
COLOR_LIGHT_RED   EQU 0xC




;*****************************************************************************
; System organization
;*****************************************************************************
DIR_ENTRY_SIZE         EQU 32
DIR_ENTRIES            EQU 224
SECTOR_SIZE            EQU 512
SYS_SIZE_SECTORS       EQU 3
FAT_SIZE_SECTORS       EQU 9

VGA_MEMORY_SEG   EQU 0xA000
SYSTEM_SEG       EQU 0x2000
STACK_SEG        EQU 0x7000




ASCII_CR EQU 0xD
ASCII_LF EQU 0xA

bios_disk EQU 0x13
bios_video EQU 0x10
bios_keyboard EQU 0x16


func_tty       EQU 0x0E
func_getcursor EQU 0x03
func_setcursor EQU 0x02
func_writechar EQU 0x09


; BIOS scan codes for keyboard
KEY_RETURN    EQU 0x1C0D
KEY_BACKSPACE EQU 0x0E08
KEY_TAB       EQU 0x09



VGA_MODE_GRAPHICS  EQU 13h
VGA_MODE_TEXT      EQU 03h
