extends Control

@onready var btn1: Button = $"PanelContainer/VBoxContainer/HBoxContainer/btnNivel1"
@onready var lock1: Label = $"PanelContainer/VBoxContainer/HBoxContainer/Lock1"
@onready var btn2: Button = $"PanelContainer/VBoxContainer/HBoxContainer2/btnNivel2"
@onready var lock2: Label = $"PanelContainer/VBoxContainer/HBoxContainer2/Lock2"

func _ready() -> void:
	_refresh()

func _refresh() -> void:
	# Nivel 1 siempre desbloqueado
	btn1.disabled = false
	lock1.visible = true   # muestra “✔”
	# Nivel 2 según progreso
	var unlocked2 := ProgressManager.is_unlocked(2)
	btn2.disabled = not unlocked2
	lock2.text = "✔" if unlocked2 else "🔒"

func _on_BtnLevel1_pressed() -> void:
	get_tree().change_scene_to_file("res://level1/level_01.tscn")

func _on_BtnLevel2_pressed() -> void:
	if ProgressManager.is_unlocked(2):
		get_tree().change_scene_to_file("res://level2/level_02.tscn")

func _on_BtnVolver_pressed() -> void:
	get_tree().change_scene_to_file("res://Menu/menu.tscn")


func _on_btn_nivel_1_pressed() -> void:
	pass # Replace with function body.
