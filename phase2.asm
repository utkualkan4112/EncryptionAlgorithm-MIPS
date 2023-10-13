.data  
T0: .space 4                           # the pointers to your lookup tables
T1: .space 4                           
T2: .space 4                           
T3: .space 4                           
fin: .asciiz "C:\\Users\\iTopya\\Desktop\\tables.dat"      # put the fullpath name of the file AES.dat here
buffer: .space 17000                 # temporary buffer to read from file
key: .word 0x2b7e1516, 0x28aed2a6, 0xabf71588, 0x09cf4f3c
   
rcon: .word 0x80, 0x40, 0x20, 0x10, 0x08, 0x04, 0x02, 0x01
userInput: .space 32
m: .space 32
s: .space 16
t: .space 32
.text
#open a file for writing
li   $v0, 13       # system call for open file
la   $a0, fin      # file name
li   $a1, 0        # Open for reading
li   $a2, 0
syscall            # open a file (file descriptor returned in $v0)
move $s6, $v0      # save the file descriptor 

#read from file
li   $v0, 14       # system call for read from file
move $a0, $s6      # file descriptor 
la   $a1, buffer   # address of buffer to which to read
li   $a2, 17000     # hardcoded buffer length
syscall            # read from file

move $s0, $v0	   # the number of characters read from the file
la   $s1, buffer   # address of buffer that keeps the characters


li $s7, 256          # counter for entries in each table
li $s2, 4            # counter for tables
la $s3, T0           # base address of the static memory locations
li $s5, 0
ProcessTables:
    
    # allocate heap memory for the current table
    li $v0, 9        # system call for sbrk
    li $a0, 1024    # allocate 1024 bytes (256 entries 4 bytes)
    syscall          # perform system call
    move $t4, $v0    # keep the starting address of the current table
    # save the heap address to static memory
    sw $t4, 0($s3)   

ProcessEntries:
    # convert the next characters from the buffer into a number
    jal ReadNumber
    
    #sw $v0, ($t4)    # store the number into the current table
    sw $v0, 0($t4)    # store the number into the current table
    addiu $t4, $t4, 4 # increment the table pointer
    addiu $s7, $s7, -1    # decrement the entry counter
    
    bnez $s7, ProcessEntries    # if entry counter is not zero, process more entries
    
    
    
    addiu $s3, $s3, 4    # increment the static memory pointer
    addiu $s2, $s2, -1   # decrement the table counter
    li $s7, 256          # reset the entry counter
    
    bnez $s2, ProcessTables    # if table counter is not zero, process more tables
    
    
# subroutine to read the next number from the buffer into $v0
    ReadNumber:

        move $t8, $zero
        #sw $v0, 0($t4)
        move $v0, $zero
        sw $ra, 0($sp)
        Loop:
            # Convert hexadecimal string to integer
            lbu $t5, 0($s1)        # load the next character
            addi $s5, $s5, 1
            beq $s5, $s0, TakeMessage
            #beq $t5, 32, ExitLoop  # if space is found, exit the loop
            #beq $t5, 10, ExitLoop  # if newline is found, exit the loop
            beq $t5, 120, Continou
            beq $t5, 44, ExitLoop  # if comma is found, exit the loop
            jal convert_to_int
            add $v0, $v0, $t5
            beq $t8, 8, ExitLoop
            addi $t8, $t8, 1
            sll $v0, $v0, 4
            andi $v0, $v0, 0xfffffff0
            #jal convert_to_binary
            addiu $s1, $s1, 1      # increment the buffer pointer
            #addiu $s0, $s0, -1     # decrement the count
            j Loop
        Continou:
            addiu $s1, $s1, 1      # increment the buffer pointer
            #addiu $s0, $s0, -1     # decrement the count
            j Loop
        ExitLoop:
            addiu $s1, $s1, 3      # skip the space/newline character
            #addiu $s0, $s0, -2     # decrement the count
            lw $ra, 0($sp)
            jr $ra                 # return from the subroutine
        
        convert_to_int:
            li $t0, 10  # prepare the divisor for conversion (ASCII to integer)
            subu $t5, $t5, 48      # convert from ASCII to integer
            bge $t5, $t0, alpha
            jr $ra
        alpha:
            subu $t5, $t5, 39      # convert from ASCII to integer
            jr $ra
                   
            
TakeMessage:
    
    jal TakeInput

LoopMessage:
    beq $s2, 2, Exit
    addi $s2, $s2, 1
       
    # ilk keyi scheduled yap
    move $s5, $zero
    la $s5, key
    #la $s6, t
    move $t0, $zero
    move $t9, $zero # multi register
    addi $t9, $t9, 4
