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
	
;--------------------------------------------------------------------------------------
;--------------------------------------------------------------------------------------
;--------------------------------------------------------------------------------------
;--------------------------------------------------------------------------------------
;--------------------------------------------------------------------------------------
; Configuraciones
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
	movlw 	0xFF
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
	
	banksel IOCAF
	clrf IOCAF
	return	

LimpiarRam
	banksel STATUS
	clrf minutos_decima
	clrf minutos_unidad 
	clrf segundos_decima
	clrf segundos_unidad
	clrf centesimas_decima
	clrf centesimas_unidad
	clrf tiempo_parpadeo	; Tiempo desde ultimo parpadeo 0
	clrf parpadeo_control	; Nadie parpadea
	movlw 0x01 ;Primer LED
	movwf control_7seg 
	return

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
	
AlternarIniciarPararTiempo
	banksel T1CON
	btfss T1CON, TMR1ON 
	goto IniciarTiempo
	goto PararTiempo
;--------------------------------------------------------------------------------------
;--------------------------------------------------------------------------------------
;--------------------------------------------------------------------------------------
;--------------------------------------------------------------------------------------
;--------------------------------------------------------------------------------------
; 7 Segmentos rutinas
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
;--------------------------------------------------------------------------------------
;--------------------------------------------------------------------------------------
;--------------------------------------------------------------------------------------
;--------------------------------------------------------------------------------------
;--------------------------------------------------------------------------------------

	END
