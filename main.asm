#include <p16f1787.inc>
#include "RAM.inc"

;CONFIG1
;__config 0xFFE1
	__CONFIG _CONFIG1,_FOSC_INTOSC & _WDTE_OFF & _PWRTE_OFF & _MCLRE_ON & _CP_OFF & _BOREN_ON & _CLKOUTEN_OFF & _IESO_ON & _FCMEN_ON
;CONFIG2
;__config 0xDFFF
	__CONFIG _CONFIG2, _WRT_OFF & _VCAPEN_OFF & _PLLEN_ON & _STVREN_ON & _BORV_LO & _LPBOR_OFF & _LVP_OFF

RST 	code  	0x0 
	goto 	Start

Start
	call Configurar

Loop
	call ManejarTic
	call ManejarBotonPresionado
	call ManejarMostrarDisplay
	goto Loop

ManejarTic
	banksel 	PIR1
	; Revisar Timer1 Overflow Interrupt Flag bit
	btfss	PIR1,TMR1IF 
	return	; No se ha desbordado
	
	bcf PIR1, TMR1IF ; Resetear manualmente
	call IniciarTiempo
	return

ManejarBotonPresionado
	banksel IOCAF
	call ManejarInicioPausa
	return

ManejarMostrarDisplay
	banksel INTCON
	; Revisar Timer1 Overflow Interrupt Flag bit
	btfss 	INTCON, TMR0IF 
	return 	; No se ha desbordado
	
	bcf INTCON, TMR0IF ; Resetear manualmente
	return

AlternarIniciarPararTiempo
	banksel T1CON
	btfss T1CON, TMR1ON 
	goto IniciarTiempo
	goto PararTiempo
	
IniciarTiempo
	call ReiniciarTimer
	banksel T1CON
	bsf T1CON, TMR1ON	
	return

PararTiempo
	banksel T1CON
	bcf T1CON, TMR1ON	
	return

ReiniciarTimer
	call PararTiempo
	movlw	0xF6;
	movwf	TMR1H; 
	movlw	0x3C
	movwf	TMR1L
	return
	
ManejarInicioPausa
	btfss IOCAF, IOCAF0
	return
	call AlternarIniciarPararTiempo
	banksel IOCAF
	bcf IOCAF, IOCAF0
	return
	

#include "Configuraciones.asm"
;--------------------------------------------------------------------------------------
	END
