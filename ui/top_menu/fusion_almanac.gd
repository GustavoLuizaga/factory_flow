extends CanvasLayer

## Almanaque de Fusiones - Estilo Plantas vs Zombis

signal almanac_closed

@onready var bg_panel: ColorRect = $BackgroundPanel
@onready var main_panel: Panel = $MainPanel
@onready var scroll_container: ScrollContainer = $MainPanel/ScrollContainer
@onready var grid_container: GridContainer = $MainPanel/ScrollContainer/GridContainer
@onready var close_btn: Button = $MainPanel/CloseButton
@onready var title_label: Label = $MainPanel/Title

var is_visible: bool = false
var dogica_font = preload("res://assets/scenes/dogica.ttf")

# Diccionario de rutas de imágenes para cada elemento
var element_images: Dictionary = {
	"Papel": "res://assets/images/item_paper.png",
	"Metal": "res://assets/images/item_metal.png",
	"Plastico": "res://assets/images/item_plastic.png",
	"Madera": "res://assets/images/item_wood.png",
	"Vidrio": "res://assets/images/item_glass.png",
	"Lata con etiqueta": "res://assets/images/Lata_con_etiqueta.png",
	"Botella con etiqueta": "res://assets/images/Botella_con_etiqueta.png",
	"Libro": "res://assets/images/Libro.png",
	"Caja de carton prensado": "res://assets/images/Caja_de_carton_prensado.png",
	"Botella con tapa metalica": "res://assets/images/Botella_con_tapa_metalica.png",
	"Cable recubierto": "res://assets/images/Cable_recubierto.png",
	"Herramienta con mango de madera": "res://assets/images/Herramienta_con_mango_de_madera.png",
	"Botella con tapa plastica": "res://assets/images/Botella_con_tapa_plastica.png",
	"Juguete": "res://assets/images/Juguete.png",
	"Ventana con marco de madera": "res://assets/images/Ventana_con_marco_de_madera.png"
}

# Colores para los ítems
var color_palette = {
	"base": Color(0.15, 0.15, 0.15),
	"fusion": Color(0.2, 0.3, 0.2),
	"border": Color.WHITE,
	"text": Color.WHITE
}


func _ready() -> void:
	# Ocultar inicialmente
	visible = false
	
	# Estilizar título
	if title_label:
		title_label.add_theme_font_override("font", dogica_font)
		title_label.add_theme_font_size_override("font_size", 24)
		title_label.add_theme_color_override("font_color", Color.YELLOW)
	
	# Estilizar panel principal
	if main_panel:
		var panel_style = StyleBoxFlat.new()
		panel_style.bg_color = Color(0.1, 0.1, 0.1, 0.95)
		panel_style.border_color = Color.WHITE
		panel_style.set_border_width(SIDE_LEFT, 3)
		panel_style.set_border_width(SIDE_RIGHT, 3)
		panel_style.set_border_width(SIDE_TOP, 3)
		panel_style.set_border_width(SIDE_BOTTOM, 3)
		main_panel.add_theme_stylebox_override("panel", panel_style)
	
	# Estilizar botón de cerrar
	if close_btn:
		close_btn.add_theme_font_override("font", dogica_font)
		close_btn.add_theme_font_size_override("font_size", 16)
		close_btn.pressed.connect(_on_close_pressed)
	
	# Crear tarjetas de fusiones
	populate_fusion_cards()
	
	# Conectar clic en background para cerrar
	if bg_panel:
		bg_panel.gui_input.connect(_on_bg_panel_input)
	
	print("✅ Almanaque de Fusiones inicializado")


func populate_fusion_cards() -> void:
	# Limpiar contenedor
	for child in grid_container.get_children():
		child.queue_free()
	
	# Obtener datos del GameManager
	var all_elements = GameManager.elements
	var recipes = GameManager.recipes
	
	# Crear tarjeta para cada elemento
	for element in all_elements:
		var card = create_fusion_card(element, recipes)
		grid_container.add_child(card)
	
	print("✅ %d tarjetas de fusión creadas" % all_elements.size())


