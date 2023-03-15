#include <p16f1787.inc>
#include "RAM.inc"
#include "CronometroTemporizadorMacros.inc"

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
	
	call Cronometro
	
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
	
	call Display
	
	bcf INTCON, TMR0IF ; Resetear manualmente
	banksel TMR0
	movlw	.131
	movwf	TMR0; inicio nuevamente
	return
	
ManejarInicioPausa
	btfss IOCAF, IOCAF0
	return
	call AlternarIniciarPararTiempo
	banksel IOCAF
	bcf IOCAF, IOCAF0
	return

Cronometro
	IncrementarYComparar centesimas_unidad, d'10'
	btfss 	STATUS, Z ; la comparacion fue 10?
	return
	
	IncrementarYComparar centesimas_decima, d'10'
	btfss 	STATUS, Z ; 
	return
	
	IncrementarYComparar segundos_unidad, d'10'
	btfss 	STATUS, Z ; la comparacion fue 10?
	return
	
	IncrementarYComparar segundos_decima, d'6'
	btfss 	STATUS, Z ; la comparacion fue 6?
	return
	
	IncrementarYComparar minutos_unidad, d'10'
	btfss 	STATUS, Z ; la comparacion fue 10?
	return
	
	IncrementarYComparar minutos_decima, d'10'
	; Maximos minutos a contar 99
	return

Display
	movf control_7seg, W
	banksel PORTB
	movwf PORTB
	
	rlf control_7seg, F
	btfss control_7seg, 6
	return
	
	movlw 0x01
	movwf control_7seg
	return	

;-----------------------	

#include "Configuraciones.asm"
#include "FuncionesTimer.asm"
#include "7seg.asm"
;--------------------------------------------------------------------------------------
	END
