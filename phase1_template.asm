.data  
T0: .space 4                           # the pointers to your lookup tables
T1: .space 4                           
T2: .space 4                           
T3: .space 4                           
fin: .asciiz "C:\\Users\\iTopya\\Desktop\\tables.dat "      # put the fullpath name of the file AES.dat here
buffer: .space 5000                    # temporary buffer to read from file

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
li   $a2, 4096     # hardcoded buffer length
syscall            # read from file

move $s0, $v0	   # the number of characters read from the file
la   $s1, buffer   # address of buffer that keeps the characters

# print whats in the file
li $v0, 4
la $a0, buffer
syscall

li $t1, 256          # counter for entries in each table
li $t2, 4            # counter for tables
la $t3, T0           # base address of the static memory locations

ProcessTables:
    # allocate heap memory for the current table
    li $v0, 9        # system call for sbrk
    li $a0, 1024     # allocate 1024 bytes (256 entries * 4 bytes)
    syscall          # perform system call
    move $t4, $v0    # keep the starting address of the current table
    # save the heap address to static memory
    sw $t4, 0($t3)   

ProcessEntries:
    # convert the next characters from the buffer into a number
    jal ReadNumber
    sw $v0, 0($t4)    # store the number into the current table

    addiu $t4, $t4, 4 # increment the table pointer
    addiu $t1, $t1, -1    # decrement the entry counter

    bnez $t1, ProcessEntries    # if entry counter is not zero, process more entries

    addiu $t3, $t3, 4    # increment the static memory pointer
    addiu $t2, $t2, -1   # decrement the table counter
    li $t1, 256          # reset the entry counter
    
    bnez $t2, ProcessTables    # if table counter is not zero, process more tables

# subroutine to read the next number from the buffer into $v0
    ReadNumber:
        # assuming $s1 points to the start of the next number to read
        # and $s0 contains the number of characters left to read
        la $v0, $t4   # initialize the return register to 0
        li $t0, 10  # prepare the divisor for conversion (ASCII to integer)

        Loop:
            lbu $t5, 0($s1)        # load the next character
            beq $t5, 32, ExitLoop  # if space is found, exit the loop
            beq $t5, 10, ExitLoop  # if newline is found, exit the loop
            beq $t5, 44, SaveWord  # if comma is found, exit the loop
            #subu $t5, $t5, 48      # convert from ASCII to integer
            #mul $v0, $v0, $t0      # multiply the current number by 10
            #add $v0, $v0, $t5      # add the new digit
            sb $t5, ($v0)
            addiu $s1, $s1, 4      # increment the buffer pointer
            addiu $s0, $s0, -1     # decrement the count
            j Loop

        ExitLoop:
            addiu $s1, $s1, 4      # skip the space/newline character
            addiu $s0, $s0, -1     # decrement the count
            jr $ra                 # return from the subroutine
        SaveWord:
            

#close the file
li $v0, 16
move $a0, $s0
syscall

# your code goes here

Exit:
li $v0,10
syscall             #exits the program

