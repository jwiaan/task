read	pusha
	mov dx, 0x1f3
	out dx, al

	inc dx
	shr eax, 8
	out dx, al

	inc dx
	shr eax, 8
	out dx, al

	inc dx
	shr eax, 8
	or al, 0xe0
	out dx, al

	mov dx, 0x1f2
	mov al, 1
	out dx, al

	mov dx, 0x1f7
	mov al, 0x20
	out dx, al

read1	in al, dx
	and al, 0x88
	cmp al, 0x08
	jne read1

	cld
	mov ecx, 256
	mov dx, 0x1f0
read2	in ax, dx
	stosw
	loop read2
	popa
	ret
