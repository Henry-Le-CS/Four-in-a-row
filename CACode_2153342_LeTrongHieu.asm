.data
	boardArray: .space 42
	colLine: .asciiz "|"
	endl: .asciiz "\n"
	dash: .asciiz "_"
	XSymbol: .asciiz "X"
	OSymbol: .asciiz "O"
	AWin: .asciiz "\nPlayer A won this game!!!"
	BWin: .asciiz "\nPlayer B won this game!!!"
	Threat: .asciiz "\nMovement violation!!! You have "	
	Chances: .asciiz " more chance(s) left if violating. Please Enter again!\n"
	ThreatRedo: .asciiz "\nRedo violation!!! You have "	
	AEnter: .asciiz "\nPlayer A's turn to move: "
	BEnter: .asciiz "\nPlayer B's turn to move: "
	Sure: .asciiz "\nDo you want to undo your move? You have "
	ChancesRedo: .asciiz " chance(s) left to redo.\n1 -> Continue, other number -> Undo: "
	DrawGame: .asciiz "\nThe game's result is draw!!!"
	PlayerAInfo: .asciiz "     Player A: "
	PlayerBInfo: .asciiz "     Player B: "
	Introduction: .asciiz "Welcome to Hieu Le's FOUR IN A ROW.\nIn this game, Each player then alternately takes a turn placing a piece in any column that is not already full.\nThe piece fall straight down.\nThe first to get 4 connected pieces will win.\nEnjoy!!!\n\n"
	NextGame:  .asciiz "\nDo you want to start a new game?\n1 -> Yes, other number -> No:  "
	TotalPoints: .asciiz "     Current Score: "
	Final: .asciiz "\nThe final result is: "
	Thanks: .asciiz "\n\nThank you for playing my game!!!"
	DashNormal: .asciiz "-"
	CurrentTurn: .asciiz "     Current turn: "
	PlayerA: .asciiz "Player A"
	PlayerB: .asciiz "Player B"
	PlayerAChoose: .asciiz "Player A, please choose your symbol. Number 0 -> O, other number -> X: "
	PlayerBChoose: .asciiz "Player B, please choose your symbol. Number 0 -> O, other number -> X: "
	NoChance: .asciiz "Sorry, you have no chance left to redo!\n"
.text
#List of Registers I use as global variable:
# $s1, $s2: X or O randomly for Player A and Player B respectively
# $s3, $s4: Chances left when violating the rules for Player A and Player B respectively
# $s5, $s6: Chances left to redo the movement for Player A and Player B respectively
# Ss0, $s7: Points for Player A and Player B respectively
# $a3: Latest move
# $a2: Current turn

#Print game introduction
li $s0, 0
li $s7, 0
li $v0, 4
la $a0, Introduction #printIntroduction
syscall
PlayerPick:
#-------------------PLAYER PICK SYMBOL----------------------#
#We randomly choose a player and let them choose their symbols. X->1, O->0
li $a0, 1
li $a1, 2
li $v0, 42 #Randomly choose integer from [0,1]#
syscall #randomly assing 0 or 1 for $a0 (Randomly choose a player). 0 -> Player A, 1 -> PlayerB
beq $a0, 1, PlayerBchoice
	la $a0, PlayerAChoose
	li $v0, 4
	syscall
	li $v0, 5
	syscall
	bne $v0, 0, AX #A chose O
	li $s1, 0
	li $s2, 1
	j InitBA #A chose X
	AX:
	li $s1, 1
	li $s2, 0
	j InitBA
PlayerBchoice:
	la $a0, PlayerBChoose
	li $v0, 4
	syscall
	li $v0, 5
	syscall
	bne $v0, 0, BX #B chose O
	li $s1, 1
	li $s2, 0
	j InitBA #B chose X
	BX:
	li $s1, 0
	li $s2, 1

#----------------END PLAYER PICK SYMBOL---------------------#


#-----------------------------INITIALIZING----------------------------------#
Initialize:
li $t0, 0 #index for looping InitBA
InitBA: #We initialize the boardArray with full of 0
	beq $t0, 42, ExitInitBA
	li $t1, 0
	sb $t1, boardArray($t0)
	addi $t0, $t0, 1
	j InitBA
