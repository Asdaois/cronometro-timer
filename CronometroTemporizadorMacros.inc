#include <p16f1787.inc>
#include <RAM.inc>
#ifndef __MACROS
#define __MACROS

IncrementarYComparar macro numero, comparacion
	incf 	numero, F
	movf 	numero, W
	xorlw 	comparacion	; verifico si es igual a comparacion
	btfsc 	STATUS, Z 	; si son iguales limpia el numero			; regresa
	clrf	numero		; Limpia el numero
	endm

SiEsCero macro numero ; agregar 1 al valor para configurar
	movf	numero, W
	xorlw	0x0
	btfsc 	STATUS, Z 	; si son iguales cambia el numero
	endm

MoverValorWSiCoincide macro numero, direccion
	btfsc control_7seg, numero
	movf direccion, W
	endm

; Si los numeros son iguales entoces Z en status es zero
Comparar macro numero, comparacion
	movf	numero, W
	xorlw	comparacion
	endm

MoverAF macro registro, literal
	movlw 	literal
	movwf	registro
	endm

CambiarModo macro modo_nuevo
	movlw 	modo_nuevo
	movwf	modo
	endm

AlternarBit macro registro, bit
	clrf 	helper	; Limpiar helper
	bsf 	helper, bit	; Setear el bit
	movf	helper, W	; pasarlo a w
	xorwf 	registro, F	; xor operacion
	; si bit esta en 1 -> 0
	; si bit esta en 0 -> 1
	; el resto no se modifican
	endm

SiModo macro literal
	movf	modo, W
	xorlw	literal
	btfss	STATUS, Z
	goto $+2
	endm

SiBotonFuePresionadoContinuar macro boton
	banksel 	IOCAF
	btfss 	IOCAF, boton
	return
	
	banksel 	IOCAF
	bcf 	IOCAF, boton	
	endm
#endif