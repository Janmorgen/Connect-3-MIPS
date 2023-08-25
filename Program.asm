.data

index_board: .word 
	     0,1,2, 	# 0
	     3,4,5, 	# 1
	     6,7,8, 	# 2
	     9,10,11, 	# 3
	     12,13,14, 	# 4
	     15,16,17	# 5
	     
board: .word 
	     0,0,0, 	# 0
	     0,0,0, 	# 1
	     0,0,0, 	# 2
	     0,0,0, 	# 3
	     0,0,0, 	# 4
	     0,0,0	# 5

space:.asciiz " "
nl: .asciiz "\n"

slot_notFound: .asciiz "There was not an available slot in the selected row...\n"


selector_Pos0: .asciiz "  V - -\n"
selector_Pos1: .asciiz "  - V -\n"
selector_Pos2: .asciiz "  - - V\n"
columns: .asciiz "  A B C"
columnA: .asciiz "A"
columnB: .asciiz "B"
columnC: .asciiz "C"

winningMove:.asciiz "\nWinning move: "
playerWin: .asciiz "You dominated the machine! (You won)"
computerWin: .asciiz "You got dominated by a computer! (You lost)"

.text

main:

	jal player_control



	li $s4, 1
	jal play_column

	jal bot_opponent_move
	li $s4, 2
	jal play_column


	b main



	end:
	li $v0, 10
	syscall

# Inputs:
#	$s0 - 1 for write, 0 for read
#	$s1 - Value to write to index
#	$s2 - Index to read/ write to
# Outputs:
#	$s1 - Value read from index
# Used Registers:
#	$t0
# Description:
#	This module provides a way for the rest of the modules to easily access data from the board
#	This module is able to read and write values on the board
access_board:
	
	#invalid_input_check:
	#	slti $t1,$s1,0
	#	li $t0, 17
	#	slti $t2, $t0, $s1
		

	la $t0, board
	sll $s2, $s2, 2
	add $t0, $t0,$s2
	
	bne $s0,0,write_board
	
	
	read_board:
		lw $s1, ($t0)
	b access_board_end
	
	write_board:
		sw $s1, ($t0)
	access_board_end:
		
		jr $ra
# Inputs:
#	Left and right arrow keys
#	Enter key
# Output:
#	$s3 - Value between 0 - 2
# Description:
#	This module provides a way for the player to select their move using keystrokes (a,d,f)
#	a - makes the move selector go left
#	b - makes the move selector go right
#	f - finalises a move from the player, passes the move to play_column
player_control:
	li $s3, 0
	la $t5, ($ra)
	b print_position
	
	jal play_player_move_sound
	
	input_loop:
		li $v0, 12
		syscall
		la $t0, ($v0)
		 
		#beq $t0, 49, one_pressed
		#beq $t0, 50, two_pressed
		
		# Doubled to make sure both upper and lower case characters are accepted
		beq $t0, 97,  left_arrow_pressed
		beq $t0, 65,  left_arrow_pressed
		beq $t0, 100, right_arrow_pressed
		beq $t0, 68,  right_arrow_pressed
		beq $t0, 102, enter_pressed
		beq $t0, 70,  enter_pressed
		
		print_position:
			li $v0, 4
			la $a0, nl
			syscall
			syscall
			syscall
			li $v0, 4
			
			beq $s3,0, pos0
			beq $s3,1, pos1
			beq $s3,2, pos2
			
			pos0:
				la $a0, selector_Pos0
				b printDuBoy
			pos1:
				la $a0, selector_Pos1
				b printDuBoy
			pos2:
				la $a0, selector_Pos2
				b printDuBoy
			
			printDuBoy:
				syscall
				jal print_board
				
				b input_loop
				
		one_pressed:
			li $s4,1
			b input_loop
		
		two_pressed:
			li $s4,2
			b input_loop
			
			
			
		right_arrow_pressed:
			beq $s3, 2, print_position
			add $s3, $s3, 1
			b print_position
			
		left_arrow_pressed:
			beq $s3, 0, print_position
			sub $s3, $s3, 1
			b print_position
		
		enter_pressed:
			la $a0, nl
			li $v0, 4
			syscall
			b player_control_end
	player_control_end:
		la $ra, ($t5)
		jr $ra
			

