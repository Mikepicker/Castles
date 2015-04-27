
extends Control

const CARD_SIZE = 64
const GRID_HEIGHT = 4
const GRID_WIDTH = 4
const GRID_HEIGHT = 4
const CARD_SPEED = 10
var CASTLES_TO_WIN = 0 # Loaded from disk

# Card Types
var cardTypes = [
	"archer",
	"warrior",
	"knight",
	"tower",
	"castle"
	]
	
# Card Movements
var cardMovements = {
	"archer":1,
	"warrior":1,
	"knight":1,
	"tower":1,
	"castle":0
}

# Game State (PLAYER_TURN, PLAYER_MOVING, PLAYER_MERGING, PLAYER_ATTACKING, ENEMY_TURN, "GAME_WON", "GAME_OVER")
var currentState = "PLAYER_TURN"
var playerMovesLeft = 3 # How many moves has the player left for his turn

# Scenes
var cardScene = preload("res://card.scn")
var explosionScene = preload("res://explosion.scn")

# Textures
var gridTex = preload("board.png")
var cardTextures = {
	"blue_archer":preload("blue_archer_card.png"),
	"blue_warrior":preload("blue_warrior_card.png"),
	"blue_knight":preload("blue_knight_card.png"),
	"blue_tower":preload("blue_tower_card.png"),
	"blue_castle":preload("blue_castle_card.png"),
	"red_archer":preload("red_archer_card.png"),
	"red_warrior":preload("red_warrior_card.png"),
	"red_knight":preload("red_knight_card.png")
	}

# Does First beats Second?
# __________| archer | warrior | knight |
# archer	|    0   |    1    |   2    |
# warrior	|    2   |    0    |   1    |
# knight	|    1   |    2    |   0    |
# tower		|    1   |    1    |   1    |
# Where: 0 -> Both cards die
#		 1 -> First card wins
#		 2 -> Second card wins
var firstBeatsSecondTable = {
	"archer":{"archer":0,"warrior":1,"knight":2},
	"warrior":{"archer":2,"warrior":0,"knight":1},
	"knight":{"archer":1,"warrior":2,"knight":0},
	"tower":{"archer":1,"warrior":1,"knight":1},
	"castle":{"archer":1,"warrior":1,"knight":1}
	}

# Matching matrix
var mergeResult = {
	"archer":"tower",
	"warrior":"tower",
	"knight":"tower",
	"tower":"castle",
	"castle":null
	}
	
# Input variables
var clickedCell = null	# Keeps track of pressed cell position
var currentSwipePos = null	# Keeps track of the swipe action
var selectionIndex = 0		# Keeps track of the current chosen card

# Action variables (move, attack, merge..)
var selectedCard = null
var cardBeingSelected = null
var cellDest = null # Destination Cell (where the selected card has to go
var lambda = 0		# Interpolation factor (movement)

# Game 4x4 Grid
var grid = {}

# Castles number
var castles = 0

# Score
var score = 0
var scoreLabel = null

# Animations
var gameWonAnim = null
var gameOverAnim = null
var animTrigger = false

func _ready():
	# Load level
	loadLevel()
	
	scoreLabel = get_parent().get_node("ScoreLabel")
	scoreLabel.set_text("Score 0")
	gameWonAnim = get_parent().get_node("Anims/GameWonAnim")
	gameOverAnim = get_parent().get_node("Anims/GameOverAnim")
	
	# Seed Rand
	rand_seed(OS.get_ticks_msec())
	
	# Sample Cards
	# createCard("archer", Vector2(1,1), "blue")
	# createCard("warrior", Vector2(1,3), "blue")
	# createCard("knight", Vector2(2,3), "blue")
	
	set_process(true)
	set_process_input(true)

