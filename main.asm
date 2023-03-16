#include <p16f1787.inc>
#include "RAM.inc"
#include "CronometroTemporizadorMacros.inc"

;CONFIG1 & CONFIG2
__CONFIG _CONFIG1, _FOSC_INTOSC & _WDTE_OFF & _PWRTE_OFF & _MCLRE_ON & _CP_OFF & _CPD_OFF & _BOREN_ON & _CLKOUTEN_OFF & _IESO_ON & _FCMEN_ON
__CONFIG _CONFIG2, _WRT_OFF & _VCAPEN_OFF & _PLLEN_ON & _STVREN_ON & _BORV_LO & _LPBOR_OFF & _LVP_ON

RST 	code  	0x0 
	goto 	Start

Start
	call 	Configurar
	call 	IniciarTiempo
	goto 	Loop
Loop
	call 	ManejarTic
	call 	ManejarBotonPresionado
	call 	ManejarMostrarDisplay
	goto 	Loop

ManejarTic
	; Aproximadamente cada 0.01 segundo
	banksel 	PIR1
	; Revisar Timer1 Overflow Interrupt Flag bit
	btfss	PIR1,TMR1IF 
	return	; No se ha desbordado
	
	call 	Cronometro
	call	ControlParpadeo
	
	bcf 	PIR1, TMR1IF ; Resetear manualmente
	call 	IniciarTiempo
	return

ManejarMostrarDisplay
	banksel 	INTCON
	; Revisar Timer1 Overflow Interrupt Flag bit
	btfss 	INTCON, TMR0IF 
	return 	; No se ha desbordado
	
	btfsc	boleanos, estaParpadeando
	call	DesactivarDisplay
	
	btfss 	boleanos, estaParpadeando
	call 	Display
	
	bcf 	INTCON, TMR0IF ; Resetear manualmente
	banksel 	TMR0
	movlw	.220
	movwf	TMR0; inicio nuevamente
	return
	
ManejarBotonPresionado
	call 	CronometroControl
	nop
	return


CronometroControl
	call ManejarInicioPausa
	call ManejarReset
	return

ManejarInicioPausa
	banksel 	IOCAF
	btfss 	IOCAF, IOCAF0
	return
	
	call 	AlternarIniciarPararTiempo
	
	banksel 	IOCAF
	bcf 	IOCAF, IOCAF0
	return

ManejarReset
	banksel 	IOCAF
	btfss 	IOCAF, IOCAF1
	return
	
	call LimpiarRam
	call PararTiempo
	
	banksel 	IOCAF
	bcf 	IOCAF, IOCAF1
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

ControlParpadeo
	; Parpadear cada cierto tiempo
	IncrementarYComparar tiempo_parpadeo, medio_segundo
	btfss 	STATUS, Z	
	return	;No ha llegado a medio segundo
	
	; Paso medio segundo
	clrf 	tiempo_parpadeo
	AlternarBit boleanos, estaParpadeando
	
	btfss	boleanos, estaParpadeando ; desactivar puntero
	call DesactivarDisplay
	
	btfsc	boleanos, estaParpadeando ;Activar puntero
	bsf 	control_7seg, 0
	
	return
		
;-----------------------	

#include "Configuraciones.asm"
#include "cronometro.asm"
#include "FuncionesTimer.asm"
#include "7seg.asm"
;--------------------------------------------------------------------------------------
	END