# Inputs:
#	$s3 - Input column 0 - 2
#	$s4 - Player value 1/2
# Output:
#	N/A for now 
# Used Registers:
#	$t6, $t2, $t3, $t4, $t5, $s3, $s4
# Dependancy Functions:
#	access_board: $t0
# Description:
#	This module abstracts "gravity" for the board, allows other functions to place tiles
#		at the last available open slot, if none is found in given column it outputs a msg
#		but still returns <-- needs fixing
play_column:
	la $t6, ($ra)
	li $t2, 3
	li $t3, 5
	li $t4, 0
	li $t5, 0
	check_loop:
		
		mul $t4,$t2,$t3
		add $t5, $s3, $t4
		
		li $s0,0
		la $s2,($t5)
		jal access_board
		
		beq $s1, $zero, availible_found
		beq $t3, $zero, availible_notFound
		sub $t3, $t3, 1
		
		j check_loop
		
	availible_found:
		li $s0, 1
		la $s2, ($t5)
		la $s1, ($s4)
		jal access_board
		
		jal check_win
		
		j end_play
	
	availible_notFound:
		li $v0, 4
		la $a0, slot_notFound
		syscall
		jal play_wrong_move
		j end_play
		
	end_play:
		la $ra, ($t6)
		jr $ra
		
		
		
	



	la $ra, ($t1)
	jr $ra
# Inputs:
#	NA
# Outputs:
#	NA
# Used Registers:
#	$t1, $t2, $t3, $t4
# Dependancy Functions:
#	access_board: $t0
# Description:
#	This module prints the entire board for the player with indicators for both axis
# Example:
#	  A B C
#	1 0 0 0
#	2 0 0 0
#	3 0 0 0
#	4 0 0 0
#	5 0 0 0
#	6 0 0 0
print_board:
	li $t1, 0
	la $t2, ($ra)
	li $t3, 0
	li $t4, 0
	
	li $v0,4
	la $a0, columns
	syscall
	
	li $v0,4
	la $a0,nl
	syscall
	
	li $v0,1
	li $a0,1
	syscall
	
	li $v0,4
	la $a0, space
	syscall
	loop:
		beq $t1, 18, end_print
		la $s2, ($t1)
		li $s0, 0
		
		jal access_board
		li $v0, 1
		la $a0, ($s1)
		syscall
		
		li $v0, 4
		la $a0, space
		syscall
		
		li $t4,3
		addi $t1,$t1,1
		div $t1, $t4
		mfhi $t3
		subi $t1,$t1,1
		
		bne $t3, 0, skipNL
		
		li $v0, 4
		la $a0, nl
		syscall
		
		mflo $t4
		add $t3,$t4, 1
		
		beq $t3, 7, skipNL
		li $v0,1
		la $a0, ($t3)
		syscall
		
		li $v0,4
		la $a0, space
		syscall
		
		skipNL:
		addi $t1, $t1, 1
		b loop
	end_print:
		la $ra, ($t2)
		jr $ra
