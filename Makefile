disk: boot core task
	cp boot disk
	dd if=core of=disk oflag=append conv=notrunc,sync
	dd if=task of=disk oflag=append conv=notrunc,sync

boot: boot.asm read.asm
	nasm boot.asm

core: core.asm read.asm
	nasm core.asm

task: task.asm
	nasm task.asm

.PHONY: clean
clean:
	rm -f disk boot core task
