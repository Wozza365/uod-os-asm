# Create a blank 1.44M bootable floppy image file.
# This will only run under Linux (or the Bash shell on Windows 10)
# It will not run under Cygwin.

.SUFFIXES: .img 

uodos.img: 
	mkfs.vfat -C uodos.img 1440

all: uodos.iso

clean:
	rm -f uodos.img