func _process(delta):

	# Update moves
	if (playerMovesLeft > 0):
		get_parent().get_node("MovesLabel").set_text("MOVES " + str(playerMovesLeft))
	
	checkGameOver()

	if (castles == CASTLES_TO_WIN):
		saveScore()
		saveNewLevel()
		set_process_input(false)
		if (!animTrigger):
			gameWonAnim.play("GameWon")
			animTrigger = true
			
		print("YOU WON!")
		return
		
	if (currentState == "GAME_OVER"):
		saveScore()
		set_process_input(false)
		if (!animTrigger):
			gameOverAnim.play("GameOver")
			animTrigger = true
			
		print("GAME OVER!")
	elif (currentState == "PLAYER_TURN" && playerMovesLeft <= 0):
		set_process_input(true)
		selectedCard = null
		currentState = "ENEMY_TURN"
		playerMovesLeft = 3
	elif (currentState == "PLAYER_MOVING"):
		set_process_input(false)
		moveSelectedCard(delta)
	elif (currentState == "PLAYER_MERGING"):
		set_process_input(false)
		moveAndMerge(delta)
	elif (currentState == "PLAYER_ATTACKING"):
		set_process_input(false)
		moveAndAttack(delta)
	elif (currentState == "ENEMY_TURN"):
		set_process_input(false)
		spawnRandomEnemy()
		spawnRandomEnemy()
		currentState = "PLAYER_TURN"

###############################
############ INPUT ############
###############################
func _input_event(ev):

	if (currentState != "PLAYER_TURN"):
		pass
	
	# Detect touch
	if (ev.type == InputEvent.MOUSE_BUTTON || ev.type == InputEvent.SCREEN_TOUCH && checkInput(ev.pos)):
		if (ev.is_pressed()):
			# Click
			if (clickedCell == null):
				var remappedPos = ev.pos/CARD_SIZE
				if (floor(remappedPos.x) >= 0 && floor(remappedPos.x) < GRID_WIDTH &&
					floor(remappedPos.y) >= 0 && floor(remappedPos.y) < GRID_HEIGHT):
					clickedCell = Vector2(floor(remappedPos.x), floor(remappedPos.y))
					if (clickedCell in grid):
						selectedCard = grid[clickedCell]
		# Unclick
		else:
			# Reset card being selected
			if (selectedCard == null && cardBeingSelected != null):
				print("RESET CARD BEING SELECTED")
				cardBeingSelected.triggerSelection()
				cardBeingSelected = null
				
			# Detect card selection (when the user wants to create a new card)
			if (selectedCard == null || 
			   (selectedCard.beingSelected && 
			   (currentSwipePos == null || currentSwipePos == selectedCard.currentCell))):
				cardSelection()
			elif (currentSwipePos != null && selectedCard.cardSide == "blue"):
				finalizeSwipeAction()
			else: # Red card is selected
				selectedCard = null
				
			# Reset values
			clickedCell = null
			currentSwipePos = null
	
	# Track swipe motion
	if ((ev.type == InputEvent.MOUSE_MOTION) 
		&& selectedCard != null && checkInput(ev.pos)):
		var remappedPos = ev.pos/CARD_SIZE
		if (floor(remappedPos.x) >= 0 && floor(remappedPos.x) < GRID_WIDTH &&
			floor(remappedPos.y) >= 0 && floor(remappedPos.y) < GRID_HEIGHT):
			currentSwipePos = Vector2(floor(remappedPos.x), floor(remappedPos.y))

func cardSelection():
	# New card
	if (selectedCard == null):
		print("NEW CARD")
		selectionIndex = 0
		cardBeingSelected = createCard(cardTypes[selectionIndex], clickedCell, "blue")
		cardBeingSelected.triggerSelection()
		playerMovesLeft -= 1
	# Change new card
	else:
		print("CHANGE CARD")
		selectionIndex = (selectionIndex+1)%3
		selectedCard.setCardType(cardTypes[selectionIndex], selectedCard.cardSide)
	
	selectedCard = null
	
