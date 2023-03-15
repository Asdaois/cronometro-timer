#include <p16f1787.inc>

IncrementarYComparar macro numero, comparacion
	incf 	numero, F
	movf 	numero, W
	xorlw 	comparacion	; verifico si es igual a comparacion
	btfsc 	STATUS,2 	; si son iguales limpia el numero			; regresa
	clrf	numero		; Limpia el numero
	endm