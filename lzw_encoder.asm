############################################
############# LZW FILE ENCODER #############
############################################

.data
	ask_string:  		.asciiz "Enter txt file name to encode (max 15 chars): "
	file_not_found: 	.asciiz "Error: file not found"
	
	line_separator:		.byte '`'
	newline_char:		.byte '\n'
	nil_char: 		.byte '\0'
	separator_char:		.byte '.'
	char:	 		.space 1
	string:			.space 40
	txt_file_name: 		.space 15
	dict_file_name:		.space 15
	dict_file_extension: 	.asciiz ".dic"
	LZW_file_name:		.space 15
	LZW_file_extension: 	.asciiz ".lzw"
	integer_to_s:		.space 32
	dict_empty_string:	.asciiz "0.`"
	
.text

# $s0 = TXT FILE DESCRIPTOR 
# $s1 = DICTIONARY FILE DESCRIPTOR 
# $s2 = LZW FILE DESCRIPTOR 
# $s3 = DICTIONARY INDEX
# $s4 = 1 IF READ CHAR FROM TXT. 0 IF EOF.
# $s5 = LAST STRING FOUND INDEX
# $s6 = TEMPORARY $ra
# $s7 = TXT FILE NAME LENGTH

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
 	lb $t2, newline_char	 # save '\n' for comparison
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
	bge $t1, 4, create_and_write_dictionary_file
	lb $t2, dict_file_extension($t1)
	sb $t2, 0($t0)
	addi $t0, $t0, 1
	addi $t1, $t1, 1
	j loop_dictionary_file_extension
	
create_and_write_dictionary_file:
	li $v0, 13 # open file
    	la $a0, dict_file_name
    	li $a1, 1 # write-only with create
	li $a2, 0 # ignoring mode
    	syscall  # File descriptor gets returned in $v0	
    	move $s1, $v0 # file descriptor saved in $s1

	li $v0, 15 # write to file
    	move $a0, $s1			# file descriptor
    	la $a1, dict_empty_string # writing "0.`" to dictionary
	li $a2, 3
    	syscall  # File descriptor gets returned in $v0	
	
closing_created_dictionary_file:
	move $a0, $s1  	# file descriptor in $a0
    	li $v0, 16  	# $a0 already has the dictionary file descriptor
    	syscall	
    	
open_read_only_dictionary_file:
	li $v0, 13 # open file
    	la $a0, dict_file_name
    	li $a1, 0 # read-only
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
 	
	move $fp, $sp # saving heap start
	add $s3, $zero, $zero # INIT INDEX DICTIONARY
	add $t9, $zero, $zero # reset EOF flag
	addi $t5, $zero, -1		# reset $t5 that will count index of dictionary string

read_one_char_from_txt_file:
	li $v0, 14 # read from file
	move $a0, $s0 # txt file descriptor
	la $a1, char # read char
	li $a2, 1
	syscall
	move $s4, $v0
	beqz $s4, comparison_string_present			# if didn't get any chars, check if there's a string to write in dic	

store_char_on_heap:
	lb $t0, char # $t0 = char
	addi $sp, $sp, -1 # open space for one char
	sb $t0, 0($sp)
	
reverse_string:
	sub 	$t1, $fp, $sp
	li	$t0, 0			# Set t0 to zero
	li	$t3, 0			# and the same for t3
	add	$t2, $zero, $sp		# $t2 is base of $sp	
	
reverse_loop:	
	add	$t3, $t2, $t0		# $t2 is the base address for our 'input' array, add loop index
	lb	$t4, 0($t3)		# load a byte at a time according to counter
	beqz	$t4, is_string_on_dictionary # We found the null-byte
	sb	$t4, string($t1)		# Overwrite this byte address in memory	
	subi	$t1, $t1, 1		# Subtract our overall string length by 1 (j--)
	addi	$t0, $t0, 1		# Advance our counter (i++)
	j	reverse_loop		# Loop until we reach our condition

is_string_on_dictionary:
	jal find_string_on_dictionary
	beq $v1, 1, read_one_char_from_txt_file # if found, get one char more
	addi $t5, $zero, -1		# reset $t5 that will count index of dictionary string
	
write_to_LZW:

print_index_to_LZW:
	add   $a0, $zero, $s5
	jal  itoa
	move $a1, $v0 		# save string we're writing
	jal get_string_size
  	move   $a2, $v0		# save string size to number of elements we're writing
  	li   $v0, 15       	# write to file
  	move $a0, $s2     	 # file descriptor 
  	syscall
  	
