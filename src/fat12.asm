; Handle FAT12 File System

%define ROOT_DIRECTORY_OFFSET 2E00h			; Offset in segment 0 where we will store the root directory when read from disk
%define FAT_SEG     		  2C0h			; We will load the FAT into location 2C00h (02CO:0000)
%define ROOT_DIRECTORY_SEG    2E0h			; We will load the root directory into 2E00h (02EO:0000)

; Load Root Directory Table to 0x2e00

LoadRoot:
	pusha						
	push	es								; Save value of ES

    ; Compute size of root directory and store in CX
	mov		ecx, 0
	;xor     cx, cx							; Clear registers
 	xor     dx, dx
	mov     ax, 32							; Each directory entry is 32 bytes
	mul     word [bpbRootEntries]			; Multiply by number of entries in root directory to give size in bytes
	div     word [bpbBytesPerSector]		; Divide by sector size to give us the number of sectors for the root directory
	xchg    ax, cx							; move into CX

    ; Compute sector number on disk of root directory and store in AX
     
	mov     al, byte [bpbNumberOfFATs]		; Number of FATs
	mul     word [bpbSectorsPerFAT]			; Mulitplied by number of sectors user per FAT
	add     ax, word [bpbReservedSectors]	; Add the number of reserved sectors
	mov     word [datasector], ax			; Gives us the starting sector number for the root directory
	add     word [datasector], cx

    ; Read root directory into 2E00h
 
 	push	word ROOT_DIRECTORY_SEG
	pop		es
	mov     bx, 0							; Set ES:BX to 02E0:0
	
	call    ReadSectors						; Read in directory table
	pop		es								; Restore previous value of ES
	popa										
	ret

;  Load FAT to 2C00h

LoadFAT:
	pusha							
	push	es								; Save current value of ES

    ; Compute size of FAT and store in CX
     
	movzx   ax, byte [bpbNumberOfFATs]		; Get number of FATs
	mul     word [bpbSectorsPerFAT]			; and multiply by sectors used by FATs
	mov     cx, ax							; Save in CX

    ; Compute location of FAT and store in AX

	mov     ax, WORD [bpbReservedSectors]	

    ; Read FAT into memory at 2C00h

	push	word FAT_SEG					; Set ES:BX to 02C0:0000
	pop		es
	xor		bx, bx
	call    ReadSectors
	pop		es
	popa							
	ret
	
;  Search for filename in root table
;
; Input:  DS:SI = Pointer to file name in format 8 characters for name and 3 characters for extension
; Output: AX    = 0 if success. -1 if error
;		  ES:DI = Pointer to entry in root directory table

FindFile:
	push	cx						
	push	dx
	push	bx
	mov		bx, si							; Save filename location for later

    ; Loop through 

	mov     cx, word [bpbRootEntries]		; Loop counter = number of entries in root directory
	mov     di, ROOT_DIRECTORY_OFFSET					; ES:DI is the next name in the directory
	cld										; Clear direction flag

FindFile_Loop:
	push    cx
	mov     cx, 11							; Each file name is 11 characters long (8.3)
	mov		si, bx							; DS:SI = Name we are looking for
 	push    di								; Save pointer to directory entry since rep cmpsb will trash it
    rep  	cmpsb							; Test for match
	pop     di								; Retrieve pointer to directory entry
	je      FindFile_Found					; Jump if found
	pop     cx
	add     di, 32							; otherwise, update pointer to next directory entry
	loop    FindFile_Loop					; if not at last directory entry, try again

	; Not found
	pop	bx										
	pop	dx
	pop	cx
	mov	ax, -1								; Set error code
	ret

FindFile_Found:
	pop	ax									; Return value into AX contains entry of file
	pop	bx									; (This is the value of DI pushed in FindFile_Loop)
	pop	dx
	pop	cx
	xor	ax, ax								; Clear AX to indicate success
	ret

;  Load file from disk
;
;  Input:  ES:SI  = Pointer to name of file to load. Filename is 11 characters, 8 for name and 3 for extension
;          EBX:BP = Buffer to load file to
;  Output: AX = -1 on error, 0 on success
;		   CX = The number of sectors occupied by the file

LoadFile:
	xor		cx, cx						; CX will return the size of the file in sectors
	push	cx

LoadFile_Find:
	push	bx								; BX:BP points to buffer to write to; store it for later
	push	bp
	call	FindFile						; Find our file. ES:SI contains our filename
	cmp		ax, -1
	jne		LoadFile_Start					; If found, then we can load it
	pop		bp								; Filename not found in directory
	pop		bx
	pop		cx
	mov		ax, -1							; Report error
	ret

LoadFile_Start:
	sub		di, ROOT_DIRECTORY_OFFSET

	; Get starting cluster

	push	word ROOT_DIRECTORY_SEG			; Root segment location
	pop		es
	mov		dx, word [es:di + 001Ah]		; ES:DI points to first cluster number in directory entry
	mov		word [cluster], dx				; Save first cluster number
	pop		bx								; Get location to write to 
	pop		es
	push    bx								; Store location of buffer to load file into for later
	push	es
	call	LoadFAT							; Load the FAT into memory

LoadFile_Load:
	; Load the cluster
	mov		ax, word [cluster]				; Cluster to read
	pop		es								 
	pop		bx
	call	ClusterToLBA					; Convert cluster number to logical sector number
	movzx   cx, byte [bpbSectorsPerCluster]	; We will read one cluster of sectors

	call	ReadSectors
	pop		cx
	movzx	ax, byte [bpbSectorsPerCluster]										; Update the number of sectors to return 
	add		cx, ax
	push	cx

	push	bx
	push	es
	mov		ax, FAT_SEG						; Get the next cluster from the FAT
	mov		es, ax
	xor		bx, bx

	; get next cluster

	mov     ax, word [cluster]				; Get current cluster
	mov     cx, ax							
	mov     dx, ax							
	shr     dx, 1							; Divide by two
	add     cx, dx							; And add to give us a mulitply by 3/2

	mov		bx, 0							; Location of fat in memory
	add		bx, cx
	mov		dx, word [es:bx]
	test	ax, 1							; Test for odd or even cluster
	jnz		Odd_Cluster

Even_Cluster:
	and		dx, 0000111111111111b			; Take low 12 bits
	jmp		LoadFile_Done

Odd_Cluster:
	shr		dx, 4							; Take high 12 bits

LoadFile_Done:
	mov		word [cluster], dx
	cmp		dx, 0FF0h						; Test for end of file 
	jb		LoadFile_Load

	pop		es
	pop		bx
	pop		cx
	xor		ax, ax
	ret






