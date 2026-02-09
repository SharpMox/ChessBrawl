extends Control

enum Phase { KING_PLACEMENT, PIECE_PLACEMENT }
enum GameState { PLACEMENT, WAVE_ACTIVE, WAVE_TRANSITION }

const GRID_COLUMNS: int = 6
const GRID_ROWS: int = 8

const COLOR_LIGHT: Color = Color(0.93, 0.93, 0.85)
const COLOR_DARK: Color = Color(0.45, 0.58, 0.33)
const COLOR_BORDER: Color = Color(0.53, 0.81, 0.98, 0.8)
const BORDER_WIDTH: int = 12
const PIECE_COLOR: Color = Color(0.1, 0.1, 0.1, 1.0)
const ENEMY_COLOR: Color = Color(0.85, 0.15, 0.15, 1.0)
const COLOR_VALID_MOVE: Color = Color(0.3, 0.8, 0.5, 0.5)
const COLOR_VALID_CAPTURE: Color = Color(0.9, 0.3, 0.3, 0.5)
const COLOR_SELECTED: Color = Color(0.5, 0.7, 1.0, 0.5)
const COLOR_ENEMY_SELECTED: Color = Color(0.9, 0.4, 0.4, 0.5)
const COLOR_PLAYER_OUTLINE: Color = Color(0.4, 0.7, 1.0, 1.0)
const COLOR_ENEMY_OUTLINE: Color = Color(1.0, 0.3, 0.3, 1.0)
const COLOR_REMOVABLE: Color = Color(1.0, 1.0, 1.0, 0.3)
const TURN_OUTLINE_WIDTH: int = 12
const TURN_OUTLINE_FADE: float = 2.4

const STARTING_POINTS: int = 3
const PLAYS_PER_TURN: int = 1
const SPAWN_CAPTURE_DELAY: float = 1.2

const ROUNDS: Array = [
	# Round 1 — 3 waves, pawns only
	{"waves": [
		{"pawn": 2},
		{"pawn": 3},
		{"pawn": 4},
	]},
	# Round 2 — 3 waves, introduce knights
	{"waves": [
		{"pawn": 3},
		{"pawn": 3, "knight": 1},
		{"pawn": 4, "knight": 1},
	]},
	# Round 3 — 3 waves, introduce bishops
	{"waves": [
		{"pawn": 3, "knight": 1},
		{"pawn": 4, "knight": 1, "bishop": 1},
		{"pawn": 4, "knight": 2, "bishop": 1},
	]},
	# Round 4 — 5 waves, growing mix
	{"waves": [
		{"pawn": 2, "knight": 1},
		{"pawn": 3, "knight": 1, "bishop": 1},
		{"pawn": 3, "knight": 2, "bishop": 1},
		{"pawn": 4, "knight": 2, "bishop": 1},
		{"pawn": 4, "knight": 2, "bishop": 2},
	]},
	# Round 5 — 5 waves, introduce rooks
	{"waves": [
		{"pawn": 3, "knight": 1, "bishop": 1},
		{"pawn": 3, "knight": 2, "bishop": 1},
		{"pawn": 4, "knight": 2, "bishop": 2},
		{"pawn": 4, "knight": 2, "bishop": 1, "rook": 1},
		{"pawn": 5, "knight": 2, "bishop": 2, "rook": 1},
	]},
	# Round 6 — 5 waves, more rooks
	{"waves": [
		{"pawn": 3, "knight": 2, "bishop": 1},
		{"pawn": 4, "knight": 2, "bishop": 2},
		{"pawn": 4, "knight": 2, "bishop": 2, "rook": 1},
		{"pawn": 5, "knight": 2, "bishop": 2, "rook": 1},
		{"pawn": 4, "knight": 3, "bishop": 2, "rook": 2},
	]},
	# Round 7 — 7 waves, introduce queen
	{"waves": [
		{"pawn": 3, "knight": 1, "bishop": 1},
		{"pawn": 4, "knight": 2, "bishop": 1},
		{"pawn": 4, "knight": 2, "bishop": 2},
		{"pawn": 4, "knight": 2, "bishop": 2, "rook": 1},
		{"pawn": 5, "knight": 2, "bishop": 2, "rook": 1},
		{"pawn": 4, "knight": 3, "bishop": 2, "rook": 1, "queen": 1},
		{"pawn": 4, "knight": 3, "bishop": 2, "rook": 2, "queen": 1},
	]},
	# Round 8 — 7 waves, tougher
	{"waves": [
		{"pawn": 3, "knight": 2, "bishop": 1},
		{"pawn": 4, "knight": 2, "bishop": 2},
		{"pawn": 4, "knight": 2, "bishop": 2, "rook": 1},
		{"pawn": 5, "knight": 3, "bishop": 2, "rook": 1},
		{"pawn": 5, "knight": 2, "bishop": 2, "rook": 1, "queen": 1},
		{"pawn": 4, "knight": 3, "bishop": 2, "rook": 2, "queen": 1},
		{"pawn": 4, "knight": 2, "bishop": 2, "rook": 2, "queen": 2},
	]},
	# Round 9 — 7 waves, heavy
	{"waves": [
		{"pawn": 4, "knight": 2, "bishop": 1, "rook": 1},
		{"pawn": 4, "knight": 2, "bishop": 2, "rook": 1},
		{"pawn": 5, "knight": 3, "bishop": 2, "rook": 1},
		{"pawn": 4, "knight": 3, "bishop": 2, "rook": 1, "queen": 1},
		{"pawn": 4, "knight": 3, "bishop": 2, "rook": 2, "queen": 1},
		{"pawn": 4, "knight": 2, "bishop": 2, "rook": 2, "queen": 2},
		{"pawn": 3, "knight": 3, "bishop": 2, "rook": 2, "queen": 2},
	]},
	# Round 10 — 9 waves, final challenge
	{"waves": [
		{"pawn": 3, "knight": 2, "bishop": 1, "rook": 1},
		{"pawn": 4, "knight": 2, "bishop": 2, "rook": 1},
		{"pawn": 5, "knight": 3, "bishop": 2, "rook": 1},
		{"pawn": 4, "knight": 3, "bishop": 2, "rook": 1, "queen": 1},
		{"pawn": 4, "knight": 3, "bishop": 2, "rook": 2, "queen": 1},
		{"pawn": 4, "knight": 2, "bishop": 2, "rook": 2, "queen": 2},
		{"pawn": 3, "knight": 3, "bishop": 2, "rook": 2, "queen": 2},
		{"pawn": 3, "knight": 2, "bishop": 2, "rook": 2, "queen": 3},
		{"pawn": 2, "knight": 2, "bishop": 2, "rook": 3, "queen": 3},
	]},
]

const PIECE_COSTS: Dictionary = {
	"king": 0,
	"pawn": 1,
	"knight": 3,
	"bishop": 3,
	"rook": 5,
	"queen": 9,
}

