#include <p16f1787.inc>
#include "RAM.inc"
#include "CronometroTemporizadorMacros.inc"

;CONFIG1 & CONFIG2
__CONFIG _CONFIG1, _FOSC_INTOSC & _WDTE_OFF & _PWRTE_OFF & _MCLRE_ON & _CP_OFF & _CPD_OFF & _BOREN_ON & _CLKOUTEN_OFF & _IESO_ON & _FCMEN_ON
__CONFIG _CONFIG2, _WRT_OFF & _VCAPEN_OFF & _PLLEN_ON & _STVREN_ON & _BORV_LO & _LPBOR_OFF & _LVP_ON

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
	movlw	.220
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
	IncrementarYComparar centesimas_unidad, 0xA
	btfss 	STATUS, Z 
	return
	
	IncrementarYComparar centesimas_decima, 0xA
	btfss 	STATUS, Z 
	return
	
	IncrementarYComparar segundos_unidad, 0xA
	btfss 	STATUS, Z 
	return
	
	IncrementarYComparar segundos_decima, 0x6
	btfss 	STATUS, Z 
	return
	
	IncrementarYComparar minutos_unidad, 0xA
	btfss 	STATUS, Z 
	return
	
	IncrementarYComparar minutos_decima, 0xA
	; Maximos minutos a contar 99
	return

	
Display	
	call	ObtenerValorEnW
	
	movf 	valor_7seg, W
	call 	BCD_7seg
	banksel 	PORTD
	movwf	PORTD
	
	call 	ManejarPuntero
	return	

ManejarPuntero
	movf 	control_7seg, W
	banksel 	PORTB
	movwf 	PORTB
	
	rlf 	control_7seg, F
	btfss 	control_7seg, 6
	return
	
	movlw 	0x1
	movwf 	control_7seg
	return
	
ObtenerValorEnW
	clrw
	MoverValorWSiCoincide 0, centesimas_unidad
	MoverValorWSiCoincide 1, centesimas_decima
	MoverValorWSiCoincide 2, segundos_unidad
	MoverValorWSiCoincide 3, segundos_decima
	MoverValorWSiCoincide 4, minutos_unidad
	MoverValorWSiCoincide 5, minutos_decima
	movwf valor_7seg
	return

;-----------------------	

#include "Configuraciones.asm"
#include "FuncionesTimer.asm"
#include "7seg.asm"
;--------------------------------------------------------------------------------------
	END
