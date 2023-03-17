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
	call 	ManejarTicLargo ; Timer 0 suficientemente rapido para hacer barrido del display
	call 	ManejarModo
	goto 	Loop

ManejarTic
	; Aproximadamente cada 0.01 segundo
	banksel 	PIR1
	; Revisar Timer1 Overflow Interrupt Flag bit
	btfss	PIR1,TMR1IF 
	return	; No se ha desbordado
	
	SiModo modo_cronometro_empezo
	call 	Cronometro
	SiModo modo_temporizador_empezo
	call	Temporizador
	
	SiModo modo_configuracion
	call	ControlParpadeo
	SiModo modo_configuracion_minutos
	call	ControlParpadeo
	SiModo modo_configuracion_segundos
	call	ControlParpadeo
	
	bcf 	PIR1, TMR1IF ; Resetear manualmente
	call 	IniciarTiempo
	return

ManejarTicLargo
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
	return
	
	; Paso medio segundo
	clrf 	tiempo_parpadeo
	AlternarBit boleanos, estaParpadeando
	
	; Estoy usandolo como medida de tiempo
	SiModo	modo_configuracion_minutos
	call 	ManejarPulsadorAumentarMinutosContinuo
	
	SiModo	modo_configuracion_segundos
	call 	ManejarPulsadorAumentarSegundosContinuo
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
	call 	ManejarPulsadorEmpezar
	call 	ManejarPulsadorReset
	call 	ManejarPulsadorConfiguracion
	return
	
ManejarModoCronometroEmpezo
	call 	ManejarPulsadorPausa
	call 	ManejarPulsadorReset
	call 	ManejarPulsadorConfiguracion
	return

ManejarModoTemporizadorCorriendo
	call 	ManejarPulsadorConfiguracion
	return
	
ManejarModoTemporizadorPausado
	call 	ManejarPulsadorConfiguracion
	call	ManejarPulsadorIniciarTemporizador
	return
	
ManejarModoConfiguracion
	call 	AlternarCronometroTemporizador
	call 	ManejarPulsadorAtras
	call 	ManejarPulsadorArribaConfiguraSegundos
	call 	ManejarPulsadorAbajoConfiguraMinutos
	return

ManejarModoConfiguracionSegundos
	call 	ManejarPulsadorAumentarSegundos
	call 	ManejarPulsadorAtras
	call 	ManejarPulsadorArribaConfiguraMinutos
	call 	ManejarPulsadorAbajoConfiguraAlternar
	return

ManejarModoConfiguracionMinutos
	call 	ManejarPulsadorAumentarMinutos
	call 	ManejarPulsadorAtras
	call 	ManejarPulsadorArribaConfiguraAlterar
	call 	ManejarPulsadorAbajoConfiguraSegundos
	return

ManejarPulsadorAumentarSegundos
	SiBotonFuePresionadoContinuar Boton_MenuEnter
	call IncrementarSegundos
	return

ManejarPulsadorAumentarMinutos
	SiBotonFuePresionadoContinuar Boton_MenuEnter
	call IncrementarMinutos
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

ManejarPulsadorIniciarTemporizador
	SiBotonFuePresionadoContinuar Boton_StartPausa	
	CambiarModo modo_temporizador_empezo
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

ManejarPulsadorAumentarSegundosContinuo
	banksel 	PORTA
	btfsc	PORTA, Boton_MenuEnter
	return
	; No me gusta esto pero tengo que garantizar que siga activa la interrupcion
	banksel 	IOCAF
	clrf 	IOCAF 
	call IncrementarSegundos
	return

IncrementarSegundos	
	IncrementarYComparar segundos_unidad, 0xA
	btfss 	STATUS, Z 
	return
	
	IncrementarYComparar segundos_decima, 0x6
	return

ManejarPulsadorAumentarMinutosContinuo
	banksel 	PORTA
	btfsc	PORTA, Boton_MenuEnter
	return
	; No me gusta esto pero tengo que garantizar que siga activa la interrupcion
	banksel 	IOCAF
	clrf 	IOCAF 
	call IncrementarMinutos
	return
	
IncrementarMinutos	
	IncrementarYComparar minutos_unidad, 0xA
	btfss 	STATUS, Z 
	return
	
	IncrementarYComparar minutos_decima, 0xA
	; Maximos minutos a contar 99
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

Temporizador
	goto ManejarTemporizadorCentesimasUnidad		
TemporizadorFin
	return
	
ManejarTemporizadorCentesimasUnidad
	SiEsCero	centesimas_unidad
	goto ManejarTemporizadorCentesimasDecima
	decf centesimas_unidad, F
	goto TemporizadorFin	
	
ManejarTemporizadorCentesimasDecima
	SiEsCero	centesimas_decima
	goto ManejarTemporizadorSegundosUnidad
	call CargarMilisegundosUnidad
	decf centesimas_decima, F 
	goto TemporizadorFin

ManejarTemporizadorSegundosUnidad
	SiEsCero	segundos_unidad
	goto ManejarTemporizadorSegundosDecima
	call CargarMilisegundosDecima
	decf segundos_unidad, F 
	goto TemporizadorFin

ManejarTemporizadorSegundosDecima
	SiEsCero	segundos_decima
	goto ManejarTemporizadorMinutosUnidad
	call CargarSegundosUnidad
	decf segundos_decima, F 
	goto TemporizadorFin
	
ManejarTemporizadorMinutosUnidad
	SiEsCero	minutos_unidad
	goto ManejarTemporizadorMinutosDecima
	call CargarSegundosDecima
	decf minutos_unidad, F 
	goto TemporizadorFin

ManejarTemporizadorMinutosDecima
	SiEsCero	minutos_decima
	goto CambiarAModoAlarma
	call CargarMinutosUnidad
	decf minutos_decima, F 
	goto TemporizadorFin

CargarMinutosUnidad
	MoverAF minutos_unidad, 0x9
CargarSegundosDecima
	MoverAF segundos_decima, 0x5
CargarSegundosUnidad
	MoverAF segundos_unidad, 0x9	
CargarMilisegundosDecima
	MoverAF centesimas_decima, 0x9
CargarMilisegundosUnidad
	MoverAF centesimas_unidad, 0x9
	return

CambiarAModoAlarma
	banksel PORTC
	bsf PORTC, RC1
	return
;-----------------------	

#include "Configuraciones.asm"
#include "cronometro.asm"
#include "FuncionesTimer.asm"
#include "7seg.asm"
;--------------------------------------------------------------------------------------
	END