const PIECE_SYMBOLS: Dictionary = {
	"pawn": "♟",
	"knight": "♞",
	"bishop": "♝",
	"rook": "♜",
	"queen": "♛",
}

@onready var _grid: GridContainer = %Grid
@onready var _moves_value: Label = %MovesValue
@onready var _turn_value: Label = %TurnValue
@onready var _round_value: Label = %RoundValue
@onready var _time_value: Label = %TimeValue
@onready var _score_value: Label = %ScoreValue
@onready var _round_overlay: PanelContainer = %RoundOverlay
@onready var _round_start_button: Button = %RoundStartButton
@onready var _placement_label: Label = %PlacementLabel
@onready var _points_label: Label = %PointsLabel
@onready var _menu_button: Button = %MenuButton
@onready var _pause_overlay: ColorRect = %PauseOverlay
@onready var _resume_button: Button = %ResumeButton
@onready var _finish_wave_button: Button = %FinishWaveButton
@onready var _abandon_button: Button = %AbandonButton
@onready var _round_title: Label = %RoundTitle
@onready var _waves_subtitle: Label = %WavesSubtitle
@onready var _wave_list: VBoxContainer = %WaveList
@onready var _wave_overlay: PanelContainer = %WaveOverlay
@onready var _wave_title: Label = %WaveTitle
@onready var _wave_description: Label = %WaveDescription
@onready var _wave_start_button: Button = %WaveStartButton
@onready var _game_over_overlay: PanelContainer = %GameOverOverlay
@onready var _game_over_title: Label = %GameOverTitle
@onready var _game_over_stats: Label = %GameOverStats
@onready var _restart_button: Button = %RestartButton
@onready var _back_to_menu_button: Button = %MenuButton2
@onready var _captures_label: Label = %CapturesLabel
@onready var _captures_flow: Control = %CapturesFlow
@onready var _lost_label: Label = %LostLabel
@onready var _lost_flow: Control = %LostFlow
@onready var _skip_turn_button: Button = %SkipTurnButton
@onready var _skip_wave_button: Button = %SkipWaveButton

@onready var _piece_buttons: Dictionary = {
	"king": %KingPiece,
	"pawn": %PawnPiece,
	"knight": %KnightPiece,
	"bishop": %BishopPiece,
	"rook": %RookPiece,
	"queen": %QueenPiece,
}

var _moves: int = 0
var _turn: int = 1
var _round: int = 1
var _score: int = 0
var _elapsed_time: float = 0.0
var _timer_running: bool = false

var _cells: Array[Panel] = []
var _phase: int = Phase.KING_PLACEMENT
var _selected_piece: String = ""
var _king_placed: bool = false
var _placement_active: bool = false
var _king_symbol: String = "♔"
var _game_state: int = GameState.PLACEMENT
var _current_wave: int = 0
var _plays_left: int = 0
var _is_player_turn: bool = false
var _enemy_ai: EnemyAi = null
var _move_source_cell: Panel = null
var _valid_move_cells: Array[Panel] = []
var _dragging: bool = false
var _ghost_label: Label = null
var _ghost_current_cell: Panel = null
var _turn_outline: Panel = null
var _turn_outline_tween: Tween = null
var _turn_banner: PanelContainer = null
var _turn_banner_label: Label = null
var _turn_banner_tween: Tween = null
var _captured_pieces: Array[String] = []
var _lost_pieces: Array[String] = []
var _placed_this_round: Array[Panel] = []

func _ready() -> void:
	_enemy_ai = EnemyAi.new(self)
	_build_grid()
	_setup_king_icon()
	_setup_cost_labels()
	_setup_turn_outline()
	_update_stats()
	_show_round_overlay()

	for piece_type: String in _piece_buttons:
		_piece_buttons[piece_type].pressed.connect(_on_piece_button_pressed.bind(piece_type))

	_round_start_button.pressed.connect(_on_round_start_pressed)
	_menu_button.pressed.connect(_on_menu_button_pressed)
	_resume_button.pressed.connect(_on_resume_button_pressed)
	_finish_wave_button.pressed.connect(_on_finish_wave_pressed)
	_abandon_button.pressed.connect(_on_abandon_button_pressed)
	_wave_start_button.pressed.connect(_on_wave_start_pressed)
	_restart_button.pressed.connect(_on_restart_pressed)
	_back_to_menu_button.pressed.connect(_on_back_to_menu_pressed)
	_skip_turn_button.pressed.connect(_on_skip_turn_pressed)
	_skip_wave_button.pressed.connect(_on_skip_wave_pressed)


func _process(delta: float) -> void:
	if _timer_running and _is_player_turn:
		_elapsed_time += delta
		_time_value.text = _format_time(_elapsed_time)

	if _game_state == GameState.WAVE_ACTIVE and not _is_player_turn and _king_placed:
		_enemy_ai.tick(delta)

	if _move_source_cell != null:
		_update_ghost_position(get_global_mouse_position())


# --- King icon ---

func _setup_king_icon() -> void:
	_king_symbol = GameData.get_king_symbol()
	_piece_buttons["king"].text = _king_symbol


func _setup_cost_labels() -> void:
	for piece_type: String in _piece_buttons:
		var btn: Button = _piece_buttons[piece_type]
		var slot: VBoxContainer = btn.get_parent() as VBoxContainer
		var cost_label: Label = slot.get_child(1) as Label
		var cost: int = PIECE_COSTS[piece_type]
		if cost == 1:
			cost_label.text = "%d pt" % cost
		else:
			cost_label.text = "%d pts" % cost


func _get_piece_symbol(piece_type: String) -> String:
	if piece_type == "king":
		return _king_symbol
	return PIECE_SYMBOLS[piece_type]


# --- Grid ---

func _build_grid() -> void:
	_grid.columns = GRID_COLUMNS

	for row: int in range(GRID_ROWS):
		for col: int in range(GRID_COLUMNS):
			var cell: Panel = Panel.new()
			cell.custom_minimum_size = Vector2(0, 0)
			cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			cell.size_flags_vertical = Control.SIZE_EXPAND_FILL

			var style: StyleBoxFlat = StyleBoxFlat.new()
			if (row + col) % 2 == 0:
				style.bg_color = COLOR_LIGHT
			else:
				style.bg_color = COLOR_DARK
			cell.add_theme_stylebox_override("panel", style)

			cell.set_meta("row", row)
			cell.set_meta("col", col)
			cell.set_meta("has_piece", false)
			cell.set_meta("piece_type", "")
			cell.set_meta("is_enemy", false)
			cell.gui_input.connect(_on_cell_input.bind(cell))

			_grid.add_child(cell)
			_cells.append(cell)


func _get_cell(row: int, col: int) -> Panel:
	return _cells[row * GRID_COLUMNS + col]


func _reset_cell_color(cell: Panel) -> void:
	var row: int = cell.get_meta("row")
	var col: int = cell.get_meta("col")
	var style: StyleBoxFlat = StyleBoxFlat.new()
	if (row + col) % 2 == 0:
		style.bg_color = COLOR_LIGHT
	else:
		style.bg_color = COLOR_DARK
	cell.add_theme_stylebox_override("panel", style)


