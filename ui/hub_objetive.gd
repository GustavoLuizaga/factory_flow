# res://ui/hub_objetive.gd
extends Node2D
class_name HubObjective

# --- Parámetros del HUB ---
@export var num_slots: int = 4          # cantidad de cuadros visibles
@export var slot_size: int = 64         # lado de cada cuadro
@export var spacing: int = 8            # espacio entre cuadros y bordes
@export var show_titles: bool = false   # mostrar u ocultar texto bajo el icono

# --- Referencias de la escena (mantén tu jerarquía actual) ---
@onready var background: ColorRect = $Background
@onready var container: GridContainer = $Container

# Objetivos visibles
# [{ "title": String, "target": int, "current": int, "icon": Texture2D, "slot": Control }]
var objectives: Array[Dictionary] = []


func _ready() -> void:
	setup_background()
	setup_container()
	populate_slots()


# -------------------------
# Fondo del HUB
# -------------------------
func setup_background() -> void:
	background.color = Color(0.1, 0.1, 0.15, 0.9)
	background.size = Vector2(
		(num_slots * (slot_size + spacing)) + spacing,
		slot_size + spacing * 2
	)


# -------------------------
# Contenedor cuadriculado
# -------------------------
func setup_container() -> void:
	container.columns = num_slots
	container.position = Vector2(spacing, spacing)
	container.custom_minimum_size = Vector2(num_slots * slot_size, slot_size)
	container.add_theme_constant_override("hseparation", spacing)
	container.add_theme_constant_override("vseparation", spacing)
	container.clip_contents = true   # recorta desbordes


# -------------------------
# Placeholders vacíos
# -------------------------
func populate_slots() -> void:
	for c in container.get_children():
		c.queue_free()
		
func _debug_dump():
	print("children:", container.get_child_count())
	for i in range(container.get_child_count()):
		var s = container.get_child(i)
		print(i, " filled=", s.get_meta("filled", false))


# -------------------------------------------------------------------
# Crea un slot: icono + (opcional) título + insignia "current/target"
# -------------------------------------------------------------------
func _make_slot(icon: Texture2D, title: String, current: int, target: int) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(slot_size, slot_size)

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.25, 0.25, 0.3, 1)
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = Color(0.35, 0.35, 0.45, 0.8)
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_right = 8
	sb.corner_radius_bottom_left = 8
	panel.add_theme_stylebox_override("panel", sb)

	# Layout vertical: icono arriba, texto abajo
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 4)
	panel.add_child(v)

	var tr := TextureRect.new()
	tr.texture = icon
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	tr.size_flags_vertical = Control.SIZE_EXPAND | Control.SIZE_FILL
	tr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(tr)

	var lbl := Label.new()
	lbl.text = title
	lbl.visible = show_titles
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.clip_text = true
	lbl.custom_minimum_size = Vector2(0, 22)  # reserva altura fija
	v.add_child(lbl)

	# Overlay para la insignia
	var overlay := Control.new()
	overlay.anchor_right = 1
	overlay.anchor_bottom = 1
	panel.add_child(overlay)

	var topbar := HBoxContainer.new()
	topbar.anchor_right = 1
	topbar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	topbar.add_theme_constant_override("separation", 0)
	topbar.position = Vector2(0, 6) # margen superior
	overlay.add_child(topbar)

	# Spacer que empuja a la derecha
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_FILL
	topbar.add_child(spacer)

	var badge_panel := PanelContainer.new()
	var badge_sb := StyleBoxFlat.new()
	if target > 0 and current < target:
		badge_sb.bg_color = Color(0.15, 0.7, 0.3, 1)
	else:
		badge_sb.bg_color = Color(0.2, 0.5, 0.2, 1)
	badge_sb.corner_radius_top_left = 6
	badge_sb.corner_radius_top_right = 6
	badge_sb.corner_radius_bottom_right = 6
	badge_sb.corner_radius_bottom_left = 6
	badge_panel.add_theme_stylebox_override("panel", badge_sb)
	topbar.add_child(badge_panel)

	var badge_margin := MarginContainer.new()
	badge_margin.add_theme_constant_override("margin_left", 6)
	badge_margin.add_theme_constant_override("margin_right", 6)
	badge_margin.add_theme_constant_override("margin_top", 2)
	badge_margin.add_theme_constant_override("margin_bottom", 2)
	badge_panel.add_child(badge_margin)

	var badge_label := Label.new()
	if target > 0:
		badge_label.text = str(current) + "/" + str(target)
	else:
		badge_label.text = ""
	badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge_label.add_theme_font_size_override("font_size", 12)
	badge_margin.add_child(badge_label)

	# Metadatos para actualizaciones
	panel.set_meta("icon_texrect", tr)
	panel.set_meta("title_lbl", lbl)
	panel.set_meta("badge_panel", badge_panel)
	panel.set_meta("badge_lbl", badge_label)

	return panel


