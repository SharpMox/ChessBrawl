extends Control

const GAME_SCENE: String = "res://scenes/game.tscn"
const MENU_SCENE: String = "res://scenes/menu.tscn"

@onready var _good_card: PanelContainer = %GoodCard
@onready var _bad_card: PanelContainer = %BadCard
@onready var _ugly_card: PanelContainer = %UglyCard
@onready var _back_button: Button = %BackButton

@onready var _points_labels: Dictionary = {
	"good": %GoodPoints,
	"bad": %BadPoints,
	"ugly": %UglyPoints,
}

@onready var _effect_labels: Dictionary = {
	"good": %GoodEffect,
	"bad": %BadEffect,
	"ugly": %UglyEffect,
}

var _selected_king: String = ""


func _ready() -> void:
	_good_card.gui_input.connect(_on_card_input.bind("good"))
	_bad_card.gui_input.connect(_on_card_input.bind("bad"))
	_ugly_card.gui_input.connect(_on_card_input.bind("ugly"))
	_back_button.pressed.connect(_on_back_button_pressed)
	_populate_cards()


func _populate_cards() -> void:
	for king_type: String in _points_labels:
		var pts: int = GameData.get_king_points_for(king_type)
		var pts_label: Label = _points_labels[king_type] as Label
		pts_label.text = "%d pts" % pts

		var effect: String = GameData.get_king_effect(king_type)
		var effect_label: Label = _effect_labels[king_type] as Label
		if effect == "" or effect == "No special effect.":
			effect_label.visible = false
		else:
			effect_label.text = effect
			effect_label.visible = true


func _on_card_input(event: InputEvent, king_type: String) -> void:
	if not event is InputEventMouseButton:
		return
	var mb: InputEventMouseButton = event as InputEventMouseButton
	if not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	_select_king(king_type)


func _select_king(king_type: String) -> void:
	_selected_king = king_type
	GameData.king_type = king_type
	get_tree().change_scene_to_file(GAME_SCENE)



func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file(MENU_SCENE)