# --- Round overlay ---

func _show_round_overlay() -> void:
	_game_state = GameState.PLACEMENT
	_current_wave = 0
	_wave_overlay.visible = false
	_round_start_button.disabled = true
	if _round == 1:
		_score += GameData.get_king_points()

	_king_placed = _has_king_on_board()
	if _king_placed:
		_phase = Phase.PIECE_PLACEMENT
		_selected_piece = ""
		_placement_active = false
	else:
		_phase = Phase.KING_PLACEMENT
		_selected_piece = "king"
		_placement_active = true

	_placed_this_round.clear()
	_populate_round_overlay()
	_spawn_enemies_deferred.call_deferred()
	_set_piece_slots_visible(true)
	_update_placement_ui()
	_highlight_placement_rows(true)


func _has_king_on_board() -> bool:
	for cell: Panel in _cells:
		if cell.get_meta("has_piece") and cell.get_meta("piece_type") == "king" and not cell.get_meta("is_enemy"):
			return true
	return false


func _spawn_enemies_deferred() -> void:
	var had_captures: bool = _spawn_enemies(_get_wave_data())
	if had_captures:
		_round_overlay.visible = false
		var tween: Tween = create_tween()
		tween.tween_interval(SPAWN_CAPTURE_DELAY)
		tween.tween_callback(func() -> void: _round_overlay.visible = true)
	else:
		_round_overlay.visible = true


func _populate_round_overlay() -> void:
	var round_data: Dictionary = _get_round_data()
	var waves: Array = round_data["waves"]
	_round_title.text = "Round %d" % _round
	_waves_subtitle.text = "%d Waves" % waves.size()

	for child: Node in _wave_list.get_children():
		child.queue_free()

	for i: int in range(waves.size()):
		var wave: Dictionary = waves[i]
		var label: Label = Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 14)
		label.text = "Wave %d \u2014 %s" % [i + 1, _format_wave_description(wave)]
		_wave_list.add_child(label)


func _format_wave_description(wave: Dictionary) -> String:
	var parts: Array[String] = []
	for piece_type: String in wave:
		var count: int = wave[piece_type]
		var symbol: String = PIECE_SYMBOLS.get(piece_type, piece_type)
		var piece_name: String = piece_type.capitalize()
		if count > 1:
			piece_name += "s"
		parts.append("%d %s %s" % [count, symbol, piece_name])
	return ", ".join(parts)


func _get_round_data() -> Dictionary:
	var index: int = mini(_round - 1, ROUNDS.size() - 1)
	return ROUNDS[index]


func _get_wave_data() -> Dictionary:
	var round_data: Dictionary = _get_round_data()
	var waves: Array = round_data["waves"]
	return waves[_current_wave]


func _update_placement_ui() -> void:
	_points_label.text = "%d pts remaining" % _score
	_update_stats()

	if _phase == Phase.KING_PLACEMENT:
		_placement_label.text = "Place your King"
		for piece_type: String in _piece_buttons:
			_piece_buttons[piece_type].disabled = (piece_type != "king")
		_highlight_piece_button("king")
	else:
		var has_space: bool = _has_empty_placement_cell()
		if _score <= 0 or not has_space:
			_placement_label.modulate.a = 0.0
		else:
			_placement_label.modulate.a = 1.0
			_placement_label.text = "Choose pieces to place"
		for piece_type: String in _piece_buttons:
			if piece_type == "king":
				_piece_buttons[piece_type].disabled = true
			else:
				_piece_buttons[piece_type].disabled = PIECE_COSTS[piece_type] > _score or not has_space
		_highlight_piece_button(_selected_piece)

	_round_start_button.disabled = not _king_placed
	_highlight_removable_cells()


func _set_piece_slots_visible(slots_visible: bool) -> void:
	for type: String in _piece_buttons:
		var btn: Button = _piece_buttons[type]
		var slot: VBoxContainer = btn.get_parent() as VBoxContainer
		slot.visible = slots_visible
	var skip_slot: VBoxContainer = _skip_turn_button.get_parent() as VBoxContainer
	skip_slot.visible = not slots_visible
	var skip_wave_slot: VBoxContainer = _skip_wave_button.get_parent() as VBoxContainer
	skip_wave_slot.visible = not slots_visible


func _highlight_piece_button(piece_type: String) -> void:
	for type: String in _piece_buttons:
		var btn: Button = _piece_buttons[type]
		btn.remove_theme_stylebox_override("normal")
		btn.remove_theme_color_override("font_color")

	if piece_type != "":
		var btn: Button = _piece_buttons[piece_type]
		if not btn.disabled:
			var style: StyleBoxFlat = StyleBoxFlat.new()
			style.bg_color = COLOR_BORDER
			btn.add_theme_stylebox_override("normal", style)
			btn.add_theme_color_override("font_color", PIECE_COLOR)


func _highlight_removable_cells() -> void:
	for cell: Panel in _placed_this_round:
		if cell.get_meta("piece_type") == "king" and _round > 1:
			continue
		var row: int = cell.get_meta("row")
		var col: int = cell.get_meta("col")
		var style: StyleBoxFlat = StyleBoxFlat.new()
		if (row + col) % 2 == 0:
			style.bg_color = COLOR_LIGHT.blend(COLOR_REMOVABLE)
		else:
			style.bg_color = COLOR_DARK.blend(COLOR_REMOVABLE)
		cell.add_theme_stylebox_override("panel", style)


func _has_empty_placement_cell() -> bool:
	for row: int in range(GRID_ROWS - 2, GRID_ROWS):
		for col: int in range(GRID_COLUMNS):
			if not _get_cell(row, col).get_meta("has_piece"):
				return true
	return false


# --- Piece placement ---

func _on_piece_button_pressed(piece_type: String) -> void:
	if _phase == Phase.KING_PLACEMENT and piece_type != "king":
		return
	if piece_type != "king" and PIECE_COSTS[piece_type] > _score:
		return

	_selected_piece = piece_type
	_placement_active = true
	_highlight_piece_button(piece_type)
	_highlight_placement_rows(true)


func _highlight_placement_rows(active: bool) -> void:
	for row: int in range(GRID_ROWS - 2, GRID_ROWS):
		for col: int in range(GRID_COLUMNS):
			var cell: Panel = _get_cell(row, col)
			var style: StyleBoxFlat = StyleBoxFlat.new()

			if (row + col) % 2 == 0:
				style.bg_color = COLOR_LIGHT
			else:
				style.bg_color = COLOR_DARK

			if active:
				style.border_color = COLOR_BORDER
				if row == GRID_ROWS - 2:
					style.border_width_top = BORDER_WIDTH
				if row == GRID_ROWS - 1:
					style.border_width_bottom = BORDER_WIDTH
				if col == 0:
					style.border_width_left = BORDER_WIDTH
				if col == GRID_COLUMNS - 1:
					style.border_width_right = BORDER_WIDTH
				style.draw_center = true

			cell.add_theme_stylebox_override("panel", style)


