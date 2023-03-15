#include <p16f1787.inc>
#include "RAM.inc"
	code
Configurar
	call ConfigurarInterrupciones
	call ConfigurarPuertos
	call LimpiarRam
	return
	
;Habilitaci¢n de interrupciones externas y del timer.
ConfigurarInterrupciones
	banksel INTCON
	; INTERRUPT CONTROL REGISTER
	movlw	0xE8	; 1110 1000
	movwf	INTCON	; habilitados gie, PEIE tm
	; T1CON: TIMER1 CONTROL REGISTER
	movlw	0x20	; prescalador 1:4 TMR1
	movwf	T1CON
	; PIEI: PERIPHERAL INTERRUPT ENABLE REGISTER 1
	banksel	PIE1
	movlw	0x01	
	movwf	PIE1	; interrupcion por TMR1 activa
	; OPTION REG: OPTION REGISTER
	movlw	0X03	; prescalador 1:16 TMR0
	movwf	OPTION_REG	;prescalador
	
	return

ConfigurarPuertos
	; Puertos como E/S digital
	banksel 	ANSELA	
	clrf 	ANSELA
	clrf 	ANSELB
	clrf 	ANSELD
	
	banksel 	TRISA
	; Entradas A
	movlw 	0xFF
	movwf 	TRISA
	; Pull-up
	banksel 	WPUA
	movlw 	0x07
	movwf 	WPUA
	; INTERRUPT-ON-CHANGE NEGATIVE EDGE REGISTER
	banksel IOCAN
	movlw	0xFF
	movwf	IOCAN	;flanco de bajada para RA0, RA1 y RA2
	
	banksel TRISB
	; Salidas B, C, D
	clrf 	TRISB
	clrf 	TRISC
	clrf 	TRISD
	
	banksel 	LATB
	clrf	LATB
	clrf	LATC
	clrf	LATD
	
	; Limpiar puertos
	banksel PORTB
	clrf PORTB
	clrf PORTC
	clrf PORTD
	return	

LimpiarRam
	clrf minutos_decima
	clrf minutos_unidad 
	clrf segundos_decima
	clrf segundos_unidad
	clrf centesimas_decima
	clrf centesimas_unidad 
	return
#include "FuncionesTimer.asm"	
;-----------------------	
	END