print_separator_to_LZW:
  	li   $v0, 15       	# write to file 	
  	move $a0, $s2		# file descriptor
  	la $a1, separator_char  # get separator char to write
  	addi $a2, $zero, 1	# number of chars to write
  	syscall
  	beq $t9, 1, txt_file_close
  	
print_char_to_LZW:
  	li   $v0, 15       	# write to file 	
  	move $a0, $s2		# file descriptor
  	la $a1, 0($sp)		# get separator char to write
  	addi $a2, $zero, 1	# number of chars to write
  	syscall
  	
reset_$s5:
	add $s5, $zero, $zero

close_dictionary_from_reading:
	move $a0, $s1  # file descriptor in $a0
    	li $v0, 16  # $a0 already has the dictionary file descriptor
    	syscall

open_dictionary_for_writing:
 	li $v0, 13 # open file
    	la $a0, dict_file_name
    	li $a1, 9 # write-only with create and append
    	li $a2, 0 # ignoring mode
    	syscall  # File descriptor gets returned in $v0
    	move $s1, $v0 # file descriptor saved in $s1
    	
add_string_to_dic:
	jal label_to_save_$ra_value		# $ra = next line
	la $s6, 12($ra) 				# saving $ra value on $s6
	j print_index_to_dic

close_dictionary_from_writing:
	move $a0, $s1  # file descriptor in $a0
    	li $v0, 16  # $a0 already has the dictionary file descriptor
    	syscall

open_dictionary_for_reading:
 	li $v0, 13 # open file
    	la $a0, dict_file_name
    	li $a1, 0 # read-only
    	li $a2, 0 # ignoring mode
    	syscall  # File descriptor gets returned in $v0
    	move $s1, $v0 # file descriptor saved in $s1	
    		
	lb $t0, nil_char
clean_heap:
	beq $sp, $fp, clean_heap_end
	sb $t0, 0($sp)		# reset space to '\0' char
	addi $sp, $sp, 1	# remove space from heap
	j clean_heap

clean_heap_end:
	la $t1, string
	addi $t1, $t1, 1
	
clean_comparison_string:
	lb $t0, 0($t1)
	beqz $t0, read_one_char_from_txt_file	
	sb $zero, 0($t1)
	addi $t1, $t1, 1
	j clean_comparison_string
	

###################################Comparison begins###################################

#########################################################################
#	$t0 -> has passed separator? separator is '.'			# if we find '`' and $t0 is true, we have found
#	$t1 -> temporarily store char from dictionary			# the string in the dictionary.
#	$t2 -> string address, used for comparing a char from string	# we pass this return through $v1.
#	$t3 -> char from string on $t3 address				#
#	$t4 -> dictionary_EOF?						#
#	$t5 -> index of dictionary string being compared		#
#	$v1 -> return if string was found in dictionary			#
#########################################################################

find_string_on_dictionary:
	add $v1, $zero, $zero		# reset $v1 that will count how many strings are the same

compare_dictionary_line:
	add  $t0, $zero, $zero		# resets $t0
	la  $t2, string			# resets $t2 to string address
	addi $t2, $t2, 1		# get first element from string
	sb $0, char			# reset char as nil
	addi $t5, $t5, 1		# dictionary index++
	
read_one_char_from_dictionary:
	li $v0, 14 			# read from file
	move $a0, $s1 			# dictionary file descriptor
	la $a1, char			# read char
	li $a2, 1
	syscall
	
compare_separator:
	beqz $v0, comparation_ends		# didn't read any chars, get EOF and end comparation
	lb $t1, char				# $t1 = char from dictionary
	beqz $t1, comparation_ends		#if $t1 is \0, then the dictionary ended, so it'll exit
	beq  $t1, 46, is_dictionary_first_line	#if the character is equal to '.', then it will compare the strings
	j    read_one_char_from_dictionary	#if not, it will continue looking for the '.' separator
	
is_dictionary_first_line:
	beqz $t5, compare_dictionary_line	# if dictionary index is 1, we're at first line. if char 
	
compare_strings:
	addi $t0, $t0, 1 		# set has_passed_separator? to true

load_char_from_string:
	lb $t3, 0($t2)			# $t3 = char from string
	addi $t2, $t2, 1		# increment index in string
			