func _on_cell_input(event: InputEvent, cell: Panel) -> void:
	if _game_state == GameState.WAVE_ACTIVE:
		_handle_wave_input(event, cell)
		return

	if _game_state == GameState.PLACEMENT:
		_handle_placement_input(event, cell)


func _handle_placement_input(event: InputEvent, cell: Panel) -> void:
	if not event is InputEventMouseButton:
		return

	var mb: InputEventMouseButton = event as InputEventMouseButton
	if not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return

	var row: int = cell.get_meta("row")
	if row < GRID_ROWS - 2:
		return

	# Click on existing piece to remove it (only pieces placed this round)
	if cell.get_meta("has_piece"):
		if not _timer_running and cell in _placed_this_round:
			if cell.get_meta("piece_type") == "king" and _round > 1:
				return
			_remove_piece_from_cell(cell)
		return

	# Place a new piece
	if not _placement_active:
		return
	if _selected_piece == "":
		return

	_place_piece_on_cell(cell)


func _place_piece_on_cell(cell: Panel) -> void:
	var cost: int = PIECE_COSTS[_selected_piece]
	if cost > _score:
		return

	cell.set_meta("has_piece", true)
	cell.set_meta("piece_type", _selected_piece)

	var label: Label = Label.new()
	label.name = "PieceLabel"
	label.text = _get_piece_symbol(_selected_piece)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var font_size: int = floori(cell.size.y * 0.8)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", PIECE_COLOR)
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	cell.add_child(label)

	_score -= cost
	_placed_this_round.append(cell)

	if _selected_piece == "king":
		_king_placed = true
		_phase = Phase.PIECE_PLACEMENT
		_selected_piece = ""
		_placement_active = false

	_update_placement_ui()
	_highlight_placement_rows(true)


func _remove_piece_from_cell(cell: Panel) -> void:
	var piece_type: String = cell.get_meta("piece_type")

	_score += PIECE_COSTS[piece_type]

	var piece_label: Label = cell.get_node_or_null("PieceLabel") as Label
	if piece_label:
		piece_label.queue_free()

	cell.set_meta("has_piece", false)
	cell.set_meta("piece_type", "")
	_reset_cell_color(cell)
	_placed_this_round.erase(cell)

	if piece_type == "king":
		_king_placed = false
		_phase = Phase.KING_PLACEMENT
		_selected_piece = "king"
		_placement_active = true

	_update_placement_ui()
	_highlight_placement_rows(true)


# --- Enemy spawning ---

func _spawn_enemies(wave_data: Dictionary) -> bool:
	var empty_cells: Array[Panel] = []
	var player_cells: Array[Panel] = []
	for row: int in range(0, 2):
		for col: int in range(GRID_COLUMNS):
			var cell: Panel = _get_cell(row, col)
			if not cell.get_meta("has_piece"):
				empty_cells.append(cell)
			elif cell.get_meta("is_enemy"):
				continue
			else:
				player_cells.append(cell)

	empty_cells.shuffle()
	player_cells.shuffle()

	var available_cells: Array[Panel] = []
	available_cells.append_array(empty_cells)
	available_cells.append_array(player_cells)

	var cell_index: int = 0
	var had_captures: bool = false

	for piece_type: String in wave_data:
		var count: int = wave_data[piece_type]
		for i: int in range(count):
			if cell_index >= available_cells.size():
				return had_captures
			var cell: Panel = available_cells[cell_index]
			if cell.get_meta("has_piece") and not cell.get_meta("is_enemy"):
				had_captures = true
				_enemy_capture_player_piece(cell, piece_type)
			else:
				_place_enemy_on_cell(cell, piece_type)
			cell_index += 1

	return had_captures


func _enemy_capture_player_piece(cell: Panel, enemy_type: String) -> void:
	var lost_type: String = cell.get_meta("piece_type")

	var player_label: Label = cell.get_node_or_null("PieceLabel") as Label
	if player_label:
		cell.remove_child(player_label)
		player_label.queue_free()

	cell.set_meta("has_piece", true)
	cell.set_meta("piece_type", enemy_type)
	cell.set_meta("is_enemy", true)

	var label: Label = Label.new()
	label.name = "PieceLabel"
	label.text = PIECE_SYMBOLS[enemy_type]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var font_size: int = floori(cell.size.y * 0.8)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", ENEMY_COLOR)
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	cell.add_child(label)
	_shake_piece_long(label)
	_flash_cell_red(cell)
	_spawn_floating_loss(cell, lost_type)
	_lost_pieces.append(lost_type)

	if lost_type == "king":
		_king_placed = false
		_cancel_turn_indicators()
		var tween: Tween = create_tween()
		tween.tween_interval(SPAWN_CAPTURE_DELAY)
		tween.tween_callback(_show_game_over)


func _place_enemy_on_cell(cell: Panel, piece_type: String) -> void:
	cell.set_meta("has_piece", true)
	cell.set_meta("piece_type", piece_type)
	cell.set_meta("is_enemy", true)

	var label: Label = Label.new()
	label.name = "PieceLabel"
	label.text = PIECE_SYMBOLS[piece_type]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var font_size: int = floori(cell.size.y * 0.8)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", ENEMY_COLOR)
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	cell.add_child(label)


func _has_enemies() -> bool:
	for cell: Panel in _cells:
		if cell.get_meta("is_enemy"):
			return true
	return false


func _clear_enemies() -> void:
	for cell: Panel in _cells:
		if cell.get_meta("is_enemy"):
			var piece_label: Label = cell.get_node_or_null("PieceLabel") as Label
			if piece_label:
				cell.remove_child(piece_label)
				piece_label.queue_free()
			cell.set_meta("has_piece", false)
			cell.set_meta("piece_type", "")
			cell.set_meta("is_enemy", false)


# --- Round / Wave flow ---

func _on_round_start_pressed() -> void:
	_round_overlay.visible = false
	_game_state = GameState.WAVE_ACTIVE
	_timer_running = true
	_placement_active = false
	_selected_piece = ""
	_highlight_placement_rows(false)
	_set_piece_slots_visible(false)
	_highlight_piece_button("")
	_start_player_turn()


func _on_finish_wave_pressed() -> void:
	_pause_overlay.visible = false
	_finish_current_wave()


func _finish_current_wave() -> void:
	_timer_running = false
	_clear_move_selection()
	_is_player_turn = false
	_plays_left = 0
	_clear_enemies()

	var round_data: Dictionary = _get_round_data()
	var waves: Array = round_data["waves"]

	if _current_wave < waves.size() - 1:
		# More waves in this round — show wave transition overlay
		_current_wave += 1
		_turn += 1
		_game_state = GameState.WAVE_TRANSITION
		var wave_data: Dictionary = _get_wave_data()
		_wave_title.text = "Wave %d" % (_current_wave + 1)
		_wave_description.text = _format_wave_description(wave_data)
		var had_captures: bool = _spawn_enemies(wave_data)
		if had_captures:
			var tween: Tween = create_tween()
			tween.tween_interval(SPAWN_CAPTURE_DELAY)
			tween.tween_callback(func() -> void: _wave_overlay.visible = true)
		else:
			_wave_overlay.visible = true
		_update_stats()
	else:
		# Last wave done
		if _round >= ROUNDS.size():
			_show_victory()
		else:
			_round += 1
			_turn = 1
			_show_round_overlay()