Schedule:
    
    jal KeySchedule
    #inputa göre s i de?i?tir
    jal CreateS 
    la $t3, T0
    la $a0, s 
    move $a1, $s5
    
    jal RoundOperation
    #la $a0, $s5 #load key address
    
    
    beq $t0, 7, LoopMessage
    addi $t0, $t0, 1 
    j Schedule
    #j Exit
RoundOperation:
    addi $sp, $sp, -28
    sw $t0, 24($sp)
    sw $s3, 20($sp)
    sw $s4, 16($sp)
    sw $s2, 12($sp)
    sw $s7, 8($sp)
    sw $s6, 4($sp)
    sw $ra, 0($sp) 
    
    move $t1, $zero # keep track of s
    addi $t1, $t1, -4
    move $t8, $zero
    move $s7, $zero #counter
    la $s6, t
    beq $s2, 2, MoveT
    j RoundLoop
MoveT:
   addi $s6, $s6, 16
   j RoundLoop
RoundLoop:
    jal UpdateS
    addi $t3, $t3, 12 # T3
    lw $t4, 0($t3) # load T3[0]
    add $t7, $a0, $t1
    lw $t6, 0($t7)
    srl $t6, $t6, 24
    mul $t6, $t6, $t9
    add $s1, $t4, $t6
    lw $s1, 0($s1)
    
    jal UpdateS
    addi $t3, $t3, -8
    lw $t4, 0($t3)
    add $t7, $a0, $t1
    lw $t6, 0($t7)
    srl $t6, $t6, 16
    and $t6, $t6, 0xff
    mul $t6, $t6, $t9
    add $s2, $t4, $t6
    lw $s2, 0($s2)
    
    jal UpdateS
    addi $t3, $t3, 4
    lw $t4, 0($t3)
    add $t7, $a0, $t1
    lw $t6, 0($t7)
    srl $t6, $t6, 8
    and $t6, $t6, 0xff
    mul $t6, $t6, $t9
    add $s3, $t4, $t6
    lw $s3, 0($s3)
    
    jal UpdateS
    addi $t3, $t3, -8
    lw $t4, 0($t3)
    add $t7, $a0, $t1
    lw $t6, 0($t7)
    and $t6, $t6, 0xff
    mul $t6, $t6, $t9
    add $s4, $t4, $t6
    lw $s4, 0($s4)
    
    xor $t2, $s1, $s2
    xor $t2, $t2, $s3
    xor $t2, $t2, $s4
    add $s0, $a1, $t8
    lw $s0, 0($s0)
    xor $t2, $t2, $s0
    sw $t2, 0($s6)
    addi $s6, $s6, 4
    
    addi $s7, $s7, 1
    
    beq $s7, $t9, ExitRoundOperation
    
    jal UpdateS
    
    
    
    addi $t8, $t8, 4
    j RoundLoop

UpdateS:
    beq $t1, 12, ResetS
    addi $t1, $t1, 4
    jr $ra
ResetS:
    move $t1, $zero
    jr $ra
    
ExitRoundOperation:
    lw $t0, 24($sp)
    lw $s3, 20($sp)
    lw $s4, 16($sp)
    lw $s2, 12($sp)
    lw $s7, 8($sp)
    lw $s6, 4($sp)
    lw $ra, 0($sp) 
    addi $sp, $sp, 28
    jr $ra
    
    
