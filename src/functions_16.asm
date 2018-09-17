; Various sub-routines that will be useful to the boot loader code	

; Output Carriage-Return/Line-Feed (CRLF) sequence to screen using BIOS

Console_Write_CRLF:
	push	ax
	mov 	ah, 0Eh						; Output CR
    mov 	al, 0Dh
    int 	10h
    mov 	al, 0Ah						; Output LF
    int 	10h
	pop		ax
    ret

; Write to the console using BIOS.
; 
; Input: SI points to a null-terminated string

Console_Write_16:
	mov 	ah, 0Eh						; BIOS call to output value in AL to screen

Console_Write_16_Repeat:
	lodsb								; Load byte at SI into AL and increment SI
    test 	al, al						; If the byte is 0, we are done
	je 		Console_Write_16_Done
	int 	10h							; Output character to screen
	jmp 	Console_Write_16_Repeat

Console_Write_16_Done:
    ret

; Write string to the console using BIOS followed by CRLF
; 
; Input: SI points to a null-terminated string

Console_WriteLine_16:
	call 	Console_Write_16
	call 	Console_Write_CRLF
	ret

Console_Write_Hex_Spaced:
	pusha								; A lot of registers get overwritten so save everything
	mov dx, 0F000h
	mov cl, 16
	
Write_Hex_Loop_Spaced:
	sub cl, 4
	mov si, dx
	and si, bx
	shr si, cl
	mov al, byte [si+HexChars]
	mov ah, 0Eh
	int 10h
	shr dx, 4
	
	cmp cl, 8							; Print a space for every byte
	je	PrintSpace
	
	cmp cl, 0
	jne Write_Hex_Loop_Spaced
	popa								; Restore registers
	ret
	
Console_Write_Hex:
	pusha
	mov dx, 0F000h
	mov cl, 16
	
Write_Hex_Loop:
	sub cl, 4
	mov si, dx
	and si, bx
	shr si, cl
	mov al, byte [si+HexChars]
	mov ah, 0Eh
	int 10h
	shr dx, 4

	cmp cl, 0
	jne Write_Hex_Loop
	popa
	ret	

PrintSpace:
	mov 	ah, 0Eh
	mov		al, 20h
	int		10h
	jmp		Write_Hex_Loop_Spaced
	
HexChars db '0123456789ABCDEF'