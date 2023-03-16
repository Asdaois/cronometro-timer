#include <p16f1787.inc>
#include "RAM.inc"
FuncionesTimer code
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
	movlw	0xFF;
	movwf	TMR1H; 
	movlw	0x06
	movwf	TMR1L
	return

#include "7seg.asm"
	END