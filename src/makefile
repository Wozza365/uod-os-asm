# Create a bootable image file from our boot code

.DEFAULT_GOAL:=all

IMAGE 		= uodos

.SUFFIXES: .iso .img .bin .asm .sys .o .lib

%.bin: %.asm
	nasm -w+all -f bin -o $@ $<

boot.bin: boot.asm bpb.asm floppy16.asm fat12.asm

boot2.bin: boot2.asm functions_16.asm bpb.asm floppy16.asm user_inputs.asm

$(IMAGE).img : boot.bin boot2.bin 
#	Get the blank floppy disk image
	cp floppy_image/uodos.img $(IMAGE).img
#	Copy our new boot sector over to the floppy image
	dd status=noxfer conv=notrunc if=boot.bin of=$(IMAGE).img
#	Mount floppy image file as Z:
	imdisk -a -t file -f $(IMAGE).img -o rem -m z:
#	Now copy files to z: (we do it this way to avoid problems with cygwin and drive specifiers)
	cmd /c "copy boot2.bin z:BOOT2.BIN"
#	Unmount the floppy disk image
	imdisk -D -m z:

all: $(IMAGE).img

clean:
	rm -f boot.bin
	rm -f boot2.bin
	rm -f $(IMAGE).img
	