ExitInitBA: 
	li $s3, 3
	li $s4, 3
	li $s5, 3
	li $s6, 3 #3 chances for all cases for each player
	li $a2, 1 
#-----------------------------END INITIALIZING----------------------------------#

#---------------------------------MAIN------------------------------------------#
.globl main
#The main function that I use to loop throughout the game
main:
	li $a2, 1
	jal DrawFullBoard
	la $a0, AEnter
	li $v0, 4
	syscall
	li $v0, 5
	syscall
	li $a0, 1
	subi $v0, $v0, 1
	move $a1, $v0
	jal StoreInput #Store into the array
	move $a3, $v0	#Latest move
	jal DrawFullBoard #Draw the board
	li $a0, 1
	move $v0, $a3
	jal WinnerCheck #Check if player A won
SureA:
	la $a0, Sure
	li $v0, 4
	syscall
	move $a0, $s5
	li $v0, 1
	syscall
	la $a0, ChancesRedo
	li $v0, 4
	syscall #Print how many chances to redo player A still have
	li $v0, 5 #The player's choices
	syscall
	beq $v0, 1, BInput #Print their chances of redoing and check, 1 = redo
	li $a0, 1
	j Redo
BInput:
	li $a2, 2
	jal DrawFullBoard
	la $a0, BEnter
	li $v0, 4
	syscall
	li $v0, 5
	syscall
	li $a0, 2
	subi $v0, $v0, 1
	move $a1, $v0
	jal StoreInput #Store into the array
	move $a3, $v0	#Latest move
	jal DrawFullBoard #Draw the board
	li $a0, 2
	move $v0, $a3
	jal WinnerCheck #Check if player B won
SureB:
	la $a0, Sure
	li $v0, 4
	syscall
	move $a0, $s6
	li $v0, 1
	syscall
	la $a0, ChancesRedo
	li $v0, 4
	syscall #Print how many chances to redo player B still have
	li $v0, 5
	syscall
	beq $v0, 1, main #Reloop the main function
	li $a0, 2
	j Redo
#--------------------END OF MAIN----------------#

#--------------------Begin Drawing-----------------------#
DrawFullBoard: #it requires to draw each row via function DrawRow($a0 = begin_position)
	la $a0, endl
	li $v0, 4
	syscall #Create Space to look nicer
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	li $a0, 35
	jal DrawRow
	la $a0, PlayerAInfo #Display the player A's X or O next to the first row
	li $v0, 4
	syscall
	bne $s1, $0, XInfo #If else function to see his/her X or O
	la $a0, OSymbol
	li $v0, 4
	syscall
	j Line28
	XInfo:
	la $a0, XSymbol
	li $v0, 4
	syscall
Line28: # to jump here after print symbol of playerA
	la $a0, endl
	li $v0, 4
	syscall
	li $a0, 28
	jal DrawRow
	la $a0, PlayerBInfo #Display the player A's X or O next to the second row
	li $v0, 4
	syscall
	bne $s2, $0, X1Info #If else function to see his/her X or O
	la $a0, OSymbol
	li $v0, 4
	syscall
	j Line21
	X1Info:
	la $a0, XSymbol
	li $v0, 4
	syscall
Line21: # to jump here after print symbol of playerB
	la $a0, endl
	li $v0, 4
	syscall
	li $a0, 21
	jal DrawRow
	la $a0, TotalPoints #Print Current TotalPoints
	li $v0, 4
	syscall
	move $a0, $s0 #Points of Player A
	li $v0, 1
	syscall
	la $a0, DashNormal # "-"
	li $v0, 4
	syscall
	li $v0, 1
	move $a0, $s7 #Points of Player B
	syscall
	la $a0, endl
	li $v0, 4
	syscall
Line14:
	li $a0, 14
	jal DrawRow
	#Next print currentTurn
	la $a0, CurrentTurn
	li $v0, 4
	syscall
	beq $a2, 2, Bturn
	la $a0, PlayerA
	syscall
	j Line7
	Bturn:
	la $a0, PlayerB
	syscall
