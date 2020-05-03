CODE SEGMENT
	ASSUME CS:CODE, DS:NOTHING, SS:NOTHING, ES:NOTHING
	
;----------------------------------------------
BEGIN PROC FAR
	push AX
	push DX
	push DS
	push DI
	
	mov AX, CS
	mov DS, AX
	mov DX, offset IF_LOAD
	call PRINT
	
	mov DI, offset SEGMENT_ADDRESS
	add DI, 22
	call WRD_TO_HEX
	
	mov DX, offset SEGMENT_ADDRESS
	call PRINT
	
	pop DI
	pop DS
	pop DX
	pop AX
	
	RETF
BEGIN ENDP
;--------------------------------------------------
PRINT PROC near
    push AX
    mov AH, 09h
    int 21h
    pop AX
    ret
PRINT ENDP
;----------------------------------------------
TETR_TO_HEX PROC near
   and AL, 0Fh
   cmp AL, 09
   jbe next
   add AL, 07
next:
   add AL, 30h
   ret
TETR_TO_HEX ENDP
;----------------------------------------------
BYTE_TO_HEX PROC near
;байт в AL переводится в два символа шест. числа в AX
   push CX
   mov AH, AL
   call TETR_TO_HEX
   xchg AL, AH
   mov CL, 4
   shr AL, CL
   call TETR_TO_HEX ;в AL старшая цифра
   pop CX ;в AH младшая
   ret
BYTE_TO_HEX ENDP
;----------------------------------------------
WRD_TO_HEX PROC near
;перевод в 16 с/с 16-ти разрядного числа
; в AX - число, DI - адрес последнего символа
   push BX
   mov BH, AH
   call BYTE_TO_HEX
   mov [DI], AH
   dec DI
   mov [DI], AL
   dec DI
   mov AL, BH
   call BYTE_TO_HEX
   mov [DI], AH
   dec DI
   mov [DI], AL
   pop BX
   ret
WRD_TO_HEX ENDP
;--------------------------------------------------
	IF_LOAD db 13, 10, 'OVERLAY1 loaded$'
	SEGMENT_ADDRESS db 13, 10, 'Segment address:        $'
;--------------------------------------------------
CODE ENDS
	END BEGIN