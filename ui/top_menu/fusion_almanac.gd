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
	# Elementos base
	"Papel": "res://assets/images/item_paper.png",
	"Metal": "res://assets/images/item_metal.png",
	"Plastico": "res://assets/images/item_plastic.png",
	"Madera": "res://assets/images/item_wood.png",
	"Vidrio": "res://assets/images/item_glass.png",
	
	# Fusiones básicas (nivel 1)
	"Lata con etiqueta": "res://assets/images/Lata_con_etiqueta.png",
	"Botella con etiqueta": "res://assets/images/Botella_con_etiqueta.png",
	"Libro": "res://assets/images/Libro.png",
	"Caja de carton prensado": "res://assets/images/Caja_de_carton_prensado.png",
	"Botella con tapa metalica": "res://assets/images/Botella_con_tapa_metalica.png",
	"Cable recubierto": "res://assets/images/Cable_recubierto.png",
	"Herramienta con mango de madera": "res://assets/images/Herramienta_con_mango_de_madera.png",
	"Botella con tapa plastica": "res://assets/images/Botella_con_tapa_plastica.png",
	"Juguete": "res://assets/images/Juguete.png",
	"Ventana con marco de madera": "res://assets/images/Ventana_con_marco_de_madera.png",
	
	# Super fusiones (nivel 2)
	"Pack de bebidas reciclado": "res://assets/images/subFusiones/Pack_de_bebidas_reciclado.png",
	"Biblioteca reciclada": "res://assets/images/subFusiones/Biblioteca_reciclada.png",
	"Coleccion de envases": "res://assets/images/subFusiones/Coleccion_de_envases.png",
	"Kit electrico reciclado": "res://assets/images/subFusiones/Kit_electrico_reciclado.png",
	"Botella de coleccion": "res://assets/images/subFusiones/Botella_de_coleccion.png",
	"Invernadero basico": "res://assets/images/subFusiones/Invernadero_basico.png",
	"E-book": "res://assets/images/subFusiones/E_book.png",
	"Botella con sorpresa": "res://assets/images/subFusiones/Botella_con_sorpresa.png",
	"Casa infantil de juguetes": "res://assets/images/subFusiones/Casa_infantil_de_juguetes.png",
	
	# Fusiones definitivas (nivel 3)
	"Centro educativo de reciclaje": "res://assets/images/FucionesDefinitivas/Centro_educativo_de_reciclaje.png",
	"Taller de proyectos domésticos reciclados": "res://assets/images/FucionesDefinitivas/Taller_de_proyectos_domesticos_reciclados.png",
	"Invernadero experimental": "res://assets/images/FucionesDefinitivas/Invernadero_experimental.png",
	"Estación educativa interactiva": "res://assets/images/FucionesDefinitivas/Estacion_educativa_interactiva.png",
	"Taller de manualidades": "res://assets/images/FucionesDefinitivas/Taller_de_manualidades_infantil.png"
}

# Colores para los ítems - Mejorados
var color_palette = {
	"base": Color(0.12, 0.15, 0.22),  # Azul oscuro para base
	"fusion": Color(0.15, 0.25, 0.15),  # Verde oscuro para fusiones
	"ultimate": Color(0.25, 0.15, 0.22),  # Púrpura para fusiones definitivas
	"border": Color(0.8, 0.85, 1.0),  # Borde azul claro
	"border_base": Color(0.9, 0.85, 0.4),  # Dorado para base
	"border_fusion": Color(0.4, 0.9, 0.5),  # Verde brillante para fusiones
	"border_ultimate": Color(0.9, 0.4, 0.8),  # Rosa/púrpura para definitivas
	"text": Color.WHITE,
	"text_shadow": Color(0.0, 0.0, 0.0, 0.5)
}

# Diccionario para almacenar información de máquinas por receta
var machine_for_recipe: Dictionary = {}


func _ready() -> void:
	# Ocultar inicialmente
	visible = false
	
	# Cargar información de máquinas desde JSON
	_load_machine_info()
	
	# Estilizar título
	if title_label:
		title_label.add_theme_font_override("font", dogica_font)
		title_label.add_theme_font_size_override("font_size", 32)
		title_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))  # Dorado brillante
		# Agregar sombra al título
		title_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
		title_label.add_theme_constant_override("shadow_offset_x", 2)
		title_label.add_theme_constant_override("shadow_offset_y", 2)
	
	# Estilizar panel principal con gradiente
	if main_panel:
		var panel_style = StyleBoxFlat.new()
		panel_style.bg_color = Color(0.08, 0.08, 0.12, 0.97)
		panel_style.border_color = Color(0.9, 0.85, 0.4)  # Borde dorado
		panel_style.set_border_width(SIDE_LEFT, 4)
		panel_style.set_border_width(SIDE_RIGHT, 4)
		panel_style.set_border_width(SIDE_TOP, 4)
		panel_style.set_border_width(SIDE_BOTTOM, 4)
		panel_style.set_corner_radius(CORNER_TOP_LEFT, 12)
		panel_style.set_corner_radius(CORNER_TOP_RIGHT, 12)
		panel_style.set_corner_radius(CORNER_BOTTOM_LEFT, 12)
		panel_style.set_corner_radius(CORNER_BOTTOM_RIGHT, 12)
		panel_style.shadow_color = Color(0, 0, 0, 0.6)
		panel_style.shadow_size = 10
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


