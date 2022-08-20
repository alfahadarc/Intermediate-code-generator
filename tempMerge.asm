
;main start
main proc
	mov ax, @data
	mov ds, ax


;variable ASSIGNOP logic_expression

	mov ax, 1
	mov i1, ax

;variable ASSIGNOP logic_expression


 ;before push asmvar for println
	push i1
	call println
	mov ax, 5
	add ax, 8
	mov t0, ax

;variable ASSIGNOP logic_expression

	mov ax, t0
	mov j1, ax

;variable ASSIGNOP logic_expression


 ;before push asmvar for println
	push j1
	call println
	mov ax, 2
	mov bx, j1
	imul bx
	mov t1, ax
	mov ax, i1
	add ax, t1
	mov t2, ax

;variable ASSIGNOP logic_expression

	mov ax, t2
	mov k1, ax

;variable ASSIGNOP logic_expression


 ;before push asmvar for println
	push k1
	call println
	mov ax, k1
	cwd
	mov bx, 9
	idiv bx
	mov t3, dx

;variable ASSIGNOP logic_expression

	mov ax, t3
	mov m1, ax

;variable ASSIGNOP logic_expression


 ;before push asmvar for println
	push m1
	call println

;relational exp
	mov ax, m1
	cmp ax, ll1

;relational exp <=
	jle L0
	mov ax, 0
	mov t4, ax
	jmp L1
	L0:
	mov ax, 1
	mov t4, ax
	L1:

;relational exp end

;variable ASSIGNOP logic_expression

	mov ax, t4
	mov n1, ax

;variable ASSIGNOP logic_expression


 ;before push asmvar for println
	push n1
	call println

;relational exp
	mov ax, i1
	cmp ax, j1

;relational exp !=
	jne L2
	mov ax, 0
	mov t5, ax
	jmp L3
	L2:
	mov ax, 1
	mov t5, ax
	L3:

;relational exp end

;variable ASSIGNOP logic_expression

	mov ax, t5
	mov o1, ax

;variable ASSIGNOP logic_expression


 ;before push asmvar for println
	push o1
	call println
	mov ax, n1
	cmp ax, 0
	jne L4
	mov ax, o1
	cmp ax, 0
	jne L4
	mov ax, 0
	mov t6, ax
	jmp L5
	L4:
	mov ax, 1
	mov t6, ax
	L5:

;variable ASSIGNOP logic_expression

	mov ax, t6
	mov p1, ax

;variable ASSIGNOP logic_expression


 ;before push asmvar for println
	push p1
	call println
	mov ax, n1
	cmp ax, 0
	je L6
	mov ax, o1
	cmp ax, 0
	je L6
	mov ax, 1
	mov t7, ax
	jmp L7
	L6:
	mov ax, 0
	mov t7, ax
	L7:

;variable ASSIGNOP logic_expression

	mov ax, t7
	mov p1, ax

;variable ASSIGNOP logic_expression


 ;before push asmvar for println
	push p1
	call println
	mov ax, p1
	mov t8, ax
	inc p1

	;variable INCOP

 ;before push asmvar for println
	push p1
	call println
	mov ax, p1
	mov t9, ax
	neg t9

;variable ASSIGNOP logic_expression

	mov ax, t9
	mov k1, ax

;variable ASSIGNOP logic_expression


 ;before push asmvar for println
	push k1
	call println

;RETURN expression SEMICOLON


;DOS EXIT



	mov ah, 4ch
	int 21h
main endp