# Inputs:
#	Passed through from play_column
#	$t5, $s3
# Outputs:
#	None, directes program flow
# Used Registers:
#	$t1, $t2, $t3, $t4
# Dependancy Functions:
#	access_board: $t0 
#	  IO: 
#		$s0: 1/0 write/read
#		$s1: Value to write || Output value for read
#		$s2: Index to read/ write to	
# Description:
#	This module uses the last move made in play_column to check all win cases for 
#		that particular tile index, checks vertical, horizontal and diagonal directions
check_win:
	la $t1, ($ra) # save return address
	li $t2, 0 # temp value for comparisons
	li $t3, 0 # index plus delta, used to retrieve adjacent values
	li $t4, 0 # comparison reg
	
	bgt $t5, 11, vert_failed
	
	vert_check:
		li $s0, 0
		la $s2, ($t5)
		jal access_board
			
		la $t2, ($s1)
			
		add $t3, $t5, 3
			
		li $s0, 0
		la $s2, ($t3)
		jal access_board
			
		bne $s1, $t2, vert_failed # if left dne middle
			
		add $t3, $t5, 6
			
		li $s0, 0
		la $s2, ($t3)
		jal access_board
			
		bne $s1, $t2, vert_failed # if left dne right
			
		b won
		
		vert_failed:
		
	beq $s3, 0, left_check
	beq $s3, 1, middle_check
	beq $s3, 2, right_check
	
	
	left_check:
		left_horizontal:
			li $s0, 0
			la $s2, ($t5)
			jal access_board
			
			la $t2, ($s1)
			
			add $t3, $t5, 1
			
			li $s0, 0
			la $s2, ($t3)
			jal access_board
			
			bne $s1, $t2, left_h_failed # if left dne middle
			
			add $t3, $t5, 2
			
			li $s0, 0
			la $s2, ($t3)
			jal access_board
			
			bne $s1, $t2, left_h_failed # if left dne right
			
			b won
			
			
		left_h_failed:
		
		slti $t4, $t5, 6
		beq $t4, 0, left_uD_failed
		
		left_up_diagonal:
			li $s0, 0
			la $s2, ($t5)
			jal access_board
			
			la $t2, ($s1)
			
			sub $t3, $t5, 2
			
			li $s0, 0
			la $s2, ($t3)
			jal access_board
			
			bne $s1, $t2, left_uD_failed # if left dne middle
			
			sub $t3, $t5, 4
			
			li $s0, 0
			la $s2, ($t3)
			jal access_board
			
			bne $s1, $t2, left_uD_failed # if left dne right
			
			b won
		
		left_uD_failed:
		
		bgt $t5,11, left_failed
		left_down_diagonal:
			li $s0, 0
			la $s2, ($t5)
			jal access_board
			
			la $t2, ($s1)
			
			add $t3, $t5, 4
			
			li $s0, 0
			la $s2, ($t3)
			jal access_board
			
			bne $s1, $t2, left_failed # if left dne middle
			
			add $t3, $t5, 8
			
			li $s0, 0
			la $s2, ($t3)
			jal access_board
			
			bne $s1, $t2, left_failed # if left dne right
			
			b won
		
		left_failed:
			b no_win
			
	middle_check:
		middle_horizontal:
			li $s0, 0
			la $s2, ($t5)
			jal access_board
			
			la $t2, ($s1)
			
			sub $t3, $t5, 1
			
			li $s0, 0
			la $s2, ($t3)
			jal access_board
			
			bne $s1, $t2, middle_h_failed # if left dne middle
			
			add $t3, $t5, 1
			
			li $s0, 0
			la $s2, ($t3)
			jal access_board
			
			bne $s1, $t2, middle_h_failed # if left dne right
			
			b won
			
			
		middle_h_failed:
		
		
		bgt $t5, 15, no_win
		blt $t5, 2, no_win
		
		middle_up_diagonal:
			li $s0, 0
			la $s2, ($t5)
			jal access_board
			
			la $t2, ($s1)
			
			add $t3, $t5, 2
			
			li $s0, 0
			la $s2, ($t3)
			jal access_board
			
			bne $s1, $t2, middle_uD_failed # if left dne middle
			
			sub $t3, $t5, 2
			
			li $s0, 0
			la $s2, ($t3)
			jal access_board
			
			bne $s1, $t2, middle_uD_failed # if left dne right
			
			b won
		
		middle_uD_failed:
		
		middle_down_diagonal:
			li $s0, 0
			la $s2, ($t5)
			jal access_board
			
			la $t2, ($s1)
			
			sub $t3, $t5, 4
			
			li $s0, 0
			la $s2, ($t3)
			jal access_board
			
			bne $s1, $t2, no_win # if left dne middle
			
			add $t3, $t5, 4
			
			li $s0, 0
			la $s2, ($t3)
			jal access_board
			
			bne $s1, $t2, no_win # if left dne right
			
			b won
		

	right_check:
		right_horizontal:
			li $s0, 0
			la $s2, ($t5)
			jal access_board
			
			la $t2, ($s1)
			
			sub $t3, $t5, 1
			
			li $s0, 0
			la $s2, ($t3)
			jal access_board
			
			bne $s1, $t2, right_h_failed # if left dne middle
			
			sub $t3, $t5, 2
			
			li $s0, 0
			la $s2, ($t3)
			jal access_board
			
			bne $s1, $t2, right_h_failed # if left dne right
			
			b won
			
			
		right_h_failed:
		
		blt $t5, 6, right_uD_failed
		
		right_up_diagonal:
			li $s0, 0
			la $s2, ($t5)
			jal access_board
			
			la $t2, ($s1)
			
			sub $t3, $t5, 8
			
			li $s0, 0
			la $s2, ($t3)
			jal access_board
			
			bne $s1, $t2, right_uD_failed # if left dne middle
			
			sub $t3, $t5, 4
			
			li $s0, 0
			la $s2, ($t3)
			jal access_board
			
			bne $s1, $t2, right_uD_failed # if left dne right
			
			b won
		
		right_uD_failed:
		
		bgt $t5,12, no_win
		right_down_diagonal:
			li $s0, 0
			la $s2, ($t5)
			jal access_board
			
			la $t2, ($s1)
			
			add $t3, $t5, 4
			
			li $s0, 0
			la $s2, ($t3)
			jal access_board
			
			bne $s1, $t2, no_win # if left dne middle
			
			add $t3, $t5, 2
			
			li $s0, 0
			la $s2, ($t3)
			jal access_board
			
			bne $s1, $t2, no_win # if left dne right
			
			b won
	won:
		jal print_board
		jal print_winner
		j end
	no_win:
		la $ra, ($t1)
		jr $ra