func _on_wave_start_pressed() -> void:
	_wave_overlay.visible = false
	_game_state = GameState.WAVE_ACTIVE
	_timer_running = true
	_start_player_turn()


func _clear_player_pieces() -> void:
	for cell: Panel in _cells:
		if cell.get_meta("has_piece") and not cell.get_meta("is_enemy"):
			var piece_label: Label = cell.get_node_or_null("PieceLabel") as Label
			if piece_label:
				piece_label.queue_free()
			cell.set_meta("has_piece", false)
			cell.set_meta("piece_type", "")
			_reset_cell_color(cell)


# --- Pause menu ---

func _on_menu_button_pressed() -> void:
	_pause_overlay.visible = true
	_timer_running = false
	_finish_wave_button.visible = _game_state == GameState.WAVE_ACTIVE


func _on_resume_button_pressed() -> void:
	_pause_overlay.visible = false
	if _game_state == GameState.WAVE_ACTIVE:
		_timer_running = true


func _on_abandon_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/king_select.tscn")


func _on_skip_turn_pressed() -> void:
	if _is_player_turn and _game_state == GameState.WAVE_ACTIVE:
		_end_player_turn()


func _on_skip_wave_pressed() -> void:
	if _game_state == GameState.WAVE_ACTIVE:
		# Award score for all remaining enemies
		for cell: Panel in _cells:
			if cell.get_meta("is_enemy"):
				var enemy_type: String = cell.get_meta("piece_type")
				_captured_pieces.append(enemy_type)
				_score += PIECE_COSTS.get(enemy_type, 0)
		_finish_current_wave()


# --- Game over ---

const COLOR_VICTORY: Color = Color(0.3, 0.5, 1.0, 1.0)
const COLOR_DEFEAT: Color = Color(1.0, 0.3, 0.3, 1.0)


func _show_victory() -> void:
	_game_over_title.text = "Victory!"
	_game_over_title.add_theme_color_override("font_color", COLOR_VICTORY)
	_show_end_screen()


func _show_game_over() -> void:
	_game_over_title.text = "King Defeated!"
	_game_over_title.add_theme_color_override("font_color", COLOR_DEFEAT)
	_show_end_screen()


func _show_end_screen() -> void:
	_timer_running = false
	_clear_move_selection()
	_is_player_turn = false
	_plays_left = 0
	_skip_turn_button.disabled = true
	_skip_wave_button.disabled = true
	_round_overlay.visible = false
	_wave_overlay.visible = false
	_pause_overlay.visible = false

	_cancel_turn_indicators()
	_game_over_stats.text = "Round %d — Wave %d\n%d moves in %s" % [
		_round, _current_wave + 1, _moves, _format_time(_elapsed_time)
	]
	_captures_label.text = "Pieces captured: %d" % _captured_pieces.size()
	_lost_label.text = "Pieces lost: %d" % _lost_pieces.size()
	# Clear previous capture / loss display
	for child: Node in _captures_flow.get_children():
		child.queue_free()
	for child: Node in _lost_flow.get_children():
		child.queue_free()
	_game_over_overlay.visible = true
	# Wait one frame so containers get their proper size from layout
	await get_tree().process_frame
	_animate_captured_pieces()
	_animate_lost_pieces()


func _fan_pieces(pieces: Array[String], container: Control, color: Color, use_enemy_symbols: bool) -> void:
	if pieces.is_empty():
		return

	const ICON: float = 108.0
	const FONT: int = 84
	const ROW_GAP: float = 4.0

	var count: int = pieces.size()
	var num_rows: int = 3
	if count <= 4:
		num_rows = 1
	elif count <= 8:
		num_rows = 2
	var per_row: int = ceili(float(count) / float(num_rows))
	var container_w: float = container.size.x

	# Horizontal step: overlap if needed to fit per_row icons in container width
	var step_x: float = ICON
	if per_row > 1:
		step_x = minf(ICON, (container_w - ICON) / float(per_row - 1))
	var row_h: float = ICON + ROW_GAP

	var max_duration: float = 10.0
	var delay_per: float = minf(max_duration / float(count), 0.3)

	# Pre-calculate positions for all pieces
	var positions: Array[Vector2] = []
	for i: int in range(count):
		@warning_ignore("integer_division")
		var row: int = i / per_row
		var col: int = i % per_row
		# Items in this row (last row may have fewer)
		var items_this_row: int = mini(per_row, count - row * per_row)
		var row_width: float = ICON + step_x * float(items_this_row - 1)
		var offset_x: float = (container_w - row_width) * 0.5
		positions.append(Vector2(offset_x + col * step_x, row * row_h))

	var tween: Tween = create_tween()
	for i: int in range(count):
		var piece_type: String = pieces[i]
		var symbol: String
		if use_enemy_symbols:
			symbol = PIECE_SYMBOLS.get(piece_type, piece_type)
		else:
			symbol = _get_piece_symbol(piece_type)
		var pos: Vector2 = positions[i]
		tween.tween_callback(func() -> void:
			var lbl: Label = Label.new()
			lbl.text = symbol
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			lbl.add_theme_font_size_override("font_size", FONT)
			lbl.add_theme_color_override("font_color", color)
			lbl.size = Vector2(ICON, ICON)
			lbl.position = pos
			lbl.modulate.a = 0.0
			container.add_child(lbl)
			var fade_in: Tween = create_tween()
			fade_in.tween_property(lbl, "modulate:a", 1.0, 0.15)
		)
		if i < count - 1:
			tween.tween_interval(delay_per)


func _animate_captured_pieces() -> void:
	_fan_pieces(_captured_pieces, _captures_flow, ENEMY_COLOR, true)


func _animate_lost_pieces() -> void:
	_fan_pieces(_lost_pieces, _lost_flow, Color(0.45, 0.7, 0.95, 1.0), false)


func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()


func _on_back_to_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu.tscn")


# --- Stats ---

func _update_stats() -> void:
	_moves_value.text = str(_moves)
	_turn_value.text = str(_current_wave + 1)
	_round_value.text = str(_round)
	_score_value.text = str(_score)
	_time_value.text = _format_time(_elapsed_time)


func _format_time(seconds: float) -> String:
	var mins: int = floori(seconds / 60.0)
	var secs: int = floori(seconds) % 60
	return "%02d:%02d" % [mins, secs]


# --- Turn management ---

func _cancel_turn_indicators() -> void:
	if _turn_outline_tween:
		_turn_outline_tween.kill()
		_turn_outline_tween = null
	_turn_outline.modulate.a = 0.0
	if _turn_banner_tween:
		_turn_banner_tween.kill()
		_turn_banner_tween = null
	_turn_banner.modulate.a = 0.0


