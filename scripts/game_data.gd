extends Node

const KING_SYMBOLS: Dictionary = {
	"good": "♔",
	"bad": "♚",
	"ugly": "⚜",
}

const KING_DATA: Dictionary = {
	"good": {
		"points": 3,
		"effect": "No special effect.",
	},
	"bad": {
		"points": 3,
		"effect": "No special effect.",
	},
	"ugly": {
		"points": 9,
		"effect": "Starts with 9 points\ninstead of 3.",
	},
}

var king_type: String = "good"


func get_king_symbol() -> String:
	return KING_SYMBOLS.get(king_type, "♔")


func get_king_points() -> int:
	return KING_DATA.get(king_type, {}).get("points", 3)


func get_king_effect(type: String) -> String:
	return KING_DATA.get(type, {}).get("effect", "")


func get_king_points_for(type: String) -> int:
	return KING_DATA.get(type, {}).get("points", 3)


func is_ugly() -> bool:
	return king_type == "ugly"
