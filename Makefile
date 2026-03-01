all: boot.img

boot.bin: boot.asm
	@echo "[AS] boot.bin"
	@nasm -f bin boot.asm -o boot.bin

boot.img: boot.bin
	@echo "[MKIMG] boot.img"
	@dd if=/dev/zero of=$@ bs=512 count=2880 2> /dev/null
	@dd if=$< of=$@ bs=512 count=1 conv=notrunc 2> /dev/null

run:
	@echo "[RUN] boot.img"
	@qemu-system-i386 -cpu 486 -m 8 -fda boot.img

clean:
	@echo "[CLEAN] boot.img boot.bin"
	@rm -rf boot.img boot.bin

.PHONY: all run clean