func _start_player_turn() -> void:
	_is_player_turn = true
	_plays_left = PLAYS_PER_TURN
	_skip_turn_button.disabled = false
	_skip_wave_button.disabled = false
	_flash_turn_outline(COLOR_PLAYER_OUTLINE)
	_flash_turn_banner("Your Turn", COLOR_PLAYER_OUTLINE)
	_update_stats()


func _end_player_turn() -> void:
	_is_player_turn = false
	_skip_turn_button.disabled = true
	_skip_wave_button.disabled = true
	_clear_move_selection()
	_enemy_ai.reset()
	_flash_turn_outline(COLOR_ENEMY_OUTLINE)
	_flash_turn_banner("Enemy Turn", COLOR_ENEMY_OUTLINE)
	_update_stats()


func _setup_turn_outline() -> void:
	_turn_outline = Panel.new()
	_turn_outline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_turn_outline.modulate.a = 0.0
	add_child(_turn_outline)

	_turn_banner = PanelContainer.new()
	_turn_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_turn_banner.modulate.a = 0.0

	_turn_banner_label = Label.new()
	_turn_banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_turn_banner_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_turn_banner_label.add_theme_font_size_override("font_size", 22)
	_turn_banner_label.add_theme_color_override("font_color", Color.WHITE)
	_turn_banner_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_turn_banner.add_child(_turn_banner_label)

	add_child(_turn_banner)


func _flash_turn_outline(color: Color) -> void:
	_turn_outline.position = _grid.global_position
	_turn_outline.size = _grid.size

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.draw_center = false
	style.border_color = color
	style.set_border_width_all(TURN_OUTLINE_WIDTH)
	_turn_outline.add_theme_stylebox_override("panel", style)

	_turn_outline.modulate.a = 1.0
	if _turn_outline_tween:
		_turn_outline_tween.kill()
	_turn_outline_tween = create_tween()
	_turn_outline_tween.tween_property(_turn_outline, "modulate:a", 0.0, TURN_OUTLINE_FADE)


func _flash_turn_banner(text: String, color: Color) -> void:
	_turn_banner_label.text = text

	var bg_color: Color = Color(color.r, color.g, color.b, 0.85)
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.set_corner_radius_all(6)
	style.content_margin_left = 24.0
	style.content_margin_right = 24.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	_turn_banner.add_theme_stylebox_override("panel", style)

	# Center banner horizontally on the grid, near the top
	_turn_banner.reset_size()
	var grid_rect: Rect2 = _grid.get_global_rect()
	_turn_banner.position.x = grid_rect.position.x + (grid_rect.size.x - _turn_banner.size.x) * 0.5
	_turn_banner.position.y = grid_rect.position.y + grid_rect.size.y * 0.35

	_turn_banner.modulate.a = 1.0
	if _turn_banner_tween:
		_turn_banner_tween.kill()
	_turn_banner_tween = create_tween()
	_turn_banner_tween.tween_interval(0.6)
	_turn_banner_tween.tween_property(_turn_banner, "modulate:a", 0.0, 0.8)


# --- Chess move validation ---

func _get_valid_moves(row: int, col: int, piece_type: String) -> Array[Vector2i]:
	match piece_type:
		"pawn":
			return _get_pawn_moves(row, col)
		"knight":
			return _get_knight_moves(row, col)
		"bishop":
			return _get_bishop_moves(row, col)
		"rook":
			return _get_rook_moves(row, col)
		"queen":
			var moves: Array[Vector2i] = _get_bishop_moves(row, col)
			moves.append_array(_get_rook_moves(row, col))
			return moves
		"king":
			return _get_king_moves(row, col)
	return []


func _is_in_bounds(row: int, col: int) -> bool:
	return row >= 0 and row < GRID_ROWS and col >= 0 and col < GRID_COLUMNS


func _is_friendly_piece(row: int, col: int) -> bool:
	var cell: Panel = _get_cell(row, col)
	return cell.get_meta("has_piece") and not cell.get_meta("is_enemy")


func _is_enemy_piece(row: int, col: int) -> bool:
	var cell: Panel = _get_cell(row, col)
	return cell.get_meta("has_piece") and cell.get_meta("is_enemy")


func _get_pawn_moves(row: int, col: int) -> Array[Vector2i]:
	var moves: Array[Vector2i] = []
	if _is_in_bounds(row - 1, col) and not _get_cell(row - 1, col).get_meta("has_piece"):
		moves.append(Vector2i(row - 1, col))
	for dc: int in [-1, 1]:
		if _is_in_bounds(row - 1, col + dc) and _is_enemy_piece(row - 1, col + dc):
			moves.append(Vector2i(row - 1, col + dc))
	return moves


func _get_knight_moves(row: int, col: int) -> Array[Vector2i]:
	var moves: Array[Vector2i] = []
	var offsets: Array[Vector2i] = [
		Vector2i(-2, -1), Vector2i(-2, 1), Vector2i(-1, -2), Vector2i(-1, 2),
		Vector2i(1, -2), Vector2i(1, 2), Vector2i(2, -1), Vector2i(2, 1),
	]
	for offset: Vector2i in offsets:
		var r: int = row + offset.x
		var c: int = col + offset.y
		if _is_in_bounds(r, c) and not _is_friendly_piece(r, c):
			moves.append(Vector2i(r, c))
	return moves


func _get_sliding_moves(row: int, col: int, directions: Array[Vector2i]) -> Array[Vector2i]:
	var moves: Array[Vector2i] = []
	for dir: Vector2i in directions:
		var r: int = row + dir.x
		var c: int = col + dir.y
		while _is_in_bounds(r, c):
			if _is_friendly_piece(r, c):
				break
			moves.append(Vector2i(r, c))
			if _is_enemy_piece(r, c):
				break
			r += dir.x
			c += dir.y
	return moves


