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
	call 	ManejarTic	; Timer 1 aproximadamente 0.01
	call 	ManejarTicLargo 	; Timer 0 suficientemente rapido para hacer barrido del display
	call	ManejarTicContador
	call 	ManejarModo
	goto 	Loop

ManejarTic
	; Aproximadamente cada 0.01 segundo
	banksel 	PIR1
	; Revisar Timer1 Overflow Interrupt Flag bit
	btfss	PIR1,TMR1IF 
	return	; No se ha desbordado
	
	incf	tics_contador	; Contar numeros de tic actuales
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

ManejarTicContador
	Comparar tics_contador, 0x64	; cada 1 segundo	
	btfss	STATUS, Z	; si no es igual a 100
	return
	
	clrf tics_contador	; restear contador
	
	SiModo	modo_alarma
	incf	tiempo_diez_segundos, F
	
	SiModo	modo_alarma	; alternar cada segundo
	call 	AlternarAlarmaDisplay
	return

AlternarAlarmaDisplay
	banksel PORTC
	AlternarBit PORTC, RC1
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
	
	SiModo modo_alarma
	Call	ManejarModoAlarma
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
	call	ManejarPulsadorPausarTemporizador
	call	ManejarPulsadorResetTemporizador	;Esto cambia el temporizador a modo pausado
	return
	
ManejarModoTemporizadorPausado
	call 	ManejarPulsadorConfiguracion
	call	ManejarPulsadorIniciarTemporizador
	call	ManejarPulsadorResetTemporizador
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

ManejarModoAlarma
	call	ManejarAlarmaVencioDiezSegundos
	call	ManejarCualquierBotonFuePresionado
	return

ManejarAlarmaVencioDiezSegundos
	Comparar tiempo_diez_segundos, 0xA	;Pasaron 10 segundos?
	btfss	STATUS, Z
	return  ; No han pasado
	
	call 	SalirModoAlarma
	call	ReiniciarTemporizador
	return

ManejarCualquierBotonFuePresionado
	banksel 	IOCAF
	Comparar IOCAF, 0x00
	btfsc 	STATUS, Z	; Si es 0 un boton fue presionado
	return
	
	; Cada vez que se cambia el modo se limpia las interrupciones
	call	SalirModoAlarma	
	call	ReiniciarTemporizador
	return
	
ReiniciarTemporizador
	CambiarModo modo_temporizador_pausado
	call	CargarConfiguracionTemporizador
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
	
	btfss 	boleanos, esCronometro
	call	GuardarConfiguracionTemporizador
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

ManejarPulsadorResetTemporizador
	SiBotonFuePresionadoContinuar Boton_Reset
	call	ReiniciarTemporizador
	return
	
ManejarPulsadorIniciarTemporizador
	SiBotonFuePresionadoContinuar Boton_StartPausa	
	CambiarModo modo_temporizador_empezo
	return

ManejarPulsadorPausarTemporizador
	SiBotonFuePresionadoContinuar Boton_StartPausa	
	CambiarModo modo_temporizador_pausado
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
	CambiarModo modo_alarma
	
	clrf	tiempo_diez_segundos ;reiniciar
	return

SalirModoAlarma
	; Solo garantiza que el display este apagado
	banksel 	PORTC
	bcf 	PORTC, RC1
	return

GuardarConfiguracionTemporizador
	banksel	BancoConfiguracionTemporizador	; Seleccionar banco 0 
	movf	minutos_decima, W
	movwf	temporizador_minutos_decima
	movf	minutos_unidad, W 
	movwf	temporizador_minutos_unidad
	movf	segundos_decima, W
	movwf	temporizador_segundos_decima
	movf	segundos_unidad, W
	movwf	temporizador_segundos_unidad
	return
	
CargarConfiguracionTemporizador
	banksel	BancoConfiguracionTemporizador	; Seleccionar banco 0 
	movf	temporizador_minutos_decima, W
	movwf	minutos_decima
	movf	temporizador_minutos_unidad, W 
	movwf	minutos_unidad	
	movf	temporizador_segundos_decima, W
	movwf	segundos_decima
	movf	temporizador_segundos_unidad, W
	movwf	segundos_unidad
	clrf	centesimas_decima
	clrf	centesimas_unidad
	return
;-----------------------	

#include "Configuraciones.asm"
#include "cronometro.asm"
#include "FuncionesTimer.asm"
#include "7seg.asm"
;--------------------------------------------------------------------------------------
	END
