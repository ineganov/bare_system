.globl _start
.org 0

_start:
	li $sp, 0xFFFFFFFF #init stack pointer
	li $gp, 0x80000000 #init global pointer

	jal main #jump to main
	
	sw $v0, 0x00000004 #write main return value to leds

_stop:			#loop forever
	j _stop

