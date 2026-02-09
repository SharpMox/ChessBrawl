class_name EnemyAi
extends RefCounted

const SELECT_DELAY: float = 0.3
const MOVE_DELAY: float = 0.3

var _game: Control
var phase: int = 0
var timer: float = 0.0
var source: Panel = null
var target: Panel = null


func _init(game: Control) -> void:
	_game = game


func reset() -> void:
	phase = 0
	timer = SELECT_DELAY
	source = null
	target = null


func tick(delta: float) -> void:
	timer -= delta
	if timer > 0.0:
		return

	if phase == 0:
		var move: Dictionary = _choose_move()
		if move.is_empty():
			_game._start_player_turn()
		else:
			source = move["source"]
			target = move["target"]
			_highlight_selection()
			phase = 1
			timer = MOVE_DELAY
	elif phase == 1:
		_execute_move()


# --- Move validation (enemy perspective) ---

func _is_enemy_friendly(row: int, col: int) -> bool:
	var cell: Panel = _game._get_cell(row, col)
	return cell.get_meta("has_piece") and cell.get_meta("is_enemy")


func _is_player_piece_at(row: int, col: int) -> bool:
	var cell: Panel = _game._get_cell(row, col)
	return cell.get_meta("has_piece") and not cell.get_meta("is_enemy")


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


func _get_pawn_moves(row: int, col: int) -> Array[Vector2i]:
	var moves: Array[Vector2i] = []
	if _game._is_in_bounds(row + 1, col) and not _game._get_cell(row + 1, col).get_meta("has_piece"):
		moves.append(Vector2i(row + 1, col))
	for dc: int in [-1, 1]:
		if _game._is_in_bounds(row + 1, col + dc) and _is_player_piece_at(row + 1, col + dc):
			moves.append(Vector2i(row + 1, col + dc))
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
		if _game._is_in_bounds(r, c) and not _is_enemy_friendly(r, c):
			moves.append(Vector2i(r, c))
	return moves


func _get_sliding_moves(row: int, col: int, directions: Array[Vector2i]) -> Array[Vector2i]:
	var moves: Array[Vector2i] = []
	for dir: Vector2i in directions:
		var r: int = row + dir.x
		var c: int = col + dir.y
		while _game._is_in_bounds(r, c):
			if _is_enemy_friendly(r, c):
				break
			moves.append(Vector2i(r, c))
			if _is_player_piece_at(r, c):
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
			if _game._is_in_bounds(r, c) and not _is_enemy_friendly(r, c):
				moves.append(Vector2i(r, c))
	return moves


# --- AI decision ---

func _choose_move() -> Dictionary:
	var capture_moves: Array[Dictionary] = []
	var advance_moves: Array[Dictionary] = []

	for cell: Panel in _game._cells:
		if not cell.get_meta("is_enemy"):
			continue
		var row: int = cell.get_meta("row")
		var col: int = cell.get_meta("col")
		var piece_type: String = cell.get_meta("piece_type")
		var moves: Array[Vector2i] = _get_valid_moves(row, col, piece_type)
		var piece_value: int = _game.PIECE_COSTS.get(piece_type, 0)

		for move: Vector2i in moves:
			var target_cell: Panel = _game._get_cell(move.x, move.y)

			if target_cell.get_meta("has_piece") and not target_cell.get_meta("is_enemy"):
				# Capture move — prefer high-value target, cheap attacker, short distance
				var target_value: int = _game.PIECE_COSTS.get(target_cell.get_meta("piece_type"), 0)
				var distance: int = absi(row - move.x) + absi(col - move.y)
				var score: float = target_value * 100.0 - piece_value * 10.0 - float(distance)
				capture_moves.append({"source": cell, "target": target_cell, "score": score})
			else:
				# Advance move — get closer to player pieces, avoid risk for expensive pieces
				var closest_dist: float = _closest_player_distance(move.x, move.y)
				var is_at_risk: bool = _is_cell_attacked_by_player(move.x, move.y)
				var score: float = -closest_dist * 10.0
				if is_at_risk:
					if piece_value > 1:
						score -= 1000.0
					else:
						score -= 5.0
				advance_moves.append({"source": cell, "target": target_cell, "score": score})

	if not capture_moves.is_empty():
		capture_moves.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["score"] > b["score"])
		return {"source": capture_moves[0]["source"], "target": capture_moves[0]["target"]}

	if not advance_moves.is_empty():
		advance_moves.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["score"] > b["score"])
		return {"source": advance_moves[0]["source"], "target": advance_moves[0]["target"]}

	return {}


func _closest_player_distance(row: int, col: int) -> float:
	var min_dist: float = INF
	for cell: Panel in _game._cells:
		if cell.get_meta("has_piece") and not cell.get_meta("is_enemy"):
			var pr: int = cell.get_meta("row")
			var pc: int = cell.get_meta("col")
			var dist: float = float(absi(row - pr) + absi(col - pc))
			if dist < min_dist:
				min_dist = dist
	return min_dist


