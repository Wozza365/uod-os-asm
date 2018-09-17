	;								;
	;	Select start sector section	;
	;								;
	
	; Output:
	; AX - Value after enter is pressed (0-2879)

Start_Read_Sector_Input:
	xor		bx, bx
	xor		dx, dx
	
Read_Sector_Input:
	mov 	ah, 00h							; AH=0, int 16h = Read key press interrupt
	int 	16h
	
	cmp		ah, 28							; Enter key pressed, so finish 
	je		End_Sector_Input

	cmp		al, 48							; ASCII code < 48	
	jl		Read_Sector_Input

	cmp		al, 57							; ASCII code > 57
	jg		Read_Sector_Input

Sector_Input_Char_Is_A_Number:				; ASCII code = 48-57 (0-9)
	xchg	ax, bx
	mov		si, 10							; Multiply by 10 after a new character is entered
	mul		si
	xchg	ax, bx

	mov		ah, 0Eh
	int 	10h								; Print the character

	xor 	ah, ah
	sub 	al, 48							; ASCII to number

	add		bx, ax
	jmp		Read_Sector_Input
	
Invalid_Input:
	mov		si, invalid_input				; Only reached when an inputted number is too high
	call	Console_Write_16
	jmp		Start_Read_Sector_Input
	ret
	
End_Sector_Input:
	mov		ax, bx
	call	Console_Write_CRLF
	cmp		ax, 2880
	jge		Invalid_Input					; Highest sector available is 2879
	ret
	
; Input code for getting the sector to start from
Start_Sector_Count_Input:
	xor		bx, bx
	xor		dx, dx

Read_Sector_Count_Input:
	mov 	ah, 00h							; AH=0, int 16h = Read key press interrupt
	int 	16h
	
	cmp		ah, 28							; Enter key pressed, so finish 
	je		End_Sector_Count_Input

	cmp		al, 48							; ASCII code < 48	
	jl		Read_Sector_Count_Input

	cmp		al, 57							; ASCII code > 57
	jg		Read_Sector_Count_Input

Sector_Count_Input_Char_Is_A_Number:		; ASCII code = 48-57 (0-9)
	xchg	ax, bx
	mov		si, 10							; Multiply by 10 after a new character is entered
	mul		si
	xchg	ax, bx

	mov		ah, 0Eh
	int 	10h								; Print the character

	xor 	ah, ah
	sub 	al, 48							; ASCII to number

	add		bx, ax
	jmp		Read_Sector_Count_Input
	
End_Sector_Count_Input:
	mov		ax, bx
	call	Console_Write_CRLF
	cmp		ax, 16
	jg		Invalid_Input					; Limiting count to 16
	cmp		ax, 0
	je		Invalid_Input
	ret

invalid_input			db 'Invalid input, please try again: ', 0