func finalizeSwipeAction():
	#if (selectedCard.cardType == "castle"): # Castle can't move ;)
		#selectedCard = null
		#return
			
	# Deselect card that has been created (if applicable)
	if (cardBeingSelected != null):
		print("DESELECT")
		cardBeingSelected.triggerSelection()
		cardBeingSelected = null
		
	# Swipe Detected -> Move selected card
	var dir = currentSwipePos - clickedCell
	
	# Clamp (no diagonal moves)
	if (abs(dir.x) >= abs(dir.y)):
		dir.y = 0
	else:
		dir.x = 0
	
	# Normalize
	dir = dir.normalized()
	
	# The cell it has to arrive to
	cellDest = clickedCell + dir * cardMovements[selectedCard.cardType]
	
	# Clamp (grid bounds)
	cellDest.x = clamp(cellDest.x, 0, GRID_WIDTH-1)
	cellDest.y = clamp(cellDest.y, 0, GRID_HEIGHT-1)
	
	# Next state
	var nextState = "PLAYER_TURN"
	
	# Check for collision
	var currPos = clickedCell
	currPos += dir
		
	# Check for attack
	if (currPos in grid && canAttack(selectedCard, grid[currPos]) && selectedCard.cardType != "castle"):
		cellDest = currPos
		nextState = "PLAYER_ATTACKING"
		selectedCard.set_z(1)
		grid[cellDest].set_z(0.5)
	# Check for card fusion
	elif (currPos in grid && canMerge(selectedCard, grid[currPos])):
		cellDest = currPos
		nextState = "PLAYER_MERGING"
		selectedCard.set_z(1)
		grid[cellDest].set_z(0.5)
	else:	# Check where the card has to go to
		nextState = "PLAYER_MOVING"
		var i = 1
		while(i < cardMovements[selectedCard.cardType]+1):
			if (currPos in grid):
				cellDest = currPos - dir
				break
			currPos += dir
			i += 1
	
		# Unable to move
		if (cellDest == clickedCell):
			nextState = "PLAYER_TURN"
			selectedCard = null
	
	print("Changing state to " + nextState)
	currentState = nextState
		
func checkInput(pos):
	var realPos = get_pos() + pos
	return (realPos.x >= 0 && 
		realPos.x <= get_pos().x + GRID_WIDTH * CARD_SIZE && 
		realPos.y >= 0 && 
		realPos.y <= get_pos().y + GRID_HEIGHT * CARD_SIZE)
	
#######################################
############ CARD HANDLERS ############
#######################################
# Register a card to another cell
func changeCell(card,cell):
	print(cell)
	grid.erase(card.currentCell)
	card.set_pos(cell*CARD_SIZE)
	card.currentCell = cell
	grid[cell] = card
	selectedCard == null
		
# Creates new card
func createCard(type, pos, side):
	var card = cardScene.instance()
	add_child(card)
	card.setCardType(type, side)
	grid[pos] = card
	card.get_node("Sprite").set_centered(false)
	card.set_pos(pos * CARD_SIZE)
	card.currentCell = pos
	card.set_z(1)
	return card

func removeCard(card):
	# Update Score
	if (card.cardSide == "red"):
		score += 10
		scoreLabel.set_text("Score " + str(score))
		
	grid.erase(card.currentCell)
	card.free()
	
########################################
############ PLAYER ACTIONS ############
########################################

# Function to move cards
func moveSelectedCard(delta):
	if (lambda >= 1):
		currentState = "PLAYER_TURN"
		changeCell(selectedCard, cellDest)
		lambda = 0
		
		playerMovesLeft -= 1
			
		selectedCard = null
		cellDest = null
		
	else:	
		selectedCard.set_pos(selectedCard.currentCell.linear_interpolate(cellDest,lambda) * CARD_SIZE)
		lambda += CARD_SPEED*delta
		
# Check if two cards can merge
func canMerge(card1, card2):
	return (card1 != card2 &&
		   (card1.cardSide == card2.cardSide && card1.cardType == card2.cardType))

# Card fusion (TODO)
func moveAndMerge(delta):
	if (lambda >= 1):
		# Explosion
		var explosionNode = explosionScene.instance()
		explosionNode.set_pos(cellDest*CARD_SIZE + Vector2(CARD_SIZE/2, CARD_SIZE/2))
		explosionNode.get_node("Particles2D").set_emitting(true)
		explosionNode.set_z(0.2)
		add_child(explosionNode)
		
		if (selectedCard.cardType == "castle"):
			playerMovesLeft -= 3
		else:
			playerMovesLeft -= 1
			
		var attackedCard = grid[cellDest]
		removeCard(attackedCard)
		var mergeRes = mergeResult[selectedCard.cardType]
		if (mergeRes == null):
			score += 200
			scoreLabel.set_text("Score " + str(score))
		if (mergeRes == "castle"):
			castles += 1
			score += 100
			scoreLabel.set_text("Score " + str(score))
		elif (mergeRes == "tower"):
			score += 50
			scoreLabel.set_text("Score " + str(score))
		
		if (mergeRes != null):
			createCard(mergeRes, cellDest, "blue")
			
		removeCard(selectedCard)
		
		currentState = "PLAYER_TURN"
		lambda = 0
			
		selectedCard = null
		cellDest = null
		
	else:	
		selectedCard.set_pos(selectedCard.currentCell.linear_interpolate(cellDest,lambda) * CARD_SIZE)
		lambda += CARD_SPEED*delta

