#include <p16f1787.inc>

;--------------------------------------------------------------------------------------
;--------------------------------------------------------------------------------------
;--------------------------------------------------------------------------------------
;--------------------------------------------------------------------------------------
;--------------------------------------------------------------------------------------
;Constantes y definicion de memoria
#define esCronometro 0
#define estaConfigurando 1
#define estaParpadeando 2
#define parpadeo_ninugno 0x0
#define parpadeo_todos 0x1
#define parpadeo_segundos 0x2
#define parpadeos_minutos 0x3
#define medio_segundo 0x19 ; 50 ticks aproximadamente .5 segundos

#define modo_cronometro_pausado 0x0
#define modo_cronometro_empezo 0x1
#define modo_temporizador_empezo 0x3
#define modo_temporizador_pausado 0x4
#define modo_configuracion 0x2
#define modo_configuracion_segundos 0x5
#define modo_configuracion_minutos 0x6
#define modo_alarma 0x7

Boton_StartPausa	equ	RA0
Boton_Reset	equ	RA1
Boton_MenuEnter	equ	RA2
Boton_Arriba 	equ	RA3
Boton_Abajo	equ	RA4
Boton_Atras	equ	RA5
BancoConfiguracionTemporizador	equ	PORTA	; Banco 0

; Asigna valores en la ram comun desde 0x70
CBLOCK 0x70
	minutos_decima
	minutos_unidad 
	segundos_decima
	segundos_unidad
	centesimas_decima
	centesimas_unidad 
	control_7seg
	valor_7seg
	boleanos
	tiempo_parpadeo
	parpadeo_control
	helper
	modo
	tics_contador		; 100 tics == 1 segundo
	tiempo_diez_segundos	; idealmente debera tener un valor de 10, aumenta cada 100 tics
ENDC

; Asigna valores en la memoria general del banco 0
CBLOCK 0x20
	temporizador_minutos_decima
	temporizador_minutos_unidad 
	temporizador_segundos_decima
	temporizador_segundos_unidad
ENDC
;--------------------------------------------------------------------------------------
;--------------------------------------------------------------------------------------
;--------------------------------------------------------------------------------------
;--------------------------------------------------------------------------------------
;--------------------------------------------------------------------------------------
;Macros; para facilitar la escritura del codigo

; Incrementa un valor en una direccion
; Luego compara si ese valor es igual a un numero
; Si el numero es igual convierte el valor a 0
; Se utiliza para programar la funcionalidad basica del cronometro
; Ejemplo:
;	Si el valor es 9
; 		Aumenta el valor a 10
;		Si el valor es 10
;			Convierte el valor a 0
IncrementarYComparar macro registro, numero_comparar
	incf 	registro, F
	movf 	registro, W
	xorlw 	numero_comparar	; verifico si es igual a comparacion
	btfsc 	STATUS, Z 	; si son iguales limpia el numero			; regresa
	clrf	registro		; Limpia el numero
	endm

; Compara si el valor dentro de un registro es igual a 0
; Si no es cero salta la siguiente instruccion
; motivacion: Escribir esta comparacion a cada rato es ladilloso
; Ejemplo:
;	Si el valor de segundos es 0
;		Pedir prestado a minutos
;	Si no
;		segundos--
SiEsCero macro registro ; agregar 1 al valor para configurar
	movf	registro, W
	xorlw	0x0
	btfsc 	STATUS, Z 	; si son iguales cambia el numero
	endm

; control_7seg: el valor actual del puntero que se utiliza para actualizar los 7segmentos
; numero: el bit actual en que se encuentra el control_7seg se usa para propositos ed comparacion
; registro: el registro en donde se encuentra el valor actual que deberia tener el 7segmentos
; Ejemplo:
;	Si el bit actual es 2 ("correspondiente a segundos unidad")
;		Mueve el valor de segundos unidad a W
;	Si no
;		No hacer nada
MoverValorWSiCoincide macro numero, registro
	btfsc control_7seg, numero
	movf registro, W
	endm
	
; Realiza una comparacion usando XOR
; Usa el valor que se encuentra en un registro, 
; Y un literal numero a comparar para realizar una comparacion de valores
; Si los numeros son iguales entoces Z en status es zero
; Motivacion: Comparar es una operacion muy comun
Comparar macro registro, numero_comparar
	movf	registro, W
	xorlw	numero_comparar
	endm

; Mueve el valor de un literal a un registro
MoverAF macro registro, literal
	movlw 	literal
	movwf	registro
	endm

; Alternar el valor de un bit, es una operacion bastante larga
; Con esto podemos alternar el valor de un bit dentro de un registro cualquiera
AlternarBit macro registro, bit
	clrf 	helper	; Limpiar helper
	bsf 	helper, bit	; Setear el bit
	movf	helper, W	; pasarlo a w
	xorwf 	registro, F	; xor operacion
	; si bit esta en 1 -> 0
	; si bit esta en 0 -> 1
	; el resto no se modifican
	endm

; El codigo funciona haciendo una maquina de estado simple
; Para cambiar el modo de funcionamiento actual se utiliza este macro	
CambiarModo macro modo_nuevo
	movlw 	modo_nuevo
	movwf	modo
	banksel 	IOCAF
	clrf 	IOCAF
	endm

; Se creo un If bloque
; Basicamente pregunta si el modo es diferente al modo actual
; Se puede utilizar Comparar, pero como el modo de funcionamiento siempre esta en la direccion de modo
; este metodo es preferible, si el 	modo a comparar es distinto al actual
; la siguiente instruccion es saltada	
SiModo macro modo_actual
	movf	modo, W
	xorlw	modo_actual
	btfss	STATUS, Z
	goto $+2
	endm

SiBotonFuePresionadoContinuar macro boton
	banksel 	IOCAF
	btfss 	IOCAF, boton
	return
	
	banksel 	IOCAF
	bcf 	IOCAF, boton	
	endm
;--------------------------------------------------------------------------------------
;--------------------------------------------------------------------------------------
;--------------------------------------------------------------------------------------
;--------------------------------------------------------------------------------------
;--------------------------------------------------------------------------------------
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
	
	btfsc	boleanos, esCronometro
	call	LimpiarRam
	
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
