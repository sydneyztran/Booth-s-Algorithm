#Group 21: Sydney Tran 1585868, Chanel Muir 1597610, Leyton McKinney 1179472
.data
    input_buffer: .space 20
    overflow_message: .asciiz "input error!\n"
    input_is: .asciiz "input: "
    dashes: .asciiz "----------\n"
    mult_symbol: .asciiz "X"
    new_line: .asciiz "\n"
    space: .asciiz " "
    case_01_message: .asciiz "case_01"
    case_10_message: .asciiz "case_10"

.text
main:   
    
    jal convert_start
    move $s0, $a0               # S0 will store the convert number DO NOT override
    jal convert_start
    move $s1, $a0               # S1 will store the second convert number DO NOT override

    la $a0, space               # Space before first operand
    li $v0, 4
    syscall

    move $s2, $s0               # Convert Start requires integer to be printed to be in $s2
    jal print_binary_word           # print first operand

    la $a0, new_line            # New line after first operand
    li $v0, 4
    syscall

    la $a0, mult_symbol         # prints X
    li $v0, 4
    syscall

    move $s2, $s1
    jal print_binary_word       # Print second operand

    la $a0, new_line            # Print new line
    li $v0, 4
    syscall

    la $a0, dashes              # Print dashes with new line
    li $v0, 4
    syscall

    jal booths

    la $a0, dashes              # Print dashes with new line
    li $v0, 4
    syscall

    # Print final result (AQ) 
    la $a0, space               # Space before A
    li $v0, 4
    syscall

    add $s2, $zero, $a2
    jal print_binary_word
    add $s2, $zero, $a1
    jal print_binary_word

    li $v0, 10                  # Exit syscall
    syscall

################################### 
#### Convert from string to decimal then check for over flow
###################################

convert_start:
    #### TAKE STRING IN ####
    li $v0, 8                   # syscall for readstring
    la $a0, input_buffer        # input will be stored here
    li $a1, 20                  # Maximum number of characters to input
    syscall

    #### CONVERT TO AN INTEGER IN A REGISTER ####
    li $t2, 0                   # Running Sum
    li $t3, 10                  # Multiplier character and Ascii value of enter
    la $t0, input_buffer        # T0 is now a pointer to input_buffer
    li $t4, 1                   # T4 is the sign register, default is positive
convert:
    lbu $t1, 0($t0)                 # Load the highest Byte (Big-Endian)
    beq $t1, 45, is_negative        # Check if current byte is -, if so this is the negative symbol and it's handled differently
    beq $t1, $t3, convert_end       # If byte = 0a, we've hit the enter character
    addi $t1, $t1, -48              # converts t1's ascii value to dec value
    
    bgt $t1, 9, overflow_escape     # If $t1's value is greater than 9 it is some other ascii character that is not a number
    blt $t1, 0, overflow_escape     # If $t1's value is less than 0 it is some other ascii character that is not a number

    mult $t2, $t3
    mflo $t2 
    addu $t2, $t2, $t1        # sum += array[s1]-'0'
    addi $t0, $t0, 1          # increment array address
    j convert                 # jump to start of loop

is_negative:
    addi $t4, $zero, -1     # Set sign register to be negative 1    
    addi $t0, $t0, 1        # move the byte pointer over 1 
    lbu $t1, 0($t0)         # load next char
    beq $t1, $t3, overflow_escape       # If byte = 0a, we've hit the enter character, 
    j convert_neg               # jump to the top of the loop

convert_neg:
    lbu $t1, 0($t0)                 # Load the highest Byte (Big-Endian)
    beq $t1, 45, is_negative        # Check if current byte is -, if so this is the negative symbol and it's handled differently
    beq $t1, $t3, convert_neg_end       # If byte = 0a, we've hit the enter character
    addi $t1, $t1, -48              # converts t1's ascii value to dec value
    
    bgt $t1, 9, overflow_escape     # If $t1's value is greater than 9 it is some other ascii character that is not a number
    blt $t1, 0, overflow_escape     # If $t1's value is less than 0 it is some other ascii character that is not a number

    mult $t2, $t3
    mflo $t2 
    addu $t2, $t2, $t1        # sum += array[s1]-'0'
    addi $t0, $t0, 1          # increment array address
    j convert_neg                 # jump to start of loop

convert_end:
    move $a0, $t2           # Store unsigned number in $a0                  

    addi $t5, $t5, 1        # 
    mult $a0, $t5           # See if $a0*1 has high bits
    mfhi $t2                #
    bne $t2, $zero, overflow_escape             # An overflow would be indicated by bits in the Hi register not being zero
    mult $a0, $t4           # Multiply the unsigned integer by the sign register
    mflo $a0                # Grab the product put it in $a0
    jr $ra 

convert_neg_end:
    move $a0, $t2           # Store unsigned number in $a0                  
    beq $a0, 2147483648, special_case
    addi $t5, $t5, 1        # 
    mult $a0, $t5           # See if $a0*1 has high bits
    mfhi $t2                #
    bne $t2, $zero, overflow_escape             # An overflow would be indicated by bits in the Hi register not being zero
    mult $a0, $t4           # Multiply the unsigned integer by the sign register
    mflo $a0                # Grab the product put it in $a0
    jr $ra 