# Can attack
func canAttack(attackerCard, attackedCard):
	return attackerCard.cardSide != attackedCard.cardSide
	
# Attack function
func moveAndAttack(delta):
	if (lambda >= 1):
		# Explosion
		var explosionNode = explosionScene.instance()
		explosionNode.set_pos(cellDest*CARD_SIZE + Vector2(CARD_SIZE/2, CARD_SIZE/2))
		explosionNode.get_node("Particles2D").set_emitting(true)
		explosionNode.set_z(0.2)
		add_child(explosionNode)
		
		if (selectedCard.cardType == "tower"):
			playerMovesLeft -= 1
			
		# Attack
		var attackedCard = grid[cellDest]
		var fightResult = firstBeatsSecondTable[selectedCard.cardType][attackedCard.cardType]
		if (fightResult == 0):	# Both die
			removeCard(selectedCard)
			removeCard(attackedCard)
		elif (fightResult == 1): # Attacker wins
			removeCard(attackedCard)
			changeCell(selectedCard, cellDest)
		elif (fightResult == 2): # Attacked wins
			print("CARD LOST")
			print(selectedCard.currentCell)
			removeCard(selectedCard)
			
		currentState = "PLAYER_TURN"
		lambda = 0
			
		selectedCard = null
		cellDest = null
		
	else:	
		selectedCard.set_pos(selectedCard.currentCell.linear_interpolate(cellDest,lambda) * CARD_SIZE)
		lambda += CARD_SPEED*delta
		
#####################################
############ SPAWN ENEMY ############
#####################################
func spawnRandomEnemy():
	
	var emptyCells = []
	var i = 0
	var j = 0
	while(j < GRID_HEIGHT):
		while(i < GRID_WIDTH):
			if (not Vector2(i,j) in grid):
				emptyCells.append(Vector2(i,j))
			i += 1
		i = 0
		j += 1
	
	if (emptyCells.size() == 0):
		return
		
	var randEmptyCell = emptyCells[rand_range(0, emptyCells.size())]
	createCard(cardTypes[rand_range(0, 3)], randEmptyCell, "red")
	
###############################
############ UTILS ############
###############################
func customClamp(val, minVal, maxVal): # both min(max) and "clamp" don't work on android
	var ret = val
	if (val < minVal):
		ret = minVal
	elif (val > maxVal):
		ret = maxVal
	return ret
	
func checkGameOver():
	var emptyCells = []
	var i = 0
	var j = 0
	while(j < GRID_HEIGHT):
		while(i < GRID_WIDTH):
			if (not Vector2(i,j) in grid):
				emptyCells.append(Vector2(i,j))
			i += 1
		i = 0
		j += 1
	
	# No space left? Game over!
	if (emptyCells.size() == 0):
		currentState = "GAME_OVER"

func loadLevel():
	# Load Level
	var f = File.new()
	var err = f.open_encrypted_with_pass("user://level.bin",File.READ,OS.get_unique_ID())
	var level = f.get_var()
	if (level == null):
		level = 1
	f.close()
	CASTLES_TO_WIN = level

func saveNewLevel():
	# New Level
	var f = File.new()
	var err = f.open_encrypted_with_pass("user://level.bin",File.WRITE,OS.get_unique_ID())
	f.store_var(CASTLES_TO_WIN + 1)
	f.close()
	
func saveScore():
	# Retrieve current high score
	var f = File.new()
	var err = f.open_encrypted_with_pass("user://highscore.bin",File.READ,OS.get_unique_ID())
	var hs = f.get_var()
	if (hs == null):
		hs = 0
	
	if (score > hs):
		err = f.open_encrypted_with_pass("user://highscore.bin",File.WRITE,OS.get_unique_ID())
		f.store_var(score)
		f.close()
		
func _on_GameOverAnim_finished():
	get_parent().get_node("Anims/AnimExit").play("Exit")

func _on_GameWonAnim_finished():
	get_parent().get_node("Anims/AnimExit").play("Exit")


func _on_AnimExit_finished():
	get_node("/root/global").goto_scene("res://main_menu.scn")