load_char_from_dictionary:
	li $v0, 14 			# read from file
	move $a0, $s1 			# dictionary file descriptor
	la $a1, char			# read char
	li $a2, 1
	syscall
	lb $t1, char			# $t1 = char from dictionary
	move $t4, $v0			# 1 if read a char. 0 if EOF.

check_if_chars_are_equal:	
	beq $t1, $t3, load_char_from_string	# load new chars while chars are equal
	beqz $t3, save_dictionary_index		# if we found last char from string (nil char = 0), then we have found the string
	add $t0, $zero, $zero			# did not find string in this line of dictionary
	beqz $t4, comparation_ends		# if EOF, exit comparation and return $v1 as false
	
	beq $t1, '`', compare_dictionary_line 	# if is equal to '`', start all over
read_dictionary_until_line_separator:
	li $v0, 14 				# read from file
	move $a0, $s1 				# dictionary file descriptor
	la $a1, char				# read char
	li $a2, 1
	syscall
	lb $t1, char				# $t1 = char from dictionary
	beq $t1, '`', compare_dictionary_line 	# if is equal to '`', start all over
	j read_dictionary_until_line_separator	# if not, keep on reading chars from dictionary

save_dictionary_index:
	move $s5, $t5

comparation_ends:
	move $v1, $t0
	jr $ra
	

# IF STRING NOT FOUND, ADD TO DICTIONARY.
print_index_to_dic:
	addi $s3, $s3, 1   	# INDEX DICTIONARY++
	add   $a0, $zero, $s3
	jal  itoa
	move $a1, $v0 		# save string we're writing
	jal get_string_size
  	move   $a2, $v0		# save string size to number of elements we're writing
  	li   $v0, 15       	# write to file
  	move $a0, $s1     	 # file descriptor 
  	syscall
  	
print_separator_to_dic:
  	li   $v0, 15       	# write to file 	
  	move $a0, $s1		# file descriptor
  	la $a1, separator_char  # get separator char to write
  	addi $a2, $zero, 1	# number of chars to write
  	syscall
  	
print_string_to_dic:
  	move $a0, $s1		# file descriptor
  	la   $a1, string  	# get string to write
  	addi $a1, $a1, 1	# getting address to first char on string
  	move $v0, $a1		# parameter to get string size
  	jal get_string_size
  	move $a2, $v0
  	li   $v0, 15       	# write to file 
  	syscall

print_line_separator_to_dic:
  	li   $v0, 15       	# write to file 	
  	move $a0, $s1		# file descriptor
  	la $a1, line_separator	# get '`' char to write
  	addi $a2, $zero, 1	# number of chars to write
  	syscall	
	jr $s6

itoa:
      la   $t0, integer_to_s    # load string address
      add  $t0, $t0, 30   # seek the end
      sb   $0, 1($t0)     # null-terminated str
      li   $t1, '0'  
      sb   $t1, ($t0)     # init. with ascii 0
      li   $t3, 10        # preload 10
      beqz  $a0, itoa_end  # end if 0
itoa_loop:
      div  $a0, $t3       # a /= 10
      mflo $a0
      mfhi $t4            # get remainder
      add  $t4, $t4, $t1  # convert to ASCII digit
      sb   $t4, ($t0)     # store it
      sub  $t0, $t0, 1    # dec. buf ptr
      bnez  $a0, itoa_loop  # if not zero, loop
      addi $t0, $t0, 1    # adjust buf ptr
itoa_end:
      move $v0, $t0      # return the addr.
      jr   $ra           # of the string
      
get_string_size:
	la $t0, 0($v0) # get string
	add $v0, $zero, $zero
	j loop_string_size

loop_string_size:
	lb $t2, 0($t0)
	beqz $t2, return_string_size # return string size
	addi $v0, $v0, 1 # string size++
	addi $t0, $t0, 1 # increment string index
	j loop_string_size
	
return_string_size:
	jr $ra
	
#
# UTILS
#
label_to_save_$ra_value:
	jr $ra

comparison_string_present:
	beq $v1, 1, reset_$v1
	j txt_file_close

reset_$v1:
	add $v1, $zero, $zero
	addi $t9, $zero, 1
	j write_to_LZW

txt_file_close:
	move $a0, $s0  # file descriptor in $a0
    	li $v0, 16  # $a0 already has the txt file descriptor
    	syscall
    	
dictionary_file_close:
	move $a0, $s1  # file descriptor in $a0
    	li $v0, 16  # $a0 already has the dictionary file descriptor
    	syscall
    	
LZW_file_close:
	move $a0, $s2  # file descriptor in $a0
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
