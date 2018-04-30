.data
	file:	   .asciiz "test.txt"
	dictio:    .asciiz "1`abc\n2`defi\n3`defi\n4`a\n" 	#in the format: INDEX ` STRING \n
	string:    .space  4					#remember to always put string_length + 1 for \0
	space:     .asciiz " "
	enter:     .asciiz "\n"
.text

#########################################################################
#	This program will need for comparison:				#
#	-A string in the memory for the dictio				#
#	-A string in a file for comparison (will be saved in string)	#
#	It's totally possible to change this, you just need to change	#
#	the .data area, but keeping the names string and dictio		#
#########################################################################

open_file:
	li $v0, 13			#opening code
	la $a0, file			#string with the file name
	li $a1, 0			#read mode
	li $a2, 0
	syscall
	add $s7, $zero, $v0		#$s7 now contains the file descriptor 
	
read_string:
	li   $v0, 14			#reading file code
	add  $a0, $s7, $zero	 	#add file descriptor to $a0
	la   $a1, string  		#stores the read string to 'string'
	li   $a2, 4		 	#indicates that only four characters will be read
	syscall
	
###################################Comparison begins###################################

#########################################################################
#	$t0 -> address in dictio index					#
#	$t1 -> address in the string index				#
#	$t2 -> character from dictio					#
#	$t3 -> character from string					#
#	$v1 -> how many elements in the dictio are equal to the string	#
#########################################################################

compare_dictionary:
	add  $t0, $zero, $zero		#resets $t0 that will change the address across the dictio
	add  $t1, $zero, $zero		#resets $t1 that will change the address across the string
	add  $v1, $zero, $zero		#resets $v1 that will count how many strings are the same
	
compare_grave:
	lb   $t2, dictio($t0)		#loads the $t0-nth character of dictio to $t2
	beqz $t2, compare_exit		#if $t2 is \0, then the dictionary ended, so it'll exit
	addi $t0, $t0, 1		#adds $t0 to the next address
	beq  $t2, 96, compare_strings	#if the character is equal to `, them it will compare the strings
	j    compare_grave		#if not, it will continue looking for the grave accent
	
compare_strings:
	lb   $t2, dictio($t0)	
	lb   $t3, string($t1)		#loads the $t1-nth character of string to $t3
	
	#######################
	#li $v0, 1			#this area will show all the comparisons it makes between $t2 and $t3
	#add $a0, $t2, $zero
	#syscall
	
	#li $v0, 4
	#la $a0, space
	#syscall
	
	#li $v0, 1
	#add $a0, $t3, $zero
	#syscall
	
	#li $v0, 4
	#la $a0, enter
	#syscall
	#######################
	
	beq  $t2, 10, compare_ends		#if the next character is already \n, go to compare ends
	##if $t2 == \n and $t3 == \0, them the strings are equal
	addi $t1, $t1, 1			#adds $t1 to the next address
	addi $t0, $t0, 1			#it already prepares $t0 to the next address
	bne  $t2, $t3, compare_reset_string	#if the characters aren't equal, it end searching for the \n
	beq  $t2, $t3, compare_strings		#it will keep looking if they are fully equal
	
compare_ends:				#when the character in the dictio is \n, the character in the string needs to be \0
	bnez  $t3, compare_grave	#we already know that $t2 is \n, if $t3 isn't \0, it will go to the next element
	addi  $v1, $v1, 1		#if the ends are equivalent, then the two strings are equal, so it will add up
	j     compare_reset_string
	
compare_reset_string:			#when a search ends, we need to reset the reading of the string
	add  $t1, $zero, $zero
	j    compare_grave
		
	
compare_exit:
###################################Comparison ends###################################	
	
close_file:
	li   $v0, 16			#closing file code
	add  $a0, $s7, $zero		#add file descriptor to a0
	syscall
