; BIOS Parameter Block

bpbBytesPerSector:  	dw 512			; Bytes per sector
bpbSectorsPerCluster: 	db 1			; Sectors per cluster
bpbReservedSectors: 	dw 1			; Number of reserved sectors
bpbNumberOfFATs: 	    db 2			; Number of copies of the file allocation table
bpbRootEntries: 	    dw 224			; Size of root directory
bpbTotalSectors: 	    dw 2880			; Total number of sectors on the disk (if disk less than 32MB)
bpbMedia: 	            db 0F0h			; Media descriptor
bpbSectorsPerFAT: 	    dw 9			; Size of file allocation table (in sectors)
bpbSectorsPerTrack: 	dw 18			; Number of sectors per track
bpbHeadsPerCylinder: 	dw 2			; Number of read-write heads
bpbHiddenSectors: 	    dd 0			; Number of hidden sectors
bpbTotalSectorsBig:     dd 0			; Number of sectors if disk greater than 32MB
bsDriveNumber: 	        db 0			; Drive boot sector came from
bsUnused: 	            db 0			; Reserved
bsExtBootSignature: 	db 29h			; Extended boot sector signature
bsSerialNumber:	        dd 0a0a1a2a3h	; Disk serial number`
bsVolumeLabel: 	        db "MOS FLOPP`Y "   ; Disk volume label
bsFileSystem: 	        db "FAT12   "	; File system type
