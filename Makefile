all:
	@#Just a quick hand-made Makefile

	@# Assemble bootloader
	nasm boot.asm -f bin -o boot.o
	@# Now kernel
	nasm kernel.asm -f bin -o kernel.o
	@# And join them together
	cat boot.o kernel.o > weevil.flp

run:
	qemu-system-i386 -fda weevil.flp