KeySchedule:
    addi $sp, $sp, -28
    sw $t0, 24($sp)
    sw $s3, 20($sp)
    sw $s1, 16($sp)
    sw $s2, 12($sp)
    sw $s7, 8($sp)
    sw $s5, 4($sp)
    sw $ra, 0($sp) 
    
    move $t8, $zero
    addi $t8, $t8, 2
    move $s7, $zero #counter
    move $t3, $zero
    move $t1, $zero
    
    move $s0, $zero
    #a
    mul $t8, $t8, 4
    add $t6, $s5, $t8
    lw $t6, 0($t6)
    srl $t6, $t6, 24
    and $t6, $t6, 0xFF
    #b
    add $t4, $s5, $t8
    lw $t4, 0($t4)
    srl $t4, $t4, 16
    and $t4, $t4, 0xFF
    #c
    add $t3, $s5, $t8
    lw $t3 0($t3)
    srl $t3, $t3, 8
    and $t3, $t3, 0xFF
    
    #d
    add $s7, $s5, $t8
    lw $s7 0($s7)
    and $s7, $s7, 0xFF
    
    
    la $s1, T2
    lw $s2, 0($s1)
    #e
    mul $t4, $t4, 4
    add $t4, $s2, $t4
    lw $t4, 0($t4)
    and $t4, $t4, 0xFF
    
    la $s3, rcon
    mul $s0, $t0, 4
    add $s3, $s3, $s0
    
    lw $s3, 0($s3)
    xor $t4, $t4, $s3
    
    #f
    mul $t3, $t3, 4
    add $t3, $s2, $t3
    lw $t3, 0($t3)
    and $t3, $t3, 0xFF
    
    #g
    mul $s7, $s7, 4
    add $s7, $s2, $s7
    lw $s7, 0($s7)
    and $s7, $s7, 0xFF
    
    #h
    mul $t6, $t6, 4
    add $t6, $s2, $t6
    lw $t6, 0($t6)
    and $t6, $t6, 0xFF
    
    #tmp
    sll $t4, $t4, 24
    sll $t3, $t3, 16
    sll $s7, $s7, 8
    xor $t4, $t4, $t3
    xor $t4, $t4, $s7
    xor $t4, $t4, $t6
    
    #assign
    lw $s7, 0($s5)
    xor $s7, $t4, $s7
    sw $s7, 0($s5)
    addi $s3, $s5, 4
    
    lw $t3, 0($s3)
    xor $t3, $s7, $t3
    sw $t3, 0($s3)
    addi $s3, $s3, 4
    
    lw $s7, 0($s3)
    xor $s7, $s7, $t3
    sw $s7, 0($s3)
    addi $s3, $s3, 4
    
    lw $t3, 0($s3)
    xor $t3, $t3, $s7
    sw $t3, 0($s3)
    
    lw $t0, 24($sp)
    lw $s3, 20($sp)
    lw $s1, 16($sp)
    lw $s2, 12($sp)
    lw $s7, 8($sp)
    lw $s5, 4($sp)
    lw $ra, 0($sp) 
    addi $sp, $sp, 28
    jr $ra
    
TakeInput:
    # Read the string from the user
    li $v0, 8
    la $a0, userInput
    li $a1, 32
    syscall
    la $t5, m
    lw $t2, 0($t5)
    move $t1, $zero
ConvertHex:
    # Initialize loop index to 0
    la $t3, 24
    move $t4, $zero
    loop:
        # Load a byte from the string
        lb $t0, userInput($t1)
        beq $t0, 10, Skip
        beqz $t0, end
        sllv $t0, $t0, $t3
        addi $t3, $t3, -8
        or $t2, $t2, $t0
        
        # Increase the loop index and jump back to the start of the loop
        addiu $t1, $t1, 1
        addi $t4, $t4, 1
        
        bne $t4, 4, loop
        
        sw $t2, 0($t5)
        move $t2, $zero
        addi $t5, $t5, 4
        j ConvertHex
        
    Skip:
        addiu $t1, $t1, 1
        
    end:
        sw $t2, 0($t5)
    exit:
        move $t1, $zero
        move $t5, $zero
        move $t2, $zero
        move $t4, $zero
        move $t3, $zero
        move $t0, $zero
        jr $ra
 CreateS:
    addi $sp, $sp, -28
    sw $t0, 24($sp)
    sw $s3, 20($sp)
    sw $s4, 16($sp)
    sw $s2, 12($sp)
    sw $s7, 8($sp)
    sw $s6, 4($sp)
    sw $ra, 0($sp)
    la $s4, m
    la $s7, key
    la $s6, s
    move $s3, $zero
    move $t2, $zero
    beq $s2, 2, SecondHalf
    
    
    SLoop:
       mul $t1, $t2, 4
       add $t0, $s4, $t1
       lw $t1, 0($t0)
       mul $t0, $s3, 4
       add $t0, $s7, $t0
       lw $t3, 0($t0)
       or $t0, $t3, $t1
       
       sw $t0, 0($s6)
       
       beq $s3, 3, ReturnS
       addi $s6, $s6, 4
       addi $s3, $s3, 1
       addi $t2, $t2, 1
       j SLoop
       
 SecondHalf:
    addi $t2, $t2, 4
    j SLoop
    
 ReturnS: 
    lw $t0, 24($sp)
    lw $s3, 20($sp)
    lw $s4, 16($sp)
    lw $s2, 12($sp)
    lw $s7, 8($sp)
    lw $s6, 4($sp)
    lw $ra, 0($sp) 
    addi $sp, $sp, 28  
    jr $ra
    
 
    
    
    
Exit:
li $v0,10
syscall             #exits the program

