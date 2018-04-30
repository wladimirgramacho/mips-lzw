.data
	file:	   .asciiz "test.txt"
	character: .space  4
	string:	   .asciiz "The quick brown fox jumps over the lazy doh."
	
.text

open_file:
	li $v0, 13		#opening code
	la $a0, file		#string with the file name
	li $a1, 0		#read mode
	li $a2, 0
	syscall
	add $s7, $zero, $v0	#$s7 now contains the file descriptor 
	
read_character:
	li   $v0, 14			#reading file code
	add  $a0, $s7, $zero	 	#add file descriptor to $a0
	la   $a1, character	  	#stores the read character to 'character'
	li   $a2, 1		 	#indicates that only one character will be read
	syscall
	
###################################Comparison begins###################################

compare_characters:
	add   $t0, $zero, $zero		#resets $t0 that will change the address across the string
	add   $t3, $zero, $zero		#resets $t3 that will count how many characters in the string are equal to the character
	lb    $t1, character		#loads the character to $t1
compare_loop:				
	lb    $t2, string($t0)			#loads the current character on the string to $t2
	beq   $t2, $zero, compare_exit		#if the character on the string is zero (null = '\0' = 0), it will exit the loop
	bne   $t1, $t2, compare_continue	#if the characters aren't equal, it will just continue the loop
	addi  $t3, $t3, 1			#if they are equal, $t3 plus one
compare_continue:	
	addi  $t0, $t0, 1
	j     compare_loop
compare_exit:

###################################Comparison ends###################################

close_file:
	li   $v0, 16		#closing file code
	add  $a0, $s7, $zero	#add file descriptor to a0
	syscall
