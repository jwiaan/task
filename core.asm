	bits 32
	org 0x80010000
	dd end-$

	mov al, 0x11
	out 0x20, al
	mov al, 0x20
	out 0x21, al
	mov al, 0x04
	out 0x21, al
	mov al, 0x01
	out 0x21, al

	mov al, 0x11
	out 0xa0, al
	mov al, 0x70
	out 0xa1, al
	mov al, 0x02
	out 0xa1, al
	mov al, 0x01
	out 0xa1, al

	mov ebx, [idt+2]
	xor edi, edi

	mov eax, stop
	call make_intr
core1	mov [ebx+edi*8+0], eax
	mov [ebx+edi*8+4], edx
	inc edi
	cmp edi, 20
	jne core1

	mov eax, intr
	call make_intr
core2	mov [ebx+edi*8+0], eax
	mov [ebx+edi*8+4], edx
	inc edi
	cmp edi, 256
	jne core2

	mov eax, switch
	call make_intr
	mov [ebx+0x20*8+0], eax
	mov [ebx+0x20*8+4], edx
	lidt [idt]

	mov eax, print
	call make_call
	call setup_gdt
	mov [gate+4], ax

	mov eax, tss
	call make_tssd
	call setup_gdt
	mov [task+12], ax
	ltr ax
	sti

	mov eax, task+4
	mov ecx, 6
core3	call alloc
	push ebx
	push ecx
	push 5
	call load
	loop core3

	mov ch, 0x7
	mov ebx, name
core4	call far [gate]
	jmp core4

load	pusha
	mov ebp, esp

	cld
	mov eax, 0
	mov edi, [ebp+44]
	mov ecx, 30
load1	stosd
	loop load1

	mov edi, 0xfffff000
	mov ecx, 512
load2	stosd
	loop load2

	mov eax, cr3
	mov cr3, eax

	mov eax, [ebp+36]
	mov edi, buf
	call reads

	xor edx, edx
	mov eax, [buf]
	add eax, 4095
	mov ecx, 4096
	div ecx
	mov ecx, eax

	mov eax, [ebp+44]
	add eax, 108
load3	call alloc
	loop load3

	call alloc
	mov edx, [eax]
	mov ebx, [ebp+44]
	mov [ebx+56], edx
	mov word [ebx+80], 0x23

	call alloc
	mov edx, [eax]
	mov ebx, [ebp+44]
	mov [ebx+4], edx
	mov word [ebx+8], 0x10

	xor edx, edx
	mov eax, [buf]
	add eax, 511
	mov ecx, 512
	div ecx
	mov ecx, eax

	mov eax, [ebp+36]
	mov edi, 0
load4	call reads
	inc esi
	add edi, 512
	loop load4

	mov ax, [gate+4]
	mov [4], ax
	mov ch, [ebp+40]
	mov [6], ch

	mov esi, [ebp+44]
	mov word [esi+72], 0x23
	mov word [esi+84], 0x23
	mov word [esi+76], 0x1b
	mov word [esi+102], 103
	mov dword [esi+32], 7
	pushf
	pop edx
	mov [esi+36], edx

	call create_pdt
	mov [esi+28], eax

	mov eax, esi
	call make_tssd
	call setup_gdt
	mov [esi+116], ax

	add esi, 104
	mov eax, [list]
	mov ecx, [eax]
	mov [esi], ecx
	mov [eax], esi
	popa
	ret 8

make_intr:
	mov edx, eax
	mov dx, 0x8e00
	and eax, 0x0000ffff
	or eax, 0x80000
	ret

make_call:
	mov edx, eax
	mov dx, 0xec00
	and eax, 0x0000ffff
	or eax, 0x80000
	ret

make_tssd:
	mov edx, eax
	shl eax, 16
	mov ax, 103
	and edx, 0xffff0000
	rol edx, 8
	bswap edx
	or edx, 0x8900
	ret

