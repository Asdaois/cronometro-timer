
#ifndef __RAM
#define __RAM
#include <p16f1787.inc>

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

; Asigna valores en la ram comun desde 0x20
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
	ENDC
#endif