func create_fusion_card(element: Dictionary, recipes: Dictionary) -> Control:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(140, 200)
	
	# Determinar si es elemento base o fusión
	var is_base = element.get("es_base", false)
	var bg_color = color_palette["base"] if is_base else color_palette["fusion"]
	
	# Estilo del panel
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = bg_color
	stylebox.border_color = color_palette["border"]
	stylebox.set_border_width(SIDE_LEFT, 2)
	stylebox.set_border_width(SIDE_RIGHT, 2)
	stylebox.set_border_width(SIDE_TOP, 2)
	stylebox.set_border_width(SIDE_BOTTOM, 2)
	stylebox.set_corner_radius(CORNER_TOP_LEFT, 5)
	stylebox.set_corner_radius(CORNER_TOP_RIGHT, 5)
	stylebox.set_corner_radius(CORNER_BOTTOM_LEFT, 5)
	stylebox.set_corner_radius(CORNER_BOTTOM_RIGHT, 5)
	
	card.add_theme_stylebox_override("panel", stylebox)
	
	# Contenedor vertical para el contenido
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.add_child(vbox)
	
	# Contenedor para la imagen/ícono
	var image_container = CenterContainer.new()
	image_container.custom_minimum_size = Vector2(0, 70)
	
	var texture_rect = TextureRect.new()
	texture_rect.custom_minimum_size = Vector2(60, 60)
	texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	
	# Cargar imagen si existe
	var element_name = element["nombre"]
	if element_images.has(element_name):
		var texture_path = element_images[element_name]
		if ResourceLoader.exists(texture_path):
			texture_rect.texture = load(texture_path)
		else:
			# Crear un rectángulo de color como fallback
			var color_rect = ColorRect.new()
			color_rect.color = GameManager.material_colors.get(element_name, Color.GRAY)
			color_rect.custom_minimum_size = Vector2(60, 60)
			image_container.add_child(color_rect)
	else:
		# Usar color del GameManager
		var color_rect = ColorRect.new()
		color_rect.color = GameManager.material_colors.get(element_name, Color.GRAY)
		color_rect.custom_minimum_size = Vector2(60, 60)
		image_container.add_child(color_rect)
	
	if texture_rect.texture:
		image_container.add_child(texture_rect)
	
	vbox.add_child(image_container)
	
	# Nombre del elemento
	var name_label = Label.new()
	name_label.text = element_name
	name_label.add_theme_font_override("font", dogica_font)
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.add_theme_color_override("font_color", color_palette["text"])
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.custom_minimum_size = Vector2(0, 30)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(name_label)
	
	# Tipo (Base o Fusión)
	var type_label = Label.new()
	type_label.text = "BASE" if is_base else "FUSIÓN"
	type_label.add_theme_font_override("font", dogica_font)
	type_label.add_theme_font_size_override("font_size", 9)
	type_label.add_theme_color_override("font_color", Color.YELLOW if is_base else Color.LIME)
	type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(type_label)
	
	# Descripción de cómo obtenerlo
	var description = get_fusion_description(element, recipes)
	var desc_label = Label.new()
	desc_label.text = description
	desc_label.add_theme_font_override("font", dogica_font)
	desc_label.add_theme_font_size_override("font_size", 8)
	desc_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_label.custom_minimum_size = Vector2(0, 60)
	vbox.add_child(desc_label)
	
	return card


func get_fusion_description(element: Dictionary, recipes: Dictionary) -> String:
	var element_name = element["nombre"]
	var is_base = element.get("es_base", false)
	
	if is_base:
		return "Material Base\nNo requiere fusión"
	
	# Buscar qué elementos se combinan para hacer este
	for recipe_key in recipes.keys():
		if recipes[recipe_key] == element_name:
			var parts = recipe_key.split("+")
			if parts.size() == 2:
				return "%s\n+\n%s" % [parts[0].strip_edges(), parts[1].strip_edges()]
	
	return "Fusión\nDesconocida"


func toggle_almanac() -> void:
	is_visible = !is_visible
	visible = is_visible
	
	if is_visible:
		print("📖 Almanaque abierto")
		get_tree().paused = true
	else:
		print("📖 Almanaque cerrado")
		get_tree().paused = false


func _on_close_pressed() -> void:
	toggle_almanac()
	almanac_closed.emit()


func _on_bg_panel_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		# Solo cerrar si se hace clic fuera del panel principal
		var mouse_pos = get_viewport().get_mouse_position()
		if main_panel and main_panel.get_global_rect().has_point(mouse_pos):
			return
		toggle_almanac()
		almanac_closed.emit()


func _input(event: InputEvent) -> void:
	# Cerrar con ESC cuando el almanaque esté abierto
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if is_visible:
			toggle_almanac()
			almanac_closed.emit()
			get_tree().root.set_input_as_handled()
