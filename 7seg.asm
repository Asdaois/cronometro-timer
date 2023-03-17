#include <p16f1787.inc>
#include "CronometroTemporizadorMacros.inc"
Segmentos code

BCD_7seg 
	brw;			xgfe dcba
	retlw 	0x40; 0-> 0100 0000
	retlw 	0x79; 1-> 0111 1001
	retlw 	0x24; 2-> 0010 0100
	retlw 	0x30; 3-> 0011 0000
	retlw 	0x19; 4-> 0001 1001
	retlw 	0x12; 5-> 0001 0010
	retlw 	0x03; 6-> 0000 0011
	retlw 	0x78; 7-> 0111 1000
	retlw 	0x00; 8-> 0000 0000
	retlw 	0x18; 9-> 0001 1000
	nop;	10
	nop;	11
	nop;	12
	nop;	13
	nop;	14
	retlw 	0x7F; apagar todos los displays

Display	
	call 	ManejarPuntero
	return	

ManejarPuntero
	movf 	control_7seg, W
	banksel 	PORTB
	movwf 	PORTB
	
	call PasarValorAlPuerto
	call ReiniciarPuntero
	
	rlf 	control_7seg, F
	btfss 	control_7seg, 6
	return
	
	call ColocarPunteroAlInicio
	return

PasarValorAlPuerto
	call	ObtenerValorEnW
	
	movf 	valor_7seg, W
	call 	BCD_7seg
	banksel 	PORTD
	movwf	PORTD
	return
ReiniciarPuntero
	Comparar	control_7seg, 0x0
	btfss	STATUS, Z
	return
	call ColocarPunteroAlInicio
	return
	
ColocarPunteroAlInicio
	movlw 	0x1
	movwf	control_7seg
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

DesactivarDisplay
	clrf 	control_7seg
	banksel 	PORTB
	clrf	PORTB
	clrf	PORTD
	return	
;------------------------	
	END