func _get_bishop_moves(row: int, col: int) -> Array[Vector2i]:
	var dirs: Array[Vector2i] = [Vector2i(-1, -1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(1, 1)]
	return _get_sliding_moves(row, col, dirs)


func _get_rook_moves(row: int, col: int) -> Array[Vector2i]:
	var dirs: Array[Vector2i] = [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]
	return _get_sliding_moves(row, col, dirs)


func _get_king_moves(row: int, col: int) -> Array[Vector2i]:
	var moves: Array[Vector2i] = []
	for dr: int in [-1, 0, 1]:
		for dc: int in [-1, 0, 1]:
			if dr == 0 and dc == 0:
				continue
			var r: int = row + dr
			var c: int = col + dc
			if _is_in_bounds(r, c) and not _is_friendly_piece(r, c):
				moves.append(Vector2i(r, c))
	return moves


# --- Piece movement ---

func _handle_wave_input(event: InputEvent, cell: Panel) -> void:
	if not event is InputEventMouseButton:
		return

	var mb: InputEventMouseButton = event as InputEventMouseButton
	if mb.button_index != MOUSE_BUTTON_LEFT:
		return

	if mb.pressed:
		_on_wave_mouse_down(cell, mb.global_position)
	else:
		_on_wave_mouse_up(cell, mb.global_position)


func _on_wave_mouse_down(cell: Panel, _global_pos: Vector2) -> void:
	if _move_source_cell != null and not _dragging:
		# Click mode: piece already selected
		if cell == _move_source_cell:
			_clear_move_selection()
			return
		if cell in _valid_move_cells:
			_execute_move(cell)
			return
		_clear_move_selection()

	if not _is_player_turn or _plays_left <= 0:
		return

	# Try to select a new piece
	if cell.get_meta("has_piece") and not cell.get_meta("is_enemy"):
		_select_piece_for_move(cell)
		_dragging = true


func _on_wave_mouse_up(_cell: Panel, global_pos: Vector2) -> void:
	if not _dragging:
		return
	_dragging = false
	_hide_ghost()

	var target: Panel = _get_cell_at_position(global_pos)
	if target == _move_source_cell:
		# Released on same cell = click, keep selected
		return
	if target != null and target in _valid_move_cells:
		_execute_move(target)
	else:
		_clear_move_selection()


func _select_piece_for_move(cell: Panel) -> void:
	_clear_move_selection()
	_move_source_cell = cell

	var row: int = cell.get_meta("row")
	var col: int = cell.get_meta("col")
	var piece_type: String = cell.get_meta("piece_type")

	var moves: Array[Vector2i] = _get_valid_moves(row, col, piece_type)
	for move: Vector2i in moves:
		_valid_move_cells.append(_get_cell(move.x, move.y))

	_highlight_source_cell()
	_highlight_valid_moves()


func _clear_move_selection() -> void:
	_hide_ghost()
	_clear_valid_move_highlights()
	if _move_source_cell != null:
		_reset_cell_color(_move_source_cell)
		_move_source_cell = null
	_dragging = false


func _execute_move(target_cell: Panel) -> void:
	if _move_source_cell == null:
		return

	var piece_type: String = _move_source_cell.get_meta("piece_type")
	var source_cell: Panel = _move_source_cell

	_clear_move_selection()

	# Remove piece from source
	var source_label: Label = source_cell.get_node_or_null("PieceLabel") as Label
	if source_label:
		source_cell.remove_child(source_label)
		source_label.queue_free()
	source_cell.set_meta("has_piece", false)
	source_cell.set_meta("piece_type", "")

	# Remove enemy from target if capturing
	var captured: bool = target_cell.get_meta("has_piece") and target_cell.get_meta("is_enemy")
	var captured_type: String = ""
	if captured:
		captured_type = target_cell.get_meta("piece_type")
		var enemy_label: Label = target_cell.get_node_or_null("PieceLabel") as Label
		if enemy_label:
			target_cell.remove_child(enemy_label)
			enemy_label.queue_free()
		target_cell.set_meta("is_enemy", false)

	# Place piece on target
	target_cell.set_meta("has_piece", true)
	target_cell.set_meta("piece_type", piece_type)

	var label: Label = Label.new()
	label.name = "PieceLabel"
	label.text = _get_piece_symbol(piece_type)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var font_size: int = floori(target_cell.size.y * 0.8)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", PIECE_COLOR)
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	target_cell.add_child(label)

	# Capture rewards: score gain + floating label + shake
	if captured and captured_type != "":
		_captured_pieces.append(captured_type)
		var points: int = PIECE_COSTS.get(captured_type, 0)
		if points > 0:
			_score += points
			_spawn_floating_score(target_cell, points)
		_shake_piece(label)

	# Pawn promotion: player pawn reaches row 0
	if piece_type == "pawn" and target_cell.get_meta("row") == 0:
		_promote_pawn(target_cell, false)

	_moves += 1
	_plays_left -= 1
	_update_stats()

	if captured and not _has_enemies():
		_finish_current_wave()
		return

	if _plays_left <= 0:
		_end_player_turn()


func _highlight_source_cell() -> void:
	if _move_source_cell == null:
		return
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = COLOR_SELECTED
	_move_source_cell.add_theme_stylebox_override("panel", style)


func _highlight_valid_moves() -> void:
	for cell: Panel in _valid_move_cells:
		var style: StyleBoxFlat = StyleBoxFlat.new()
		if cell.get_meta("has_piece") and cell.get_meta("is_enemy"):
			style.bg_color = COLOR_VALID_CAPTURE
		else:
			style.bg_color = COLOR_VALID_MOVE
		cell.add_theme_stylebox_override("panel", style)


func _clear_valid_move_highlights() -> void:
	for cell: Panel in _valid_move_cells:
		_reset_cell_color(cell)
	_valid_move_cells.clear()


func _get_cell_at_position(global_pos: Vector2) -> Panel:
	for cell: Panel in _cells:
		if cell.get_global_rect().has_point(global_pos):
			return cell
	return null


func _update_ghost_position(global_pos: Vector2) -> void:
	if _valid_move_cells.is_empty():
		_hide_ghost()
		return

	var closest_cell: Panel = null
	var closest_dist: float = INF
	for cell: Panel in _valid_move_cells:
		var cell_center: Vector2 = cell.global_position + cell.size * 0.5
		var dist: float = global_pos.distance_to(cell_center)
		if dist < closest_dist:
			closest_dist = dist
			closest_cell = cell

	if closest_cell != null:
		_show_ghost_on_cell(closest_cell)
	else:
		_hide_ghost()


func _show_ghost_on_cell(cell: Panel) -> void:
	if _ghost_current_cell == cell:
		return

	_hide_ghost()
	_ghost_current_cell = cell

	if _ghost_label == null:
		_ghost_label = Label.new()
		_ghost_label.name = "GhostPiece"
		_ghost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_ghost_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_ghost_label.modulate.a = 0.4
		_ghost_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if _move_source_cell != null:
		_ghost_label.text = _get_piece_symbol(_move_source_cell.get_meta("piece_type"))
	var font_size: int = floori(cell.size.y * 0.8)
	_ghost_label.add_theme_font_size_override("font_size", font_size)
	_ghost_label.add_theme_color_override("font_color", PIECE_COLOR)
	_ghost_label.set_anchors_preset(Control.PRESET_FULL_RECT)

	cell.add_child(_ghost_label)
	_ghost_label.visible = true


func _hide_ghost() -> void:
	if _ghost_label != null and _ghost_label.get_parent() != null:
		_ghost_label.get_parent().remove_child(_ghost_label)
	_ghost_current_cell = null


# --- Pawn promotion ---

func _promote_pawn(cell: Panel, is_enemy: bool) -> void:
	var new_type: String = ["knight", "rook"][randi() % 2]

	# Find a random empty cell in the owner's starting zone
	var start_row: int = GRID_ROWS - 2 if not is_enemy else 0
	var end_row: int = GRID_ROWS if not is_enemy else 2
	var empty_cells: Array[Panel] = []
	for row: int in range(start_row, end_row):
		for col: int in range(GRID_COLUMNS):
			var c: Panel = _get_cell(row, col)
			if not c.get_meta("has_piece"):
				empty_cells.append(c)

	if empty_cells.is_empty():
		# No room — promote in place
		_set_piece_on_cell(cell, new_type, is_enemy)
		return

	# Clear the pawn from its current cell
	var old_label: Label = cell.get_node_or_null("PieceLabel") as Label
	if old_label:
		cell.remove_child(old_label)
		old_label.queue_free()
	cell.set_meta("has_piece", false)
	cell.set_meta("piece_type", "")
	cell.set_meta("is_enemy", false)
	_reset_cell_color(cell)

	# Place promoted piece on random empty cell in starting zone
	var target: Panel = empty_cells[randi() % empty_cells.size()]
	_set_piece_on_cell(target, new_type, is_enemy)
	_shake_piece(target.get_node("PieceLabel") as Label)


func _set_piece_on_cell(cell: Panel, piece_type: String, is_enemy: bool) -> void:
	# Remove any existing label
	var old_label: Label = cell.get_node_or_null("PieceLabel") as Label
	if old_label:
		cell.remove_child(old_label)
		old_label.queue_free()

	cell.set_meta("has_piece", true)
	cell.set_meta("piece_type", piece_type)
	cell.set_meta("is_enemy", is_enemy)

	var label: Label = Label.new()
	label.name = "PieceLabel"
	if is_enemy:
		label.text = PIECE_SYMBOLS[piece_type]
		label.add_theme_color_override("font_color", ENEMY_COLOR)
	else:
		label.text = _get_piece_symbol(piece_type)
		label.add_theme_color_override("font_color", PIECE_COLOR)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var font_size: int = floori(cell.size.y * 0.8)
	label.add_theme_font_size_override("font_size", font_size)
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	cell.add_child(label)


# --- Capture effects ---

func _spawn_floating_score(cell: Panel, points: int) -> void:
	var pill: PanelContainer = PanelContainer.new()
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var pill_style: StyleBoxFlat = StyleBoxFlat.new()
	pill_style.bg_color = Color(0.25, 0.45, 0.95, 0.9)
	pill_style.set_corner_radius_all(12)
	pill_style.content_margin_left = 8.0
	pill_style.content_margin_right = 8.0
	pill_style.content_margin_top = 2.0
	pill_style.content_margin_bottom = 2.0
	pill.add_theme_stylebox_override("panel", pill_style)

	var float_label: Label = Label.new()
	float_label.text = "+%d" % points
	float_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	float_label.add_theme_font_size_override("font_size", 16)
	float_label.add_theme_color_override("font_color", Color.WHITE)
	float_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill.add_child(float_label)

	add_child(pill)
	var start_pos: Vector2 = cell.global_position + Vector2(cell.size.x * 0.15, -8.0)
	pill.position = start_pos

	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(pill, "position:y", start_pos.y - 40.0, 0.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(pill, "modulate:a", 0.0, 0.8).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.chain().tween_callback(pill.queue_free)


func _shake_piece(label: Label) -> void:
	var original_x: float = label.position.x
	var tween: Tween = create_tween()
	tween.tween_property(label, "position:x", original_x + 4.0, 0.05)
	tween.tween_property(label, "position:x", original_x - 4.0, 0.05)
	tween.tween_property(label, "position:x", original_x + 2.0, 0.05)
	tween.tween_property(label, "position:x", original_x - 2.0, 0.05)
	tween.tween_property(label, "position:x", original_x, 0.05)


func _shake_piece_long(label: Label) -> void:
	var original_x: float = label.position.x
	var tween: Tween = create_tween()
	tween.tween_property(label, "position:x", original_x + 5.0, 0.06)
	tween.tween_property(label, "position:x", original_x - 5.0, 0.06)
	tween.tween_property(label, "position:x", original_x + 4.0, 0.06)
	tween.tween_property(label, "position:x", original_x - 4.0, 0.06)
	tween.tween_property(label, "position:x", original_x + 3.0, 0.06)
	tween.tween_property(label, "position:x", original_x - 3.0, 0.06)
	tween.tween_property(label, "position:x", original_x + 2.0, 0.06)
	tween.tween_property(label, "position:x", original_x - 2.0, 0.06)
	tween.tween_property(label, "position:x", original_x + 1.0, 0.06)
	tween.tween_property(label, "position:x", original_x - 1.0, 0.06)
	tween.tween_property(label, "position:x", original_x, 0.06)


func _flash_cell_red(cell: Panel) -> void:
	var row: int = cell.get_meta("row")
	var col: int = cell.get_meta("col")
	var original_color: Color
	if (row + col) % 2 == 0:
		original_color = COLOR_LIGHT
	else:
		original_color = COLOR_DARK

	var flash_style: StyleBoxFlat = StyleBoxFlat.new()
	flash_style.bg_color = Color(1.0, 0.2, 0.2, 0.8)
	cell.add_theme_stylebox_override("panel", flash_style)

	var tween: Tween = create_tween()
	tween.tween_interval(0.15)
	tween.tween_callback(func() -> void:
		var s: StyleBoxFlat = StyleBoxFlat.new()
		s.bg_color = original_color
		cell.add_theme_stylebox_override("panel", s)
	)
	tween.tween_interval(0.1)
	tween.tween_callback(func() -> void:
		var s: StyleBoxFlat = StyleBoxFlat.new()
		s.bg_color = Color(1.0, 0.2, 0.2, 0.6)
		cell.add_theme_stylebox_override("panel", s)
	)
	tween.tween_interval(0.15)
	tween.tween_callback(func() -> void:
		_reset_cell_color(cell)
	)


func _spawn_floating_loss(cell: Panel, lost_type: String) -> void:
	var piece_name: String = lost_type.capitalize()

	var pill: PanelContainer = PanelContainer.new()
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var pill_style: StyleBoxFlat = StyleBoxFlat.new()
	pill_style.bg_color = Color(0.85, 0.15, 0.15, 0.9)
	pill_style.set_corner_radius_all(12)
	pill_style.content_margin_left = 8.0
	pill_style.content_margin_right = 8.0
	pill_style.content_margin_top = 2.0
	pill_style.content_margin_bottom = 2.0
	pill.add_theme_stylebox_override("panel", pill_style)

	var float_label: Label = Label.new()
	float_label.text = "Lost a %s" % piece_name
	float_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	float_label.add_theme_font_size_override("font_size", 14)
	float_label.add_theme_color_override("font_color", Color.WHITE)
	float_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill.add_child(float_label)

	add_child(pill)
	var start_pos: Vector2 = cell.global_position + Vector2(cell.size.x * 0.1, -8.0)
	pill.position = start_pos

	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(pill, "position:y", start_pos.y - 40.0, 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(pill, "modulate:a", 0.0, 1.0).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.chain().tween_callback(pill.queue_free)
