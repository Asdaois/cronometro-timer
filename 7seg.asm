#include <p16f1787.inc>
#include "RAM.inc"

code
BCD_7seg
	brw		;xgfe dcba
	retlw 0x40	; 0-> 0100 0000
	retlw 0x79	; 1-> 0111 1001
	retlw 0x24	; 2-> 0010 0100
	retlw 0x30	; 3-> 0011 0000
	retlw 0x19	; 4-> 0001 1001
	retlw 0x12	; 5-> 0001 0010
	retlw 0x03	; 6-> 0000 0011
	retlw 0x78	; 7-> 0111 1000
	retlw 0x00	; 8-> 0000 0000
	retlw 0x18	; 9-> 0001 1000
	nop;	10
	nop;	11
	nop;	12
	nop;	13
	nop;	14
	retlw 0x7F; apagar todos los displays
	
	END