# Input:
#	Brought over from play_column
#	$t5, $s3
# Output:
#	A column the computer wants a tile to drop down, outputed as input to play_column
#	$s3
# Used Registers:
#	$t1, $t2, $t3, $t4
# Description:
#	Provides the player with a computer opponent to play against
#	This module attempts to block player moves using a similar principle behind the 
#		check_win module
#	Uses a complex set of powerful comparitives to provide an obstacle to a player win
bot_opponent_move:
	block_move:
		la $t1, ($ra) # save return address
		li $t2, 0 # temp value for comparisons
		li $t3, 0 # index plus delta, used to retrieve adjacent values
		li $t4, 0 # comparison reg
		
		bgt $t5, 11, vert_block_failed
		
		vert_block:
			li $s0, 0
			la $s2, ($t5)
			jal access_board
				
			la $t2, ($s1)
				
			add $t3, $t5, 3
				
			li $s0, 0
			la $s2, ($t3)
			jal access_board
				
			bne $s1, $t2, vert_block_failed # if left dne middle
				
			add $t3, $t5, 6
				
			li $s0, 0
			la $s2, ($t3)
			jal access_board
				
			bne $s1, $t2, block # if left dne right
				
			
			vert_block_failed:
			
		beq $s3, 0, left_block
		beq $s3, 1, middle_block
		beq $s3, 2, right_block
		
		
		left_block:
			left_horizontal_block:
				li $s0, 0
				la $s2, ($t5)
				jal access_board
				
				la $t2, ($s1)
				
				add $t3, $t5, 1
				
				li $s0, 0
				la $s2, ($t3)
				jal access_board
				
				bne $s1, $t2, left_hblock_failed # if left dne middle
				
				add $t3, $t5, 2
				
				li $s0, 0
				la $s2, ($t3)
				jal access_board
				
				bne $s1, $t2, block # if left dne right
				
				
				
			left_hblock_failed:
			
			slti $t4, $t5, 6
			beq $t4, 0, left_uDblock_failed
			
			left_up_diagonal_block:
				li $s0, 0
				la $s2, ($t5)
				jal access_board
				
				la $t2, ($s1)
				
				sub $t3, $t5, 2
				
				li $s0, 0
				la $s2, ($t3)
				jal access_board
				
				bne $s1, $t2, left_uDblock_failed # if left dne middle
				
				sub $t3, $t5, 4
				
				li $s0, 0
				la $s2, ($t3)
				jal access_board
				
				bne $s1, $t2, block # if left dne right
				
			
			left_uDblock_failed:
			
			bgt $t5,11, left_block_failed
			left_down_diagonal_block:
				li $s0, 0
				la $s2, ($t5)
				jal access_board
				
				la $t2, ($s1)
				
				add $t3, $t5, 4
				
				li $s0, 0
				la $s2, ($t3)
				jal access_board
				
				bne $s1, $t2, left_block_failed # if left dne middle
				
				add $t3, $t5, 8
				
				li $s0, 0
				la $s2, ($t3)
				jal access_board
				
				bne $s1, $t2, block # if left dne right
				
			
			left_block_failed:
				b no_block
				
		middle_block:
			middle_horizontal_block:
				li $s0, 0
				la $s2, ($t5)
				jal access_board
				
				la $t2, ($s1)
				
				sub $t3, $t5, 1
				
				li $s0, 0
				la $s2, ($t3)
				jal access_board
				
				bne $s1, $t2, middle_hblock_failed # if left dne middle
				
				add $t3, $t5, 1
				
				li $s0, 0
				la $s2, ($t3)
				jal access_board
				
				bne $s1, $t2, block # if left dne right
				

				
				
			middle_hblock_failed:
			
			
			bgt $t5, 15, no_block
			blt $t5, 2, no_block
			
			middle_up_diagonal_block:
				li $s0, 0
				la $s2, ($t5)
				jal access_board
				
				la $t2, ($s1)
				
				add $t3, $t5, 2
				
				li $s0, 0
				la $s2, ($t3)
				jal access_board
				
				bne $s1, $t2, middle_uDblock_failed # if left dne middle
				
				sub $t3, $t5, 2
				
				li $s0, 0
				la $s2, ($t3)
				jal access_board
				
				bne $s1, $t2, block # if left dne right
				
				
			
			middle_uDblock_failed:
			
			middle_down_diagonal_block:
				li $s0, 0
				la $s2, ($t5)
				jal access_board
				
				la $t2, ($s1)
				
				sub $t3, $t5, 4
				
				li $s0, 0
				la $s2, ($t3)
				jal access_board
				
				bne $s1, $t2, no_block # if left dne middle
				
				add $t3, $t5, 4
				
				li $s0, 0
				la $s2, ($t3)
				jal access_board
				
				bne $s1, $t2, block # if left dne right
				
				
			

		right_block:
			right_horizontal_block:
				li $s0, 0
				la $s2, ($t5)
				jal access_board
				
				la $t2, ($s1)
				
				sub $t3, $t5, 1
				
				li $s0, 0
				la $s2, ($t3)
				jal access_board
				
				bne $s1, $t2, right_hblock_failed # if left dne middle
				
				sub $t3, $t5, 2
				
				li $s0, 0
				la $s2, ($t3)
				jal access_board
				
				bne $s1, $t2, block # if left dne right
				

				
				
			right_hblock_failed:
			
			blt $t5, 6 ,right_uDblock_failed
			
			right_up_diagonal_block:
				li $s0, 0
				la $s2, ($t5)
				jal access_board
				
				la $t2, ($s1)
				
				sub $t3, $t5, 8
				
				li $s0, 0
				la $s2, ($t3)
				jal access_board
				
				bne $s1, $t2, right_uDblock_failed # if left dne middle
				
				sub $t3, $t5, 4
				
				li $s0, 0
				la $s2, ($t3)
				jal access_board
				
				bne $s1, $t2, block # if left dne right
				

			
			right_uDblock_failed:
			
			bgt $t5,12, no_block
			right_down_diagonal_block:
				li $s0, 0
				la $s2, ($t5)
				jal access_board
				
				la $t2, ($s1)
				
				add $t3, $t5, 4
				
				li $s0, 0
				la $s2, ($t3)
				jal access_board
				
				bne $s1, $t2, no_block # if left dne middle
				
				add $t3, $t5, 2
				
				li $s0, 0
				la $s2, ($t3)
				jal access_board
				
				bne $s1, $t2, block # if left dne right
				
				
				
		block:
			li $t4, 3
			div $t3, $t4
			mflo $t4
			la $s3, ($t4)
			b oppo_movement_end
			
	no_block:
		li $v0, 42
		li $a0, 123
		li $a1, 200
		syscall
		li $v0, 42
		li $a0, 123
		li $a1, 3
		syscall
		la $s3, ($a0)
	oppo_movement_end:
		la $ra, ($t1)
		jr $ra
	
	