setup_gdt:
	push ebx
	push edx
	sgdt [gdt]
	movzx ebx, word [gdt]
	inc ebx
	add ebx, [gdt+2]
	mov [ebx], eax
	mov [ebx+4], edx
	add word [gdt], 8
	lgdt [gdt]

	mov ax, [gdt]
	xor dx, dx
	mov bx, 8
	div bx
	shl ax, 3
	pop edx
	pop ebx
	ret

stop	mov ch, 0xc
	mov ebx, kill
	call far [gate]
	hlt

intr	pusha
	mov al, 0x20
	out 0x20, al
	popa
	iret

switch	pusha
	mov al, 0x20
	out 0x20, al

	mov eax, [list]
	mov ebx, [eax]
	mov [list], ebx
	jmp far [ebx+8]
	popa
	iret

print	pusha
print1	mov cl, [ebx]
	cmp cl, 0
	je print2
	call show
	inc ebx
	jmp print1
print2	popa
	retf

show	pusha
	mov dx, 0x3d4
	mov al, 0xe
	out dx, al
	inc dx
	in al, dx
	mov ah, al

	mov dx, 0x3d4
	mov al, 0xf
	out dx, al
	inc dx
	in al, dx
	and eax, 0x0000ffff

	cmp cl, 0xa
	je show1
	mov [0x800b8000+eax*2], cx
	inc ax
	jmp show2
show1	mov cl, 80
	div cl
	inc al
	mul cl
show2	cmp ax, 2000
	jne show4

	mov esi, 0x800b80a0
	mov edi, 0x800b8000
	mov ecx, 960
	cld
	rep movsd

	mov ecx, 80
	xor ebx, ebx
show3	mov word [ebx+edi], 0x720
	add ebx, 2
	loop show3
	mov ax, 1920
show4	mov cx, ax
	mov dx, 0x3d4
	mov al, 0xe
	out dx, al
	inc dx
	mov al, ch
	out dx, al

	mov dx, 0x3d4
	mov al, 0xf
	out dx, al
	inc dx
	mov al, cl
	out dx, al
	popa
	ret

reads	cli
	call read
	sti
	ret

create_pdt:
	push ecx
	push esi
	push edi
	call alloc_page
	mov ecx, eax
	or ecx, 0x7
	mov [0xfffffff8], ecx
	invlpg [0xfffffff8]

	mov esi, 0xfffff000
	mov edi, 0xffffe000
	mov ecx, 1024
	cld
	rep movsd
	pop edi
	pop esi
	pop ecx
	ret

alloc	mov ebx, [eax]
	call alloc_line
	add dword [eax], 4096
	ret

alloc_line:
	pusha
	push ebx
	and ebx, 0xffc00000
	shr ebx, 20
	or ebx, 0xfffff000
	test dword [ebx], 1
	jnz alloc_line1
	call alloc_page
	or eax, 0x7
	mov [ebx], eax
alloc_line1:
	pop ebx
	and ebx, 0xfffff000
	shr ebx, 10
	or ebx, 0xffc00000
	call alloc_page
	or eax, 0x7
	mov [ebx], eax
	popa
	ret

alloc_page:
	xor eax, eax
alloc_page1:
	bts [page], eax
	jnc alloc_page2
	inc eax
	jmp alloc_page1
alloc_page2:
	shl eax, 12
	ret

%include "read.asm"
page	db 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
	db 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
	db 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
	db 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
	db 0x55, 0x55, 0x55, 0x55, 0x55, 0x55, 0x55, 0x55
	db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	db 0x55, 0x55, 0x55, 0x55, 0x55, 0x55, 0x55, 0x55
	db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
idt	dw 256*8-1
	dd 0x8000a000
gdt	dw 0
	dd 0
buf	times 512 db 0
tss	times 28 db 0
	dd 0x8000
	times 70 db 0
	dw 103
task	dd task
	dd 0x80100000
	dd 0
	dw 0
list	dd task
gate	dd 0
	dw 0
name	db 'core', 10, 0
kill	db 'kill', 10, 0
end:
