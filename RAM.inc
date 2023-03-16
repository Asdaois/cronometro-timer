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
	ENDC

#ifndef __BOLEANOS
#define __BOLEANOS
#define esCronometro 0
#define estaConfigurando 1
#endif
