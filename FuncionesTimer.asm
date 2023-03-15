#include <p16f1787.inc>
#include "RAM.inc"

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

	END