# -------------------------------------------------------------------
# Añadir objetivo con icono y meta
# -------------------------------------------------------------------
func add_objective_with_icon(title: String, target: int, icon_tex: Texture2D, current: int = 0) -> void:
	var obj := {
		"title": title,
		"target": target,
		"current": clamp(current, 0, target),
		"icon": icon_tex,
		"slot": null
	}

	var replaced := false
	var idx := 0
	for s in container.get_children():
		if not s.get_meta("filled", false):
			var new_slot := _make_slot(icon_tex, title, obj.current, target)
			new_slot.set_meta("filled", true)

			container.remove_child(s)
			s.queue_free()
			container.add_child(new_slot)
			container.move_child(new_slot, idx) # conserva posición visual

			obj.slot = new_slot
			replaced = true
			break
		idx += 1

	# Si no había espacio, reutiliza los placeholders existentes
	if not replaced:
		if container.get_child_count() > objectives.size():
			var s := container.get_child(objectives.size())
			var new_slot := _make_slot(icon_tex, title, obj.current, target)
			new_slot.set_meta("filled", true)
			container.remove_child(s)
			s.queue_free()
			container.add_child(new_slot)
			obj.slot = new_slot
		else:
			var new_slot2 := _make_slot(icon_tex, title, obj.current, target)
			new_slot2.set_meta("filled", true)
			container.add_child(new_slot2)
			num_slots += 1
			setup_background()


	objectives.append(obj)


# -------------------------------------------------------------------
# Actualizar progreso por índice
# -------------------------------------------------------------------
func set_progress(index: int, current: int) -> void:
	if index < 0 or index >= objectives.size():
		return
	var o: Dictionary = objectives[index]
	o.current = clamp(current, 0, o.target)
	_update_slot(o)

func add_progress(index: int, delta: int = 1) -> void:
	if index < 0 or index >= objectives.size():
		return
	var o: Dictionary = objectives[index]
	o.current = clamp(o.current + delta, 0, o.target)
	_update_slot(o)


# -------------------------
# Refresco visual del slot
# -------------------------
func _update_slot(o: Dictionary) -> void:
	if o.slot == null:
		return

	# contador
	var badge_lbl: Label = o.slot.get_meta("badge_lbl")
	badge_lbl.text = str(o.current) + "/" + str(o.target)

	# panel del slot
	var panel_sb := StyleBoxFlat.new()
	if o.current >= o.target:
		panel_sb.bg_color = Color(0.18, 0.35, 0.18, 1)
	else:
		panel_sb.bg_color = Color(0.25, 0.25, 0.3, 1)
	panel_sb.border_width_left = 1
	panel_sb.border_width_top = 1
	panel_sb.border_width_right = 1
	panel_sb.border_width_bottom = 1
	panel_sb.corner_radius_top_left = 8
	panel_sb.corner_radius_top_right = 8
	panel_sb.corner_radius_bottom_right = 8
	panel_sb.corner_radius_bottom_left = 8
	o.slot.add_theme_stylebox_override("panel", panel_sb)

	# insignia
	var badge_panel: PanelContainer = o.slot.get_meta("badge_panel")
	var badge_sb := StyleBoxFlat.new()
	if o.current >= o.target:
		badge_sb.bg_color = Color(0.12, 0.55, 0.2, 1)
	else:
		badge_sb.bg_color = Color(0.15, 0.7, 0.3, 1)
	badge_sb.corner_radius_top_left = 6
	badge_sb.corner_radius_top_right = 6
	badge_sb.corner_radius_bottom_right = 6
	badge_sb.corner_radius_bottom_left = 6
	badge_panel.add_theme_stylebox_override("panel", badge_sb)


# -------------------------
# Tamaño útil para posicionar el HUB desde fuera
# -------------------------
func get_size() -> Vector2:
	return background.size


# -------------------------
# Wrapper opcional sin icono
# -------------------------
func add_objective(texto: String, target: int = 1, current: int = 0) -> void:
	add_objective_with_icon(texto, target, null, current)