Line7:
	la $a0, endl
	li $v0, 4
	syscall
	li $a0, 7
	jal DrawRow
	la $a0, endl
	li $v0, 4
	syscall
Line0:
	li $a0, 0
	jal DrawRow
	la $a0, endl
	li $v0, 4
	syscall
	jal DrawNumber #Draw the number at the end of table for the player to locate easier
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
#input: $a0 = index of beginning of the line
DrawRow:
	move $t0, $a0
	addi $t1, $t0, 7
	loopDrawRow:
		beq $t0, $t1, exitDrawRow #if(i = i+8 ->  at the end of the row, break)
		la $a0, colLine #print "|" before every number 
		li $v0, 4
		syscall
		#Load value at ith of the array out to check#
		lb $t2, boardArray($t0)
		#Case $t2 = 0
		bne $t2, 0, isOne
		la $a0, dash
		li $v0, 4
		syscall
		j contDrawRow
		#Case $t2 = 1
		isOne:
		bne $t2, 1, Two 
			beq $s1, 1, itsX
			la $a0, OSymbol
			li $v0, 4
			syscall
			j contDrawRow
			itsX:
			la $a0, XSymbol
			li $v0, 4
			syscall
			j contDrawRow
		#Case $t2 = 2
		Two:
			beq $s2, 1, itsX
			la $a0, OSymbol
			li $v0, 4
			syscall
			j contDrawRow
		contDrawRow:
			addi $t0, $t0, 1
			j loopDrawRow
	exitDrawRow:
		la $a0, colLine #Draw the encapsulation "|"
		li $v0, 4
		syscall
		jr $ra
DrawNumber:
	li $t0, 1
	loop_DrawNumber:
		beq $t0, 8, exitDrawNumber
		la $a0, colLine #Draw the encapsulation "|"
		li $v0, 4
		syscall
		move $a0, $t0
		li $v0, 1
		syscall
		addi $t0, $t0, 1
		j loop_DrawNumber #loop until 8 is reached
	exitDrawNumber:
		la $a0, colLine
		li $v0, 4
		syscall
		la $a0, endl
		syscall
		jr $ra
		
#----------------------------END OF DRAW------------------------------------#

#----------------------------STORE INPUT------------------------------------#
#StoreInput($a0 = who, $a1 = where) is a fuction to store the players' entered values
#Here, we will use $s3, $s4 for the violation chances left for player A, B, respectively
StoreInput:
	slti $t0, $a1, 0 # return 1 if $a1 < 1, 0 if $a1 >= 1. We take care of case 1
	slti $t1, $a1, 7 # return 1 if $a1 < 7, 0 if $a1 >= 7. We take care of case 0
	move $t2, $a0 #Save it in case we lose
	beq $t1, 0, Violate
	beq $t0, 1, Violate
	move $t0, $a1 # temp = where
	LoopFind: #Find possible slots#
		bgtu $t0, 41, Violate
		lb $t1, boardArray($t0)
		#If $t1 == 0
		
		bne $t1, 0, ContFind # If value at $t0 is not EMPTY, continue finding
			sb $t2, boardArray($t0) #If = 0 just store player 1 or 2 into that and return
			beq $t2, 2, PlayerBMove
				move $v0, $t0 #Return $v0 so it can be used for redo
				jr $ra
			PlayerBMove:
				move $v0, $t0
				jr $ra
		ContFind:
			addi $t0, $t0, 7
			j LoopFind #else just i+=7 and find it in the array
	Violate:
		beq $t2, 2, BViolate
		#Player A violate#
		beq $s3, 0, ALose #chances = 0
		subi $s3, $s3, 1
		la $a0, Threat
		li $v0, 4
		syscall
		move $a0, $s3
		li $v0, 1
		syscall
		la $a0, Chances
		li $v0, 4
		syscall #Print warning for player A#
		j main
		#Player B violate#
		BViolate:
		beq $s4, 0, BLose #chanes =0
		subi $s4, $s4, 1
		la $a0, Threat
		li $v0, 4
		syscall
		move $a0, $s4
		li $v0, 1
		syscall
		la $a0, Chances
		li $v0, 4
		syscall #Print warning for player B#
		j BInput
	ALose:
		li $a0, 2 #Which means player B win#
		j Winner
	BLose:
		li $a0, 1 #Which means player A win#
		j Winner