func _is_cell_attacked_by_player(row: int, col: int) -> bool:
	for cell: Panel in _game._cells:
		if not cell.get_meta("has_piece") or cell.get_meta("is_enemy"):
			continue
		var pr: int = cell.get_meta("row")
		var pc: int = cell.get_meta("col")
		var pt: String = cell.get_meta("piece_type")
		if _can_player_piece_attack(pr, pc, pt, row, col):
			return true
	return false


func _can_player_piece_attack(pr: int, pc: int, piece_type: String, tr: int, tc: int) -> bool:
	match piece_type:
		"pawn":
			return tr == pr - 1 and absi(tc - pc) == 1
		"knight":
			var dr: int = absi(tr - pr)
			var dc: int = absi(tc - pc)
			return (dr == 2 and dc == 1) or (dr == 1 and dc == 2)
		"bishop":
			var dirs: Array[Vector2i] = [Vector2i(-1, -1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(1, 1)]
			return _can_slide_attack(pr, pc, tr, tc, dirs)
		"rook":
			var dirs: Array[Vector2i] = [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]
			return _can_slide_attack(pr, pc, tr, tc, dirs)
		"queen":
			var dirs: Array[Vector2i] = [
				Vector2i(-1, -1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(1, 1),
				Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1),
			]
			return _can_slide_attack(pr, pc, tr, tc, dirs)
		"king":
			return absi(tr - pr) <= 1 and absi(tc - pc) <= 1 and not (tr == pr and tc == pc)
	return false


func _can_slide_attack(pr: int, pc: int, tr: int, tc: int, directions: Array[Vector2i]) -> bool:
	for dir: Vector2i in directions:
		var r: int = pr + dir.x
		var c: int = pc + dir.y
		while _game._is_in_bounds(r, c):
			if r == tr and c == tc:
				return true
			if _game._get_cell(r, c).get_meta("has_piece"):
				break
			r += dir.x
			c += dir.y
	return false


# --- Highlighting ---

func _highlight_selection() -> void:
	if source != null:
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color = _game.COLOR_ENEMY_SELECTED
		source.add_theme_stylebox_override("panel", style)
	if target != null:
		var style: StyleBoxFlat = StyleBoxFlat.new()
		if target.get_meta("has_piece") and not target.get_meta("is_enemy"):
			style.bg_color = _game.COLOR_VALID_CAPTURE
		else:
			style.bg_color = _game.COLOR_VALID_MOVE
		target.add_theme_stylebox_override("panel", style)


func _clear_selection() -> void:
	if source != null:
		_game._reset_cell_color(source)
	if target != null:
		_game._reset_cell_color(target)
	source = null
	target = null


# --- Move execution ---

func _execute_move() -> void:
	if source == null or target == null:
		_game._start_player_turn()
		return

	var piece_type: String = source.get_meta("piece_type")
	var src: Panel = source
	var tgt: Panel = target

	_clear_selection()

	# Remove piece from source
	var source_label: Label = src.get_node_or_null("PieceLabel") as Label
	if source_label:
		src.remove_child(source_label)
		source_label.queue_free()
	src.set_meta("has_piece", false)
	src.set_meta("piece_type", "")
	src.set_meta("is_enemy", false)

	# Handle capture of player piece
	var captured: bool = tgt.get_meta("has_piece") and not tgt.get_meta("is_enemy")
	var captured_type: String = ""
	if captured:
		captured_type = tgt.get_meta("piece_type")
		var target_label: Label = tgt.get_node_or_null("PieceLabel") as Label
		if target_label:
			tgt.remove_child(target_label)
			target_label.queue_free()

	# Place enemy on target
	tgt.set_meta("has_piece", true)
	tgt.set_meta("piece_type", piece_type)
	tgt.set_meta("is_enemy", true)

	var label: Label = Label.new()
	label.name = "PieceLabel"
	label.text = _game.PIECE_SYMBOLS[piece_type]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var font_size: int = floori(tgt.size.y * 0.8)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", _game.ENEMY_COLOR)
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	tgt.add_child(label)

	if captured and captured_type != "":
		_game._shake_piece(label)
		_game._flash_cell_red(tgt)
		_game._spawn_floating_loss(tgt, captured_type)
		_game._lost_pieces.append(captured_type)
		if captured_type == "king":
			_game._king_placed = false
			_game._cancel_turn_indicators()
			var tween: Tween = _game.create_tween()
			tween.tween_interval(_game.SPAWN_CAPTURE_DELAY)
			tween.tween_callback(_game._show_game_over)
			return

	# Enemy pawn promotion: reaches bottom row (GRID_ROWS - 1)
	if piece_type == "pawn" and tgt.get_meta("row") == _game.GRID_ROWS - 1:
		_game._promote_pawn(tgt, true)

	_game._start_player_turn()
