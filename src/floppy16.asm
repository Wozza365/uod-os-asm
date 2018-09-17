; Floppy drive interface routines

datasector  			dw 0x0000
cluster     			dw 0x0000

absoluteSector 			db 0x00
absoluteHead   			db 0x00
absoluteTrack  			db 0x00

; Convert Cluster number to Linear-Block-Addressing (LBA)
;
; LBA = First data sector + (cluster - 2) * sectors per cluster
;
; Input:  AX = Cluster number
; Output: AX = LBA value

ClusterToLBA:
	sub 	ax, 2                          		; Convert cluster number to zero-based
	movzx   cx, byte [bpbSectorsPerCluster]     ; Get sectors per cluster into CX
	mul     cx
	add     ax, word [datasector]               ; Add the start of the data sectors for the disk.
	ret

; Convert Linear-Block-Addressing (LBA) to Cylinder-Head-Sector (CHS) address
;
; Input: AX = LBA Address to convert
; Output:
;   CL = Absolute sector = (LBA address / sectors per track) + 1   (We add one since the sectors start from 0)
;   DH = Absolute head   = (LBA address / sectors per track) MOD number of heads
;   CH = Absolute track  = LBA address / (sectors per track * number of heads)

LBAToCHS:
	xor     dx, dx                              ; Divide by sectors per track
	div     word [bpbSectorsPerTrack]           ; DIV leaves result in AX and remainder in DX  
	inc     dl                                  
	mov     cl, dl
	xor     dx, dx                              
	div     word [bpbHeadsPerCylinder] 			       
	mov     dh, dl
	mov     ch, al
	ret

; Read a series of sectors from disk.  If a sector read fails, it will
; be attempted a total of five times. 
; 
; On input:
; 	CX = 	  Number of sectors to read
; 	AX =	  Starting sector
;   ES:BX => Buffer to read to

ReadSectors:
	mov     di, 5                          		  ; We attempt each read 5 times if an error occurs

AttemptRead:
	push    ax
	push    bx
	push    cx
	push 	di
	call    LBAToCHS                              ; Convert starting sector to CHS
	mov     ah, 2                            	  ; BIOS read sector function
	mov     al, 1                            	  ; Read one sector
	mov     dl, byte [bsDriveNumber]              
	int     13h                                   ; invoke BIOS to read the sector
	jnc     ReadSuccess                           ; Read was successful
	xor     ax, ax                                ; If not successful, invoke BIOS call to reset disk
	int     13h                                  
	pop		di
	dec     di                                    ; Decrement error counter
	pop     cx
	pop     bx
	pop     ax
	jnz     AttemptRead                           ; Attempt to read again
	int     18h									  ; Read still failed.  Reboot

ReadSuccess:
	pop		di
	pop     cx
	pop     bx
	pop     ax
	add     bx, word [bpbBytesPerSector]        ; Update buffer pointer to point to next location to read to
	inc     ax                                  ; Increment LBA
	loop    ReadSectors                         ; read next sector
	ret