#----------------------------END STORE INPUT--------------------------------#
#-------------------------------REDO----------------------------------------#
# Redo($a0 = who, $a3 = where)
Redo:
	move $t5, $a0 #OTher temporary register will be used in DrawFullBoard so I have to use $t5
	beq $t5, 2, BRedo
		beq $s5, 0, ANoChance #No chance left for player A
		subi $s5, $s5, 1
		sb $zero, boardArray($a3) #Make that position on the board 0 to make it null before making the new movement
		jal DrawFullBoard
		j main
	BRedo:
		beq $s6, 0, BNoChance #No chance left for player B
		subi $s6, $s6, 1
		sb $zero, boardArray($a3) #Make that position on the board 0 to make it null before making the new movement
		move $t5, $a0 #OTher temporary register will be used in DrawFullBoard so I have to use $t5
		jal DrawFullBoard
		j BInput
	ANoChance:
		la $a0, NoChance
		li $v0, 4
		syscall
		j BInput
	BNoChance:
		la $a0, NoChance
		li $v0, 4
		syscall
		j main
		

#-------------------------------END REDO------------------------------------#


#----------------------------WINNER REPORT-----------------------------------#
#input $a0 = 1 or 2 is the player who win the game
Winner:
	beq $a0, 2, TwoWin
	addi $s0, $s0, 1
	la $a0, AWin
	li $v0, 4
	syscall
	la $a0, NextGame
	li $v0, 4
	syscall
	li $v0, 5
	syscall
	bne $v0, 1, EndGame
	j Initialize
	TwoWin:
	addi $s7, $s7, 1
	la $a0, BWin
	li $v0, 4
	syscall
	la $a0, NextGame
	li $v0, 4
	syscall
	li $v0, 5
	syscall
	bne $v0, 1, EndGame
	j Initialize
EndGame:
	la $a0, Final
	li $v0, 4
	syscall
	move $a0, $s0
	li $v0, 1
	syscall
	la $a0, DashNormal
	li $v0, 4
	syscall
	li $v0, 1
	move $a0, $s7
	syscall
	la $a0, Thanks
	li $v0, 4
	syscall
	li $v0, 10
	syscall
#----------------------------END WINNER REPORT-------------------------------#

