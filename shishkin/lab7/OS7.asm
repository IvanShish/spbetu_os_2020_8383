AStack SEGMENT STACK
	dw 128 dup(0)
Astack ENDS

DATA SEGMENT
	PARAMETER_BLOCK dw 0 ;сегментный адрес среды
                  dd 0 ;сегмент и смещение командной строки
                  dd 0 ;сегмент и смещение FCB 
                  dd 0 ;сегмент и смещение FCB 
                  
	STR_OVERLAY1_NAME db 'OVERLAY1.OVL$'
	STR_OVERLAY2_NAME db 'OVERLAY2.OVL$'
	PROGRAM_PATH db 50 dup(0)
	OFFSET_OVL_NAME dw 0
	DTA_BUFF db 43 dup(0)
	OVL_PARAM_SEG dw 0
	OVL_ADDRESS dd 0
	
	IS_MEMORY_FREED db 0
	STR_FUNCTION_COMPLETED db 'Memory freed', 13, 10, '$'
	STR_FUNC_NOT_COMPLETED db 13, 10, 'Memory is not freed$'
	ERROR_CODE_7 db 13, 10, 'Memory control block destroyed$'
	ERROR_CODE_8 db 13, 10, 'Not enough memory to execute function$'
	ERROR_CODE_9 db 13, 10, 'Invalid memory block address$'
	
	GET_SIZE_ERROR db 13, 10, 'Overlay size not received$'
	GET_SIZE_ERROR_CODE_2 db 13, 10, 'File not found$'
	GET_SIZE_ERROR_CODE_3 db 13, 10, 'Path not found$'
	
	LOADING_ERROR db 13, 10, 'Overlay not loaded$'
	LOADING_ERROR_CODE_1 db 13, 10, 'Non-existent function$'
	LOADING_ERROR_CODE_2 db 13, 10, 'File not found$'
	LOADING_ERROR_CODE_3 db 13, 10, 'Path not found$'
	LOADING_ERROR_CODE_4 db 13, 10, 'Too many open files$'
	LOADING_ERROR_CODE_5 db 13, 10, 'No access$'
	LOADING_ERROR_CODE_8 db 13, 10, 'No memory$'
	LOADING_ERROR_CODE_10 db 13, 10, 'Wrong environment$'

	END_OF_DATAA db 0 
	
DATA ENDS

CODE SEGMENT
	ASSUME CS:CODE, DS:DATA, SS:AStack

;--------------------------------------------------
PRINT PROC near
    push AX
    mov AH, 09h
    int 21h
    pop AX
    ret
PRINT ENDP
;----------------------------------------------
OVERLAY_LOADING PROC near
	call MAKE_FULL_FILE_NAME
	call GET_OVERLAY_SIZE
	call OVERLAYY
	ret
OVERLAY_LOADING ENDP
;----------------------------------------------
MAKE_FULL_FILE_NAME PROC near
	push AX
	push DI
	push SI
	push ES
		
	;mov OFFSET_OVL_NAME, AX
	;mov BX, AX
	mov ES, ES:[2Ch]	;смещение до сегмента окружения (environment)
	xor DI, DI

	NEXT:	;ищем 2 нуля - т.к. строка запуска программы за ними
		mov AL, ES:[DI]
		;inc DI
		cmp AL, 0
		je AFTER_FIRST_0
		inc DI
		jmp NEXT
		
	AFTER_FIRST_0:
		inc DI
		mov AL, ES:[DI]
		cmp AL, 0
		jne NEXT
		add DI, 3h	;нашли 2 нуля, пропускаем 3 цифры
		mov SI, 0
		
	WRITE_NUM:
		mov AL, ES:[DI]
		cmp AL, 0
		je DELETE_FILE_NAME
		mov PROGRAM_PATH[SI], AL
		inc DI
		inc SI
		jmp WRITE_NUM
		
	DELETE_FILE_NAME:
		dec si
		cmp PROGRAM_PATH[SI], '\'
		je READY
		jmp DELETE_FILE_NAME
		
	READY:
		mov DI, -1

	ADD_FILE_NAME:
		inc SI
		inc DI
		;mov AL, OFFSET_OVL_NAME[DI]
		mov AL, BX[DI]
		cmp AL, '$'
		je END_OF_COMMAND_LINE
		mov PROGRAM_PATH[SI], AL
		jmp ADD_FILE_NAME
		
	END_OF_COMMAND_LINE:	
		pop ES
		pop SI
		pop DI
		pop AX
		ret
