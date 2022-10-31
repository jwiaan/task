	bits 32
print	dd end
	dw 0
color	db 0

	mov ch, [color]
	mov ebx, name
task	call far [print]
	jmp task

name	db 'task', 10, 0
end:
