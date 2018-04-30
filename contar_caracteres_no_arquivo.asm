.data
	arquivo:        .asciiz "test.txt"
	caracter_lido:  .space  4
  
.text

##################################NÃO MAIS NECESSÁRIO##################################

abre_arquivo:
	li $v0, 13		#comando para abrir arquivo
	la $a0, arquivo		#string com o nome do arquivo
	li $a1, 0		#modo leitura
	li $a2, 0
	syscall
	add $s7, $zero, $v0	#$s7 agora contem o indicador do arquivo

zera_t0:
	add $t0, $zero, $zero

conta_caracteres:
	li   $v0, 14			#comando para ler do arquivo
	add  $a0, $s7, $zero	 	#indicador do arquivo
	la   $a1, caracter_lido  	#armazena o endereço onde o caracter será colocado
	li   $a2, 1		 	#indica que só lerá 1 caracter de cada vez
	syscall
	beq  $v0, $zero, fecha_arquivo	#verifica se chegou no final do arquivo
	addi $t0, $t0, 1	 	#soma 1 em $t0 a cada caracter lido
	j    conta_caracteres		#reinicia o loop

fecha_arquivo:
	li   $v0, 16		#comando para fechar o arquivo
	add  $a0, $s7, $zero	#$a0 recebe o indicador do arquivo a ser fechado
	syscall
