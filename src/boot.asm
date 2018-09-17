; First stage of the boot loader.  Because this has to fit inside a 512 byte sector
; all it does is load the second stage of the boot loader into memory and transfers
; control to it.
;
; When the PC starts, the processor is essentially emulating an 8086 processor, i.e. 
; a 16-bit processor.  So our initial boot loader code is 16-bit code that will 
; eventually switch the processor into 32-bit mode.

BITS 16

; Tell the assembler that we will be loaded at 7C00 (That's where the BIOS loads boot loader code).
ORG 7C00h
start:
	jmp 	Real_Mode_Start				; Jump past our sub-routines]

	times 11-$+start db 0				; Pad out so that there are 11 bytes before the BIOS Parameter Block.
	
%include "bpb.asm"						; The BIOS Parameter Block (i.e. information about the disk format)
%include "floppy16.asm"					; Routines to access the floppy disk drive
%include "fat12.asm"					; Routines to read the FAT and root directory

; Name of stage 2 of the boot loader (Must be a 8.3 filename and must be 11 bytes exactly).  This is expected
; to be found in the root directory of the disk.
ImageName     db "BOOT2   BIN"

; This is the real mode address where we will initially load the kernel
%define	BOOT2_SEG		0000h
%define BOOT2_OFFSET	9000h

;	Start of the actual boot loader code
	
Real_Mode_Start:
	cli
    xor 	ax, ax						; Set stack segment (SS) to 0 and set stack size to top of segment
    mov 	ss, ax
    mov 	sp, 0FFFFh

    mov 	ds, ax						; Set data segment registers (DS and ES) to 0.
	mov		es, ax						
	
	mov		[boot_device], dl			; Boot device number is passed in DL. Save it to pass to the second stage.
	
Reset_Floppy_Drive:
	mov		ah, 0						; Reset floppy disk function
	mov		dl, [boot_device]						
	int		13h						
	jc		Reset_Floppy_Drive			; If carry flag is set, there was an error. Try resetting again	
	
;	Now load the root directory table
	call	LoadRoot

	;	Load BOOT2.BIN	
    
	mov		bx, BOOT2_SEG				; BX:BP points to memory address to load the file to
    mov		bp, BOOT2_OFFSET
	mov		si, ImageName				; The file to load
	call	LoadFile					; Load the file
	mov     dl, [boot_device]
	cmp		ax, 0						; Was it successfully loaded
	je		BOOT2_OFFSET				; If so, jump to the second stage

	; Failed to load the second stage, so output an error message and halt.
	
	mov 	si, error_msg
	mov 	ah, 0Eh						; BIOS call to output value in AL to screen

Console_Write_16_Repeat:
	lodsb								; Load byte at SI into AL and increment SI
    test 	al, al						; If the byte is 0, we are done
	je 		Console_Write_16_Done
	int 	10h							; Output character to screen
	jmp 	Console_Write_16_Repeat

Console_Write_16_Done:
	hlt						
	
error_msg  db 'BOOT2.BIN Failed', 0

boot_device			db  0

; Pad out the boot loader so that it will be exactly 512 bytes
	times 510 - ($ - $$) db 0
	
; The segment must end with AA55h to indicate that it is a boot sector
	dw 0AA55h
	