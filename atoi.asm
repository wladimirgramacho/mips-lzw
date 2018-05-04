.data
	file: .asciiz "test.txt"
	char: .space 1
	number: .asciiz "abc"
.text

la $s1, number
li $t0, 10
li $s2, 0

lp:         
  lbu $t1, ($s1)       #load unsigned char from array into t1
  beq $t1, $0, FIN     #NULL terminator found
  addi $t1, $t1, -48   #converts t1's ascii value to dec value
  mul $s2, $s2, $t0    #sum *= 10
  add $s2, $s2, $t1    #sum += array[s1]-'0'
  addi $s1, $s1, 1     #increment array address
  j lp                 #jump to start of loop
  
error:
 addi $v1, $zero, -88
FIN:
 li $v0, 1
 move $a0, $s2
 syscall