#----------------------------CHECK WINNER------------------------------------#
#Input($a0 = who, $v0 = last inserted position)
WinnerCheck:
	#We have to check 4 direction:
	#1. Vertical
	#2. Horizontal
	#3. Upward Diagonal
	#4. Downward Diagonal
	#---------------Vertical---------------#
	li $t9, 1
	move $t0, $v0
	CheckUp:
		bgt $t0, 34, ExitCheckUp # We are on the 6-th row, cant go any further
		addi $t0, $t0, 7
		lb $t3, boardArray($t0)
		bne $t3, $a0, ExitCheckUp
		addi $t9, $t9, 1
		bgt $t9, 3, Winner
		j CheckUp
	ExitCheckUp:
		move $t0, $v0
	CheckDown:
		blt $t0, 7, ExitCheckDown
		subi $t0, $t0,7
		lb $t3, boardArray($t0)
		bne $t3, $a0, ExitCheckDown
		addi $t9, $t9, 1
		bgt $t9, 3, Winner
		j CheckDown
	ExitCheckDown:
		li $t9, 1
		move $t0, $v0
	#---------------END VERTICAL---------------#
	
	#---------------HORIZONTAL-----------------#
	
	li $t7, 7
	CheckLeft:
		div $t0,$t7
		mfhi $t3
		beqz $t3, ExitCheckLeft #If(i%7==0) then we are at the leftmost position, cant go left
		subi $t0, $t0, 1
		lb $t4, boardArray($t0)
		bne $t4, $a0, ExitCheckLeft #If they are not equal anymore we can check on the right
		addi $t9,$t9, 1
		bgt $t9, 3, Winner
		j CheckLeft
	ExitCheckLeft:
		move $t0, $v0
	CheckRight:
		div $t0, $t7
		mfhi $t3
		beq $t3, 6, ExitCheckRight #If(i%7==6) then we are at the rightmost position, cant go right
		addi $t0, $t0, 1
		lb $t4, boardArray($t0)
		bne $t4, $a0, ExitCheckRight
		addi $t9, $t9, 1
		bgt $t9, 3, Winner
		j CheckRight
	ExitCheckRight:
		move $t0, $v0
		li $t9, 1
	#---------------END HORIZONTAL-------------#
	
	#---------------UPWARD-DIRECTION DIAGONAL------------#
	
	
	#----------------------UP RIGHT------------------------#
	CheckUpRight:
		bgt $t0, 34, ExitCheckUpRight #We are at the top level of the table
		div $t0, $t7
		mfhi $t3
		beq $t3, 6, ExitCheckUpRight #We are at the right-most level of the table
		addi $t0, $t0, 8	
		lb $t4, boardArray($t0)
		bne $t4, $a0, ExitCheckUpRight
		addi $t9, $t9, 1
		bgt $t9, 3, Winner
		j CheckUpRight
	ExitCheckUpRight:
		move $t0, $v0
	#-------------------END UP RIGHT---------------------#
	#---------------------DOWN LEFT----------------------#
	CheckDownLeft:
		blt $t0, 7, ExitCheckDownLeft
		div $t0, $t8
		mfhi $t3
		beqz $t3, ExitCheckDownLeft
		subi $t0, $t0, 8
		lb $t4, boardArray($t0)
		bne $t4, $a0, ExitCheckDownLeft
		addi $t9, $t9, 1
		bgt $t9, 3, Winner
		j CheckDownLeft
	ExitCheckDownLeft:
		move $t0, $v0	
		li $t9, 1
	#-------------------END DOWN LEFT---------------------#
	#------------END UPWARD-DIRECTION DIAGONAL------------#
	#---------------DOWNWARD-DIRECTION DIAGONAL-----------#
	#-----------------------UP LEFT-----------------------#
	CheckUpLeft:
		bgt $t0, 34, ExitCheckUpLeft
		div $t0, $t7
		mfhi $t3
		beqz $t3, ExitCheckUpLeft
		addi $t0, $t0, 6
		lb $t4, boardArray($t0)
		bne $t4, $a0, ExitCheckUpLeft
		addi $t9, $t9, 1
		bgt $t9, 3, Winner
		j CheckUpLeft
	ExitCheckUpLeft:
		move $t0, $v0
	#---------------------END UP LEFT---------------------#
	#----------------------DOWN RIGHT---------------------#
	CheckDownRight:
		blt $t0, 7, ExitCheckDownRight
		div $t0, $t7
		mfhi $t3
		beq $t3, 6, ExitCheckDownRight
		addi $t0, $t0, -6
		lb $t4, boardArray($t0)
		bne $t4, $a0, ExitCheckDownRight
		addi $t9, $t9, 1
		bgt $t9, 3, Winner
		j CheckDownRight
	ExitCheckDownRight:
	#-------------------- END DOWN RIGHT------------------#
	#-------------END DOWNWARD-DIRECTION DIAGONAL---------#
	
	#-----------------------DRAW GAME---------------------#
		#ONLY HAPPEN IF THE TOP LINE ARE ALL FULL#	
	li $t0, 35
	loop_check:
		beq $t0, 42, ConcludeDraw
		lb $t1, boardArray($t0)
		beq $t1, 0, ExitCheck
		addi $t0, $t0, 1
		j loop_check
	ExitCheck:
		jr $ra
	ConcludeDraw:
		addi $s0, $s0, 1
		addi $s7, $s7, 1
		la $a0, DrawGame
		li $v0, 4
		syscall
		la $a0, NextGame
		li $v0, 4
		syscall
		li $v0, 5
		syscall
		bne $v0, 1, EndGame
		j Initialize
	
#---------------------------END CHECK WINNNER--------------------------------#
	

	
