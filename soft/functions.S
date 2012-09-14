.global delay


delay:	
	beq $zero, $a0, __exit
	addi $a0, $a0, -1
	j delay
__exit:
	jr $ra

