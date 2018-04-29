.data
	ask_string:  		.asciiz "Enter file name (max 15 chars): "
	file_not_found: 	.asciiz "Error: file not found"
	
	newline_char: 		.byte '\n'
	nil_char: 		.byte '\0'
	string: 		.space 21
	txt_file_name: 		.space 15
	dict_file_name:		.space 15
	dict_file_extension: 	.asciiz ".dic"
	LZW_file_name:		.space 15
	LZW_file_extension: 	.asciiz ".lzw"
	

.text

# $s0 = TXT FILE DESCRIPTOR 
# $s1 = DICTIONARY FILE DESCRIPTOR 
# $s2 = LZW FILE DESCRIPTOR 

ask_file_name:
      	la $a0,ask_string # load and print string asking for file name
      	li $v0,4 # write string
      	syscall

get_file_name:
      	li $v0,8 # read string
      	la $a0, txt_file_name # load byte space into address
      	li $a1,20 # max number of chars to read
      	move $t0,$a0 # save string reference to $t0
      	syscall

	# ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾ #
	# Normalizing file name #
	# _____________________ #

       	la $t0, txt_file_name
 	lb $t2, newline_char # save \n for comparison
 	lb $t3, nil_char # save \0 for string cleaning
while_not_newline:
       	lb   $t1, 0($t0)
	beq  $t1, $t2, clean_string
       	addi $t0, $t0, 1
       	j while_not_newline
	
clean_string:
	la $t1, txt_file_name
	sub $s7, $t0, $t1  #$s7 now contains the length of txt file string
	sb $t3, 0($t0)
	

open_txt_file:
	li $v0, 13 # open file
    	la $a0, txt_file_name
    	li $a1, 0 # read-only
	li $a2, 0 # ignoring mode
    	syscall  # File descriptor gets returned in $v0
    	move $s0, $v0 # file descriptor saved in $s0
       
check_if_file_is_present:
 	bltz $s0, error_file_not_found
 	
init_dictionary_file:
	addi $t0, $s7, -4 # trim txt file string so we get file's name without extension
	li $t1, 0
	
dict_while_less_than_string_size:
	bge $t1, $t0, add_dictionary_file_extension # while counter is less than txt file string size
	lb $t2, txt_file_name($t1) # get char from txt file name
	sb $t2, dict_file_name($t1) # store char in dict file name
	addi $t1, $t1, 1 # counter++
	j dict_while_less_than_string_size
	
add_dictionary_file_extension:
	la $t0, dict_file_name($t0) # get address of last inserted char
	li $t1, 0

loop_dictionary_file_extension:
	bge $t1, 4, create_and_open_dictionary_file 
	lb $t2, dict_file_extension($t1)
	sb $t2, 0($t0)
	addi $t0, $t0, 1
	addi $t1, $t1, 1
	j loop_dictionary_file_extension

create_and_open_dictionary_file:
	li $v0, 13 # open file
    	la $a0, dict_file_name
    	li $a1, 1 # write-only with create
	li $a2, 0 # ignoring mode
    	syscall  # File descriptor gets returned in $v0
    	move $s1, $v0 # file descriptor saved in $s1
    	
    	
init_LZW_file:
    	addi $t0, $s7, -4 # trim txt file string so we get file's name without extension
    	li $t1, 0
  
LZW_while_less_than_string_size:
    	bge $t1, $t0, add_LZW_file_extension # while counter is less than txt file string size
    	lb $t2, txt_file_name($t1) # get char from txt file name
    	sb $t2, LZW_file_name($t1) # store char in LZW file name
    	addi $t1, $t1, 1 # counter++
    	j LZW_while_less_than_string_size
  
add_LZW_file_extension:
    	la $t0, LZW_file_name($t0) # get address of last inserted char
    	li $t1, 0

loop_LZW_file_extension:
    	bge $t1, 4, create_and_open_LZW_file 
    	lb $t2, LZW_file_extension($t1)
    	sb $t2, 0($t0)
    	addi $t0, $t0, 1
    	addi $t1, $t1, 1
    	j loop_LZW_file_extension

create_and_open_LZW_file:
 	li $v0, 13 # open file
    	la $a0, LZW_file_name
    	li $a1, 1 # write-only with create
    	li $a2, 0 # ignoring mode
    	syscall  # File descriptor gets returned in $v0
    	move $s2, $v0 # file descriptor saved in $s2
    	
    	
 	# STRING = ""
 	# L1: APPEND CHARACTER FROM FILE TO STRING
 	# IF STRING IS IN DICTIONARY, GOTO L1
 	# IF NOT, PUT STRING IN DICTIONARY WITH ITS INDEX
 	

read_from_file:
    	move $a0, $s0  # file descriptor in $a0
    	li $v0, 14 # read from file
    	la $a1, string # string we're writing in file
	li $a2, 20
    	syscall
    	
print_to_console:
        li $v0,4 # write to console
        la $a0, string # string to write
        syscall

txt_file_close:
	move $a0, $s0  # file descriptor in $a0
    	li $v0, 16  # $a0 already has the txt file descriptor
    	syscall
    	j end_program
    	
dictionary_file_close:
	move $a0, $s1  # file descriptor in $a0
    	li $v0, 16  # $a0 already has the dictionary file descriptor
    	syscall
    	j end_program

error_file_not_found:
      	la $a0,file_not_found # print error
      	li $v0,4 # write string
      	syscall

end_program:
      	li $v0,10
      	syscall