func _load_machine_info() -> void:
	"""Carga la información de máquinas desde el JSON"""
	var json_path = "res://database/game_data.json"
	
	if not FileAccess.file_exists(json_path):
		print("❌ JSON no encontrado para máquinas")
		return
	
	var file = FileAccess.open(json_path, FileAccess.READ)
	if not file:
		print("❌ Error al abrir JSON")
		return
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_text)
	
	if error != OK:
		print("❌ Error al parsear JSON: ", json.get_error_message())
		return
	
	var data = json.data
	
	if data.has("combinaciones"):
		# Mapear elementos ID a nombre
		var id_to_name: Dictionary = {}
		if data.has("elementos"):
			for elem in data["elementos"]:
				id_to_name[elem["id"]] = elem["nombre"]
		
		# Cargar información de máquinas
		for combo in data["combinaciones"]:
			if combo.has("maquina"):
				var mat1_id = combo["elemento1"]
				var mat2_id = combo["elemento2"]
				var resultado_id = combo["resultado"]
				var maquina = combo["maquina"]
				
				var mat1_nombre = id_to_name.get(mat1_id, "")
				var mat2_nombre = id_to_name.get(mat2_id, "")
				var resultado_nombre = id_to_name.get(resultado_id, "")
				
				if mat1_nombre != "" and resultado_nombre != "":
					machine_for_recipe[resultado_nombre] = maquina
					print("🔧 ", resultado_nombre, " requiere: ", maquina)


func create_fusion_card(element: Dictionary, recipes: Dictionary) -> Control:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(240, 260)  # Tarjetas más grandes
	
	# Determinar si es elemento base, fusión o fusión definitiva
	var is_base = element.get("es_base", false)
	var element_id = element.get("id", 0)
	var is_ultimate = element_id >= 25  # IDs 25-29 son fusiones definitivas
	
	var bg_color: Color
	var border_color: Color
	if is_base:
		bg_color = color_palette["base"]
		border_color = color_palette["border_base"]
	elif is_ultimate:
		bg_color = color_palette["ultimate"]
		border_color = color_palette["border_ultimate"]
	else:
		bg_color = color_palette["fusion"]
		border_color = color_palette["border_fusion"]
	
	# Estilo del panel con mejor apariencia
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = bg_color
	stylebox.border_color = border_color
	stylebox.set_border_width(SIDE_LEFT, 3)
	stylebox.set_border_width(SIDE_RIGHT, 3)
	stylebox.set_border_width(SIDE_TOP, 3)
	stylebox.set_border_width(SIDE_BOTTOM, 3)
	stylebox.set_corner_radius(CORNER_TOP_LEFT, 8)
	stylebox.set_corner_radius(CORNER_TOP_RIGHT, 8)
	stylebox.set_corner_radius(CORNER_BOTTOM_LEFT, 8)
	stylebox.set_corner_radius(CORNER_BOTTOM_RIGHT, 8)
	stylebox.shadow_color = Color(0, 0, 0, 0.4)
	stylebox.shadow_size = 4
	stylebox.shadow_offset = Vector2(2, 2)
	
	card.add_theme_stylebox_override("panel", stylebox)
	
	# Contenedor vertical para el contenido
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.add_child(vbox)
	
	# Contenedor para la imagen/ícono - más grande
	var image_container = CenterContainer.new()
	image_container.custom_minimum_size = Vector2(0, 100)
	
	var texture_rect = TextureRect.new()
	texture_rect.custom_minimum_size = Vector2(80, 80)  # Imágenes más grandes
	texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
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
			color_rect.custom_minimum_size = Vector2(50, 50)
			image_container.add_child(color_rect)
	else:
		# Usar color del GameManager
		var color_rect = ColorRect.new()
		color_rect.color = GameManager.material_colors.get(element_name, Color.GRAY)
		color_rect.custom_minimum_size = Vector2(50, 50)
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
	name_label.custom_minimum_size = Vector2(0, 25)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(name_label)
	
	# Tipo (Base, Fusión o Fusión Definitiva)
	var type_label = Label.new()
	if is_base:
		type_label.text = "BASE"
		type_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))  # Dorado
	elif is_ultimate:
		type_label.text = "FUSIÓN DEFINITIVA"
		type_label.add_theme_color_override("font_color", Color(0.9, 0.4, 0.9))  # Púrpura brillante
	else:
		type_label.text = "FUSIÓN"
		type_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))  # Verde lima
	
	type_label.add_theme_font_override("font", dogica_font)
	type_label.add_theme_font_size_override("font_size", 11)
	type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(type_label)
	
	# Información de máquina si es fusión
	if not is_base and machine_for_recipe.has(element_name):
		var machine_label = Label.new()
		machine_label.text = "🔧 " + machine_for_recipe[element_name]
		machine_label.add_theme_font_override("font", dogica_font)
		machine_label.add_theme_font_size_override("font_size", 9)
		machine_label.add_theme_color_override("font_color", Color.ORANGE)
		machine_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		machine_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		machine_label.custom_minimum_size = Vector2(0, 15)
		vbox.add_child(machine_label)
	
	# Descripción de cómo obtenerlo
	var description = get_fusion_description(element, recipes)
	var desc_label = Label.new()
	desc_label.text = description
	desc_label.add_theme_font_override("font", dogica_font)
	desc_label.add_theme_font_size_override("font_size", 9)
	desc_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_label.custom_minimum_size = Vector2(0, 40)
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
