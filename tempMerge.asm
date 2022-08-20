
;main start
main proc
	mov ax, @data
	mov ds, ax


;variable ASSIGNOP logic_expression

	mov ax, 3
	mov i1, ax

;variable ASSIGNOP logic_expression


;variable ASSIGNOP logic_expression

	mov ax, 8
	mov j1, ax

;variable ASSIGNOP logic_expression


;variable ASSIGNOP logic_expression

	mov ax, 6
	mov k1, ax

;variable ASSIGNOP logic_expression


;relational exp
	mov ax, i1
	cmp ax, 3

;relational exp ==
	je L0
	mov ax, 0
	mov t0, ax
	jmp L1
	L0:
	mov ax, 1
	mov t0, ax
	L1:

;relational exp end
	mov ax, t0
	cmp ax, 0
	je L2

 ;before push asmvar for println
	push j1
	call println
L2:

;if then end


;relational exp
	mov ax, j1
	cmp ax, 8

;relational exp <
	jl L3
	mov ax, 0
	mov t1, ax
	jmp L4
	L3:
	mov ax, 1
	mov t1, ax
	L4:

;relational exp end
	mov ax, t1
	cmp ax, 0
	je L5

 ;before push asmvar for println
	push i1
	call println
	jmp L6
L5:

 ;before push asmvar for println
	push k1
	call println
L6:

;if then else end


;relational exp
	mov ax, k1
	cmp ax, 6

;relational exp !=
	jne L7
	mov ax, 0
	mov t2, ax
	jmp L8
	L7:
	mov ax, 1
	mov t2, ax
	L8:

;relational exp end
	mov ax, t2
	cmp ax, 0
	je L9

 ;before push asmvar for println
	push k1
	call println
	jmp L10
L9:

;relational exp
	mov ax, j1
	cmp ax, 8

;relational exp >
	jg L11
	mov ax, 0
	mov t3, ax
	jmp L12
	L11:
	mov ax, 1
	mov t3, ax
	L12:

;relational exp end
	mov ax, t3
	cmp ax, 0
	je L13

 ;before push asmvar for println
	push j1
	call println
	jmp L14
L13:

;relational exp
	mov ax, i1
	cmp ax, 5

;relational exp <
	jl L15
	mov ax, 0
	mov t4, ax
	jmp L16
	L15:
	mov ax, 1
	mov t4, ax
	L16:

;relational exp end
	mov ax, t4
	cmp ax, 0
	je L17

 ;before push asmvar for println
	push i1
	call println
	jmp L18
L17:

;variable ASSIGNOP logic_expression

	mov ax, 0
	mov k1, ax

;variable ASSIGNOP logic_expression


 ;before push asmvar for println
	push k1
	call println
L18:

;if then else end

L14:

;if then else end

L10:

;if then else end


;RETURN expression SEMICOLON


;DOS EXIT



	mov ah, 4ch
	int 21h
main endp

