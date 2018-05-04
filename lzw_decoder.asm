############################################
############# LZW FILE DECODER #############
############################################

.data
	ask_string:  		.asciiz "Enter LZW file name (max 15 chars): "
	file_not_found: 	.asciiz "Error: file not found"
	lzw_file_name: 		.space 15
	dict_file_name:		.space 15
	dict_file_extension: 	.asciiz ".dic"
	newline_char: 		.byte '\n'
	nil_char: 		.byte '\0'
	char:			.byte '\0'
	index_string: 		.space 32
	
.text

# $s0 = LZW FILE DESCRIPTOR
# $s1 = DIC FILE DESCRIPTOR
# $s2 = INDEX READ FROM LZW

# $s7 = TXT FILE NAME LENGTH

#####OPENING FILE#####

ask_file_name:
      	la $a0,ask_string 				# load and print string asking for file name
      	li $v0,4 					# write string
      	syscall

get_file_name:
      	li $v0,8 					# read string
      	la $a0, lzw_file_name 				# load byte space into address
      	li $a1,20 					# max number of chars to read
      	move $t0,$a0 					# save string reference to $t0
      	syscall

	# ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾ #
	# Normalizing file name #
	# _____________________ #

       	la $t0, lzw_file_name
 	lb $t2, newline_char 				# save \n for comparison
 	lb $t3, nil_char 				# save \0 for string cleaning
while_not_newline:
       	lb   $t1, 0($t0)
	beq  $t1, $t2, clean_string
       	addi $t0, $t0, 1
       	j while_not_newline
	
clean_string:
	la $t1, lzw_file_name
	sub $s7, $t0, $t1  				#$s7 now contains the length of lzw file string
	sb $t3, 0($t0)
	
open_lzw_file:
	li $v0, 13 					# open file
    	la $a0, lzw_file_name
    	li $a1, 0					# read-only
	li $a2, 0					# ignoring mode
    	syscall  					# File descriptor gets returned in $v0
    	move $s0, $v0 					# file descriptor saved in $s0
       
check_if_file_is_present:
 	bltz $s0, error_file_not_found

init_dictionary_file:
	addi $t0, $s7, -4 				# trim txt file string so we get file's name without extension
	li $t1, 0
	
dict_while_less_than_string_size:
	bge $t1, $t0, add_dictionary_file_extension 	# while counter is less than txt file string size
	lb $t2, lzw_file_name($t1) 			# get char from txt file name
	sb $t2, dict_file_name($t1) 			# store char in dict file name
	addi $t1, $t1, 1 				# counter++
	j dict_while_less_than_string_size
	
add_dictionary_file_extension:
	la $t0, dict_file_name($t0) 			# get address of last inserted char
	li $t1, 0

loop_dictionary_file_extension:
	bge $t1, 4, open_dictionary_file
	lb $t2, dict_file_extension($t1)
	sb $t2, 0($t0)
	addi $t0, $t0, 1
	addi $t1, $t1, 1
	j loop_dictionary_file_extension



open_dictionary_file:
	li $v0, 13 					# open file
    	la $a0, dict_file_name
    	li $a1, 0					# read-only
	li $a2, 0 					# ignoring mode
    	syscall  					# file descriptor gets returned in $v0	
    	move $s1, $v0 					# file descriptor saved in $s1


#####DECODING#####

reset_index:
	add  $s2, $zero, $zero				# preparing $s2 for the index
	la   $t3, index_string				# $t3 stores the adress across index_string

read_char_from_lzw:
	li $v0, 14 					# read char from file
	move $a0, $s0 					# lzw file descriptor
	la $a1, char					# read char
	li $a2, 1
	syscall

	lb   $t0, char					# loading the read char to $t0
	beq  $t0, '.', ascii_to_integer			# if the char is '.', then the index ended
	sb   $t0, ($t3)					# if it's part of the index, save it to index_string
	addi $t3, $t3, 1				# prepares the next address of index_string
	j    read_char_from_lzw				# jump to read the next char in the index

ascii_to_integer:	
	la $a1, index_string				# prepares the address of index_string
	li $t2, 10					# $t2 is used as a constant 10
	li $v1, 0					# prepares the result storage

loop_ascii_to_integer:         
  	lbu $t1, ($a1)       				# load unsigned char from index_string to $t1
  	beq $t1, $zero, final_integer     		# end of the string
  	addi $t1, $t1, -48   				# converts $t1's ascii value to decimal value
  	mul $v1, $v1, $t2    				# multiply the result by 10
  	add $v1, $v1, $t1    				# sum the result with the next read value
  	addi $a1, $a1, 1     				# increment index_string address
  	j loop_ascii_to_integer				# jump to start of loop
	
final_integer:
	move $s2, $v1					# moves the result to $s2

get_character_from_lzw:
 	
 	
##################

	j end_program

error_file_not_found:
      	la $a0,file_not_found 				# print error
      	li $v0,4 					# write string
      	syscall

end_program:
      	li $v0,10
      	syscall