# The print_winner uses leftover values from play_column to determine the winner and the winning move 
# Inputs:
# 	Passed over from play_column
#	$t5
# Outputs:
#	None, outputs to console (user)
# Description:
#	This program prints a message indicating which player won and what their final move was
print_winner:
	la $t4, ($ra)
	li $t1,3
	div $t5, $t1
	
	mflo $t1
	mfhi $t2
	add $t1,$t1, 1
	
	beq $s4, 1, player_won
	beq $s4, 2, computer_won
	
	player_won:
		li $v0,4
		la $a0,playerWin
		syscall
		jal play_win_sound
		b print_winner_end
	
	computer_won:
		li $v0,4
		la $a0,computerWin
		syscall
		jal play_lose_sound
		b print_winner_end
	
	print_winner_end:
		li $v0, 4
		la $a0, winningMove
		syscall
		li $v0, 1
		la $a0, ($t1)
		syscall
		beq $t2,0,print_col_A
		beq $t2,1,print_col_B
		beq $t2,2,print_col_C
	
		print_col_A:
			li $v0, 4
			la $a0, columnA
			syscall
			b jump_ship
		
		print_col_B:
			li $v0, 4
			la $a0, columnB
			syscall
			b jump_ship
		
		print_col_C:
			li $v0, 4
			la $a0, columnC
			syscall
	
	jump_ship:
	la $ra, ($t4)
	jr $ra
	

play_win_sound:
	li $v0, 33
	li $a0, 70
	li $a1, 500
	li $a2, 7
	li $a3, 100
	syscall
	li $v0, 33
	li $a0, 85
	li $a1, 500
	li $a2, 7
	li $a3, 100
	syscall
	li $v0, 33
	li $a0, 89
	li $a1, 500
	li $a2, 7
	li $a3, 100
	syscall
	jr $ra

play_wrong_move:
	li $v0, 33
	li $a0, 55
	li $a1, 700
	li $a2, 1
	li $a3, 100
	syscall
	jr $ra

play_lose_sound:
	li $v0, 33
	li $a0, 40
	li $a1, 2000
	li $a2, 3
	li $a3, 100
	syscall
	jr $ra

play_player_move_sound:
	li $v0, 33
	li $a0, 85
	li $a1, 500
	li $a2, 4
	li $a3, 100
	syscall
	jr $ra
