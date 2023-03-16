#include <p16f1787.inc>
#include <RAM.inc>
#ifndef __MACROS
#define __MACROS

IncrementarYComparar macro numero, comparacion
	incf 	numero, F
	movf 	numero, W
	xorlw 	comparacion	; verifico si es igual a comparacion
	btfsc 	STATUS,2 	; si son iguales limpia el numero			; regresa
	clrf	numero		; Limpia el numero
	endm

MoverValorWSiCoincide macro numero, direccion
	btfsc control_7seg, numero
	movf direccion, W
	endm

#endif