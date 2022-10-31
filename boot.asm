	org 0x7c00
	cli

	in al, 0x92
	or al, 0x02
	out 0x92, al

	mov ax, cs
	mov ds, ax
	lgdt [gdt]

	mov eax, cr0
	or eax, 1
	mov cr0, eax
	jmp dword 8:boot

	bits 32
boot	mov ax, 0x10
	mov ds, ax
	mov es, ax

	mov dword [0x8000], 0x9003
	mov dword [0x8800], 0x9003
	mov dword [0x8ffc], 0x8003

	cld
	mov edi, 0x9000
	mov eax, 0x0003
	mov ecx, 256
boot1	stosd
	add eax, 0x1000
	loop boot1

	mov eax, 0x8000
	mov cr3, eax
	mov eax, cr0
	or eax, 0x80000000
	mov cr0, eax

	mov ax, 0x10
	mov ss, ax
	mov esp, 0x80007000
	add dword [gdt+2], 0x80000000
	lgdt [gdt]

	mov eax, 1
	mov edi, 0x80010000
	call read

	xor edx, edx
	mov eax, [edi]
	add eax, 511
	mov ecx, 512
	div ecx

	mov ecx, eax
	mov eax, 1
boot2	dec ecx
	jz 0x80010004
	inc eax
	add edi, 512
	call read
	jmp boot2

gdt	dw 39
	dd gdt+6
	dd 0x00000000, 0x00000000
	dd 0x0000ffff, 0x00cf9800
	dd 0x0000ffff, 0x00cf9200
	dd 0x0000ffff, 0x00cff800
	dd 0x0000ffff, 0x00cff200

%include "read.asm"
	times 510-($-$$) db 0
	dw 0xaa55
