; Second stage of the boot loader

BITS 16

ORG 9000h
	jmp 	Second_Stage

%include "functions_16.asm"
%include "bpb.asm"						; The BIOS Parameter Block (i.e. information about the disk format)
%include "floppy16.asm"					; Routines to access the floppy disk drive
%include "user_inputs.asm"				; File containing user input related routines

;	Start of the second stage of the boot loader
	
Second_Stage:
    mov		[boot_device], dl			; Boot device number is passed in from first stage in DL. Save it to pass to kernel later.
	mov 	si, second_stage_msg		; Output our greeting message
    call 	Console_WriteLine_16
	
Start_Program:
	mov		si, input_msg				; Request sector from user
	call 	Console_Write_16
	call 	Start_Read_Sector_Input		; Read sector provided from user
	
	push 	ax
	push	ax
	
	mov		si, input_count_msg			; Request number of sectors
	call 	Console_Write_16
	call 	Start_Sector_Count_Input	; Read number provided from user
	
	push 	ax
	
	mov		cx, 2
	mul		cx							; Need to multiply number of sectors by 2 to get number of 256 byte sections
	
	mov		cx, dx
	mov		bx, ax

	pop		cx							; Return sector number and count after multiplication
	pop		ax							

	push	bx							; Save the sector count x2

	mov 	bx, 0D000h					; Point SI to buffer location

	call 	ReadSectors					; Execute reading of sectors
	xor		cx, cx						; Counter
	pop		bx
	
Start_Print:
	call 	Begin_Write
	call	Print_Line	
	hlt
	
Begin_Write:
	mov		ax, 512						; 512 bytes per sector
	mov		dx, 16						; 16 bytes per line
	ret	
	
Print_Line:
	push	bx
	push	cx
	
	call 	Print_Offset				; Printing each component completely separately
	call 	Print_Hex_Data
	call	Print_ASCII_Data
	call	Console_Write_CRLF
	
	pop		cx
	add		cx, 16						; Increment at end of line
	mov		ax, cx
	mov		bx, 256						; Divide by 256 as this is the blocks we are reading in
	div		bx

	pop 	bx
	cmp		dx, 0						; So we can decide whether to wait for enter/end
	jne		Print_Line
	
	cmp		ax, bx						; Safe as we don't go above 512, would break between 512-768
	je		Start_Program				; Would need to AND with dx = 0 to work beyond 512
	
	cmp		dx, 0
	je		Wait_For_Enter				; Can't be 512 here so only 256 will meet this condition

	ret
	
Wait_For_Enter:
	push	bx
	mov		si, continue_msg
	call	Console_WriteLine_16		; Print message to continue
	xor		ax, ax
	xor		bx, bx
	mov 	ah, 00h						; Keyboard input interrupt
	int 	16h
	
	pop		bx
	cmp		ah, 28						; Enter key pressed
	je		Start_Print
	cmp		ah, 28
	jne		Wait_For_Enter				; Continue to wait for Enter
	
	ret
	
Print_Offset:
	mov 	bx, cx
	call	Console_Write_Hex 			; Print offset value
	mov		si, space
	call	Console_Write_16			; Print space after offset
	ret
	
Print_Hex_Data:
	mov		si, 0D000h					; buffer
	mov		bx, cx
	mov		bx, [si+bx]
	rol		bx, 8
	call 	Console_Write_Hex_Spaced	; 2 bytes of hexadecimal with space
	add 	cx, 2						; Reading 2 bytes per time
	push 	si
	mov		si, space
	call	Console_Write_16			; Insert space after the two bytes
	pop 	si
	xor		dx, dx
	mov		bx, 16
	mov		ax, cx
	div		bx							; Checking if its reached the 16th byte per line
	cmp		dx, 0
	jne		Print_Hex_Data
	sub		cx, 16						; Reset the CX counter so that ASCII print can use it again
	ret
	
Print_ASCII_Data:
	mov		si, 0D000h
	mov		bx, cx
	mov		ax, [si+bx]					; Get the 2 bytes at the [si+bx] location
	
	xor		ah, ah						; Compare AL doesn't work as expected
	cmp		ax, 32						; So clear AH and compare AX instead
	jg		Print_Character
Replace_Character:
	mov		ax, 5Fh						; Replace ASCII code under 32 with _
Print_Character:
	mov		ah, 0Eh
	int 	10h							; Print the character in AL
	
	add		cx, 1						; Increment after each print
	xor		dx, dx
	mov		bx, 16						
	mov		ax, cx
	div		bx
	cmp		dx, 0						; Count to 16 chars per line
	jne		Print_ASCII_Data
	ret
	
continue_msg		db 'Press Enter to continue:', 0
input_msg			db 'Enter the sector you want to begin reading from (0-2879): ', 0
input_count_msg		db 'Enter the number of sectors you want to read (max 16): ', 0
second_stage_msg  	db 'Second stage of boot loader running', 0
boot_device		  	db 0
hex_chars			db '0123456789ABCDEF'
space				db ' ', 0