MAKE_FULL_FILE_NAME ENDP
;----------------------------------------------
GET_OVERLAY_SIZE PROC near
	push AX
	push BX
	push CX
	push DX
	push SI
	
	mov AH, 1Ah
	mov DX, offset DTA_BUFF
    int 21h
	; определение размера требуемой памяти
	mov AH, 4Eh
	mov DX, offset PROGRAM_PATH
	mov CX, 0
	int 21h
	jnc NO_ERRORS
	
	mov DX, offset GET_SIZE_ERROR
	call PRINT
	mov DX, offset GET_SIZE_ERROR_CODE_2
	cmp AX, 2
	je WRITE_TYPE_OF_ERROR
	mov DX, offset GET_SIZE_ERROR_CODE_3
	cmp AX, 3
	je WRITE_TYPE_OF_ERROR
	jmp END_OF_OVL_SIZE
	
	WRITE_TYPE_OF_ERROR:
		call PRINT
		jmp END_OF_OVL_SIZE

	NO_ERRORS:
		mov SI, offset DTA_BUFF
		add SI, 1Ah
		mov BX, [SI]	
		shr BX, 4 
		mov AX, [SI + 2]	
		shl AX, 12
		add BX, AX
		add BX, 2
		mov AH, 48h
		int 21h
		
		jnc SAVE_SEG
		mov DX, offset STR_FUNC_NOT_COMPLETED
		call PRINT
		jmp END_OF_OVL_SIZE

	SAVE_SEG:
		mov OVL_PARAM_SEG, AX

	END_OF_OVL_SIZE:	
		pop SI
		pop DX
		pop CX
		pop BX
		pop AX
		ret
GET_OVERLAY_SIZE ENDP
;----------------------------------------------
OVERLAYY PROC NEAR
	push AX
	push BX
	push DX
	push ES
	
	mov DX, offset PROGRAM_PATH
	push DS
	pop ES
	mov BX, offset OVL_PARAM_SEG
	mov AX, 4B03h            
    int 21h
	
	jnc NO_LOADING_ERRORS
	mov DX, offset LOADING_ERROR
	call PRINT
	mov DX, offset LOADING_ERROR_CODE_1
	cmp AX, 1
	je WRITE_LOADING_OVL_ERROR
	mov DX, offset LOADING_ERROR_CODE_2
	cmp AX, 2
	je WRITE_LOADING_OVL_ERROR
	mov DX, offset LOADING_ERROR_CODE_3
	cmp AX, 3
	je WRITE_LOADING_OVL_ERROR
	mov DX, offset LOADING_ERROR_CODE_4
	cmp AX, 4
	je WRITE_LOADING_OVL_ERROR
	mov DX, offset LOADING_ERROR_CODE_5
	cmp AX, 5
	je WRITE_LOADING_OVL_ERROR
	mov DX, offset LOADING_ERROR_CODE_8
	cmp AX, 8
	je WRITE_LOADING_OVL_ERROR
	mov DX, offset LOADING_ERROR_CODE_10
	cmp AX, 10
	je WRITE_LOADING_OVL_ERROR
	jmp END_OF_OVERLAYY
	
	WRITE_LOADING_OVL_ERROR:
		call PRINT
		jmp END_OF_OVERLAYY
	
	NO_LOADING_ERRORS:
		mov AX, OVL_PARAM_SEG
		mov ES, AX
		mov WORD PTR OVL_ADDRESS + 2, AX
		call OVL_ADDRESS
		mov AH, 49h
		int 21h
	
	END_OF_OVERLAYY:
		pop ES
		pop DX
		pop BX
		pop AX
		ret
OVERLAYY ENDP
;----------------------------------------------
FREEING_UP_MEMORY PROC near
	push AX
	push BX
	push CX
	push DX

	mov BX, offset END_OF_PROGRAM
	mov AX, offset END_OF_DATAA
	add BX, AX
	add BX, 40Fh
	mov CL, 4
	shr BX, CL
	mov AX, 4A00h	;сжать или расширить блок памяти
	int 21h	
	jnc FUNCTION_COMPLETED

	mov DX, offset STR_FUNC_NOT_COMPLETED
	call PRINT
	mov IS_MEMORY_FREED, 0
	cmp AX, 7
	je IF_ERROR_CODE_7
	cmp AX, 8
	je IF_ERROR_CODE_8
	cmp AX, 9
	je IF_ERROR_CODE_9
	
	IF_ERROR_CODE_7:
		mov DX, offset ERROR_CODE_7
		call PRINT
		jmp END_OF_FREEING
	IF_ERROR_CODE_8:
		mov DX, offset ERROR_CODE_8
		call PRINT
		jmp END_OF_FREEING
	IF_ERROR_CODE_9:
		mov DX, offset ERROR_CODE_9
		call PRINT
		jmp END_OF_FREEING

	FUNCTION_COMPLETED:
		mov DX, offset STR_FUNCTION_COMPLETED
		call PRINT
		mov IS_MEMORY_FREED, 1

	END_OF_FREEING:
		pop DX
		pop CX
		pop BX
		pop AX
		ret
FREEING_UP_MEMORY ENDP
;----------------------------------------------
BEGIN PROC FAR
	xor AX, AX
	push AX
	mov AX, DATA
	mov DS, AX
	mov BX, DS
	
	call FREEING_UP_MEMORY
	cmp IS_MEMORY_FREED, 1
	jne ENDD
	; 1-я оверлейная программа
	mov BX, offset STR_OVERLAY1_NAME
	call OVERLAY_LOADING
	; 2-я оверлейная программа
	mov BX, offset STR_OVERLAY2_NAME
	call OVERLAY_LOADING

	ENDD:
		xor AL, AL
		mov AH, 4Ch
		int 21h
BEGIN ENDP
END_OF_PROGRAM:
CODE ENDS
	END BEGIN