special_case:
    addi $t5, $t5, 1        # 
    mult $a0, $t5           # See if $a0*1 has high bits
    mfhi $t2                #
    bne $t2, -1, overflow_escape             # An overflow would be indicated by bits in the Hi register not being zero
    mult $a0, $t4           # Multiply the unsigned integer by the sign register
    mflo $a0                # Grab the product put it in $a0
    jr $ra 
    
overflow_escape:
    la $a0, overflow_message    # load the overflow_message into $a0
    li $v0, 4                   # print string 
    syscall

    li $v0, 10                  # exit
    syscall


###################### PRINT REGISTER IN BINARY PROCEDURE #################################
###### Put the number you want to convert in register $s2
print_binary_word:

    move $t2, $s2      # Load the value in $s2 into $t2 for the procedure
    li $t0, 31         # index register
    li $t1, 31         # Comparison register

print_binary_loop:
    blt $t0, $zero, end_binary_loop         # if the index register is less than zero, we've iterated over 32 bits alreadu
    srlv $t3, $t2, $t0                      # Shift $t2 to the right $t0 times moving the $t0'th bit into the 1's position
    andi $a0, $t3, 1                        # $a0 will be 1 if there is a bit in the 1's position or 0 otherwise

    li $v0, 1                               # print integer syscall
    syscall
    addi $t0, $t0, -1                       # Decriment the loop variable
    j print_binary_loop


end_binary_loop:                                
    jr $ra                                  # Return to caller 



######### BOOTHS ALGORITHM PROCEDURE #########
booths:
    li $t0, 0                               # $t0 will store A's value, initialized to be 0*32
    move $t1, $s0                           # $t1 will store M's value, intialized as the multiplicand
    add $t2, $zero, $zero                   # $t2 will store Q(-1)'s value, initialized as 0
    move $t3, $s1                           # $t3 will store Q's value, intialzed as the multiplier
    sub $t4, $zero, $t1                     # $t4 will store -M's value ($t3 = 0 - $t2(M))
    li $t5, 31                              # $t5 will be the indexing register, initialzed at 31
    li $t6, 0                               # $t6 will store the 0th bit of Q
    andi $t6, $t3, 1                        # Initialize Q[0] as the 0th bit of Q

    addi $sp, $sp, -4
    sw $ra, 0($sp)

booths_loop:
    blt $t5, $zero, end_booths              # If the indexing register is less than zero, the procedure is complete
                      
    
    blt $t6, $t2, case_01
    bgt $t6, $t2, case_10

return_from_cases:

    ############ Arithmetic Shift AQQ-1 ##########
    andi $t2, $t3, 1                    # Grab's 0th bit of Q stores it in $t2(Q-1 regsiter)
    srl $t3, $t3, 1                     # Shift Q right once
    andi $t7, $t0, 1                    # Grab the 0th bit of A store it in $t7
    sll $t7, $t7, 31                    # Move to MSB
    sra $t0, $t0, 1                     # Shift A Right Arithmetically
    or $t3, $t3, $t7                    # Set Q[31] to A0
    andi $t6, $t3, 1                    # Q[0] = 0th bit of Q (now shifted over 1)

    addi $t5, $t5, -1                   # Decriment the index register

    ############# Print AQ #############
    la $a0, space               # Space before A
    li $v0, 4
    syscall

    move $s2, $t0
    addi $sp, $sp, -16     # Allocate space on stack
    sw $t0, 0($sp)         # Store $t0 to $t3 on stack
    sw $t1, 4($sp)
    sw $t2, 8($sp)
    sw $t3, 12($sp)
    jal print_binary_word
    lw $t3, 12($sp)

    move $s2, $t3
    sw $t3, 12($sp)
    jal print_binary_word
    lw $t0, 0($sp)          # Retrieve $t0 to $t3 from stack
    lw $t1, 4($sp)
    lw $t2, 8($sp)
    lw $t3, 12($sp)
    addi $sp, $sp, 16       # Deallocate space on stack

    la $a0, new_line
    li $v0, 4
    syscall

    j booths_loop
 
case_01:
    #la $a0, case_01_message
    #li $v0, 4
    #syscall

    #la $a0, new_line
    #li $v0, 4
    #syscall

    add $t0, $t0, $t1                       # A = A+M
    j return_from_cases

case_10:
    #la $a0, case_10_message
    #li $v0, 4
    #syscall

    #la $a0, new_line
    #li $v0, 4
    #syscall

    add $t0, $t0, $t4                       # A = A-M
    j return_from_cases

end_booths:
    lw $ra, 0($sp)                        # Grab the return address
    addi $sp, $sp, 4                      # Deallocate STack
    add $a2, $zero, $t0                   # Store A in a2
    add $a1, $zero, $t3                   # Store Q in a1
    jr $ra

