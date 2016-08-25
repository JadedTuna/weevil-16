ASM=nasm
ASMFLAGS=-f bin
BOOT=boot
KERNEL=kernel
FLOPPY=weevil.flp


help:
	@echo -e "Available commands:"
	@echo -e "\tall - compile the OS"
	@echo -e "\trun - run the .flp file"
	@echo -e "\tclean - clean up"
	@echo -e "\thelp - print this help message"

all:
	@#Just a quick hand-made Makefile
	$(ASM) $(BOOT).asm $(ASMFLAGS) -o $(BOOT).o
	$(ASM) $(KERNEL).asm $(ASMFLAGS) -o $(KERNEL).o
	cat $(BOOT).o $(KERNEL).o > $(FLOPPY)

run:
	qemu-system-i386 -fda $(FLOPPY)

clean:
	rm -f *.o
	rm -f $(FLOPPY)
