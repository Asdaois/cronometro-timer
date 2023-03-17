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
	CambiarModo modo_cronometro_pausado
	bsf	boleanos, esCronometro
	goto 	Loop
Loop
	call 	ManejarTic
	call 	ManejarModo
	call 	ManejarMostrarDisplay
	goto 	Loop

ManejarTic
	; Aproximadamente cada 0.01 segundo
	banksel 	PIR1
	; Revisar Timer1 Overflow Interrupt Flag bit
	btfss	PIR1,TMR1IF 
	return	; No se ha desbordado
	
	SiModo modo_cronometro_empezo
	call 	Cronometro
	
	SiModo modo_configuracion
	call	ControlParpadeo
	SiModo modo_configuracion_minutos
	call	ControlParpadeo
	SiModo modo_configuracion_segundos
	call	ControlParpadeo
	
	bcf 	PIR1, TMR1IF ; Resetear manualmente
	call 	IniciarTiempo
	return

ManejarMostrarDisplay
	banksel 	INTCON
	; Revisar Timer1 Overflow Interrupt Flag bit
	btfss 	INTCON, TMR0IF 
	return 	; No se ha desbordado
		
	call 	Display
	
	btfsc	boleanos, estaParpadeando
	call	EnmascararPuntero
	
	call 	MostrarCronometroTemporizador
	
	bcf 	INTCON, TMR0IF ; Resetear manualmente
	banksel 	TMR0
	movlw	.240
	movwf	TMR0; inicio nuevamente
	return

ControlParpadeo
	; Parpadear cada cierto tiempo
	IncrementarYComparar tiempo_parpadeo, medio_segundo
	btfss 	STATUS, Z	
	return	;No ha llegado a medio segundo
	
	; Paso medio segundo
	clrf 	tiempo_parpadeo
	AlternarBit boleanos, estaParpadeando
	return

EnmascararPuntero
	SiModo modo_configuracion
	call 	EnmascararTodosLosBits
	SiModo modo_configuracion_segundos
	call 	EnmascararSegundos
	SiModo modo_configuracion_minutos
	call 	EnmascararMinutos
	return

EnmascararTodosLosBits
	banksel 	PORTB
	clrf 	PORTB
	return

EnmascararSegundos
	banksel PORTB
	btfsc	PORTB, RB2
	bcf	PORTB, RB2
	btfsc	PORTB, RB3
	bcf	PORTB, RB3
	return

EnmascararMinutos
	banksel PORTB
	btfsc	PORTB, RB4
	bcf	PORTB, RB4
	btfsc	PORTB, RB5
	bcf	PORTB, RB5
	return
	
ManejarModo
	SiModo modo_cronometro_pausado
	call 	ManejarModoCronometroPausado
	SiModo modo_cronometro_empezo
	call	ManejarModoCronometroEmpezo
	SiModo modo_temporizador_empezo
	call 	ManejarModoTemporizadorCorriendo
	SiModo modo_temporizador_pausado
	call	ManejarModoTemporizadorPausado
	
	SiModo modo_configuracion
	call 	ManejarModoConfiguracion
	SiModo modo_configuracion_segundos
	call 	ManejarModoConfiguracionSegundos
	SiModo modo_configuracion_minutos
	call 	ManejarModoConfiguracionMinutos
	
	return
		
ManejarModoCronometroPausado
	call ManejarPulsadorEmpezar
	call ManejarPulsadorReset
	call ManejarPulsadorConfiguracion
	return
	
ManejarModoCronometroEmpezo
	call ManejarPulsadorPausa
	call ManejarPulsadorReset
	call ManejarPulsadorConfiguracion
	return

ManejarModoTemporizadorCorriendo
	call ManejarPulsadorConfiguracion
	return
	
ManejarModoTemporizadorPausado
	call ManejarPulsadorConfiguracion
	return
	
ManejarModoConfiguracion
	call AlternarCronometroTemporizador
	call ManejarPulsadorAtras
	call ManejarPulsadorArribaConfiguraSegundos
	call ManejarPulsadorAbajoConfiguraMinutos
	return

ManejarModoConfiguracionSegundos
	call ManejarPulsadorAtras
	call ManejarPulsadorArribaConfiguraMinutos
	call ManejarPulsadorAbajoConfiguraAlternar
	return

ManejarModoConfiguracionMinutos
	call ManejarPulsadorAtras
	call ManejarPulsadorArribaConfiguraAlterar
	call ManejarPulsadorAbajoConfiguraSegundos
	return
	
ManejarPulsadorAtras
	SiBotonFuePresionadoContinuar Boton_Atras
	btfsc	boleanos, esCronometro	
	CambiarModo modo_cronometro_pausado
	
	btfss  	boleanos, esCronometro
	CambiarModo modo_temporizador_pausado
	
	bcf	boleanos, estaParpadeando
	return

ManejarPulsadorConfiguracion
	SiBotonFuePresionadoContinuar Boton_MenuEnter
	CambiarModo modo_configuracion
	call LimpiarRam
	return
	
ManejarPulsadorEmpezar
	SiBotonFuePresionadoContinuar Boton_StartPausa
	CambiarModo modo_cronometro_empezo

	return

ManejarPulsadorPausa
	SiBotonFuePresionadoContinuar Boton_StartPausa	
	CambiarModo modo_cronometro_pausado

	return

ManejarPulsadorReset
	SiBotonFuePresionadoContinuar Boton_Reset
	CambiarModo modo_cronometro_pausado
		
	call LimpiarRam

	return

ManejarPulsadorArribaConfiguraAlternar
	SiBotonFuePresionadoContinuar Boton_Arriba
	CambiarModo modo_configuracion
	return

ManejarPulsadorArribaConfiguraSegundos
	SiBotonFuePresionadoContinuar Boton_Arriba
	CambiarModo modo_configuracion_segundos
	return

ManejarPulsadorArribaConfiguraMinutos
	SiBotonFuePresionadoContinuar Boton_Arriba
	CambiarModo modo_configuracion_minutos
	return
	
ManejarPulsadorAbajoConfiguraAlternar
	SiBotonFuePresionadoContinuar Boton_Abajo
	CambiarModo modo_configuracion
	return

ManejarPulsadorAbajoConfiguraMinutos
	SiBotonFuePresionadoContinuar Boton_Abajo
	CambiarModo modo_configuracion_minutos
	return

ManejarPulsadorAbajoConfiguraSegundos
	SiBotonFuePresionadoContinuar Boton_Abajo
	CambiarModo modo_configuracion_segundos
	return
		
MostrarCronometroTemporizador
	banksel PORTB
	btfsc boleanos, esCronometro
	bsf PORTC, RC0
	
	btfss boleanos, esCronometro
	bcf PORTC, RC0
	return

AlternarCronometroTemporizador
	SiBotonFuePresionadoContinuar Boton_MenuEnter
	AlternarBit boleanos, esCronometro
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
;-----------------------	

#include "Configuraciones.asm"
#include "cronometro.asm"
#include "FuncionesTimer.asm"
#include "7seg.asm"
;--------------------------------------------------------------------------------------
	END
