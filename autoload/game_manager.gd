extends Node

## GameManager - Singleton global
## Gestiona recetas, estado del juego y lógica compartida

# Ruta a la base de datos
const DB_PATH = "res://database/factory_db.db"

# Diccionario de recetas: "Material1+Material2" -> "Producto"
var recipes: Dictionary = {}

# Colores únicos para cada tipo de material/producto (provisional hasta tener sprites)
var material_colors: Dictionary = {
	"Papel": Color.WHITE,
	"Metal": Color.GRAY,
	"Plastico": Color.YELLOW,
	"Madera": Color.SADDLE_BROWN,
	"Vidrio": Color.CYAN,
	"Lata con etiqueta": Color.ORANGE_RED,
	"Cable recubierto": Color.GREEN,
	"Juguete": Color.PURPLE
}

# Tipos de materiales base disponibles
var base_materials: Array[String] = []

# Referencia al grid actual
var current_grid: Node = null

# Estadísticas del nivel
var items_produced: int = 0
var successful_fusions: int = 0

# Array para registrar todas las fusiones completadas (para verificar objetivos)
var completed_fusions: Array[String] = []

var db = null


func _ready() -> void:
	print("GameManager inicializado")
	print("🖥️ OS:", OS.get_name())
	# Usar JSON en lugar de SQLite - funciona en todos los sistemas
	_load_from_json()


## Carga elementos y combinaciones desde JSON
func _load_from_json() -> void:
	var json_path = "res://database/game_data.json"
	
	if not FileAccess.file_exists(json_path):
		print("❌ JSON no encontrado, usando datos hardcodeados")
		_load_hardcoded_data()
		return
	
	var file = FileAccess.open(json_path, FileAccess.READ)
	if not file:
		print("❌ Error al abrir JSON, usando datos hardcodeados")
		_load_hardcoded_data()
		return
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_text)
	
	if error != OK:
		print("❌ Error al parsear JSON: ", json.get_error_message())
		_load_hardcoded_data()
		return
	
	var data = json.data
	print("✅ JSON cargado exitosamente")
	
	# Limpiar diccionarios
	recipes.clear()
	base_materials.clear()
	
	# Cargar elementos base
	if data.has("elementos"):
		for elem in data["elementos"]:
			if elem.get("es_base", false):
				base_materials.append(elem["nombre"])
	
	# Cargar combinaciones
	if data.has("combinaciones"):
		# Primero crear un mapa de ID a nombre para búsqueda rápida
		var id_to_name: Dictionary = {}
		for elem in data["elementos"]:
			id_to_name[elem["id"]] = elem["nombre"]
		
		print("📋 Mapa de elementos ID->Nombre:")
		for id in id_to_name.keys():
			print("   ", id, " -> ", id_to_name[id])
		
		# Ahora procesar las combinaciones
		for combo in data["combinaciones"]:
			var mat1_id = combo["elemento1"]
			var mat2_id = combo["elemento2"]
			var resultado_id = combo["resultado"]
			
			# Obtener nombres usando el mapa
			var mat1_nombre = id_to_name.get(mat1_id, "")
			var mat2_nombre = id_to_name.get(mat2_id, "")
			var resultado_nombre = id_to_name.get(resultado_id, "")
			
			if mat1_nombre == "" or mat2_nombre == "" or resultado_nombre == "":
				print("⚠️ Receta incompleta: ", mat1_id, "+", mat2_id, "->", resultado_id)
				continue
			
			# Crear claves bidireccionales
			var key1 = mat1_nombre + "+" + mat2_nombre
			var key2 = mat2_nombre + "+" + mat1_nombre
			
			recipes[key1] = resultado_nombre
			if key1 != key2:  # Evitar duplicados cuando mat1 == mat2
				recipes[key2] = resultado_nombre
			
			print("✅ Receta: ", mat1_nombre, " + ", mat2_nombre, " = ", resultado_nombre)
	
	print("📦 Materiales base: ", base_materials.size())
	print("🔧 Recetas cargadas: ", recipes.size(), " combinaciones")
	print("\n📚 TODAS LAS RECETAS CARGADAS:")
	for key in recipes.keys():
		print("   ", key, " -> ", recipes[key])


## FALLBACK: Datos hardcodeados por si falla JSON
func _load_hardcoded_data() -> void:
	print("⚠️ Usando datos hardcodeados de respaldo")
	base_materials = ["Papel", "Metal", "Plastico", "Madera", "Vidrio"]
	recipes = {
		# Lata con etiqueta (Papel + Metal)
		"Papel+Metal": "Lata con etiqueta",
		"Metal+Papel": "Lata con etiqueta",
		
		# Botella con etiqueta (Papel + Vidrio)
		"Papel+Vidrio": "Botella con etiqueta",
		"Vidrio+Papel": "Botella con etiqueta",
		
		# Libro (Papel + Plastico)
		"Papel+Plastico": "Libro",
		"Plastico+Papel": "Libro",
		
		# Caja de cartón prensado (Papel + Madera)
		"Papel+Madera": "Caja de carton prensado",
		"Madera+Papel": "Caja de carton prensado",
		
		# Botella con tapa metálica (Metal + Vidrio)
		"Metal+Vidrio": "Botella con tapa metalica",
		"Vidrio+Metal": "Botella con tapa metalica",
		
		# Cable recubierto (Metal + Plastico)
		"Metal+Plastico": "Cable recubierto",
		"Plastico+Metal": "Cable recubierto",
		
		# Herramienta con mango de madera (Metal + Madera)
		"Metal+Madera": "Herramienta con mango de madera",
		"Madera+Metal": "Herramienta con mango de madera",
		
		# Botella con tapa plástica (Plastico + Vidrio)
		"Plastico+Vidrio": "Botella con tapa plastica",
		"Vidrio+Plastico": "Botella con tapa plastica",
		
		# Juguete (Plastico + Madera)
		"Plastico+Madera": "Juguete",
		"Madera+Plastico": "Juguete",
		
		# Ventana con marco de madera (Madera + Vidrio)
		"Madera+Vidrio": "Ventana con marco de madera",
		"Vidrio+Madera": "Ventana con marco de madera"
	}
	print("📦 Usando datos hardcodeados - TODAS las combinaciones cargadas")
	print("🔬 Total de recetas:", recipes.size() / 2, "(", recipes.size(), "combinaciones con orden)")


## Verifica si existe una receta válida con dos materiales
func check_recipe(material_a: String, material_b: String) -> String:
	var key1 = material_a + "+" + material_b
	var key2 = material_b + "+" + material_a
	
	print("\n🔍 VERIFICANDO RECETA:")
	print("   Material A: '", material_a, "'")
	print("   Material B: '", material_b, "'")
	print("   Clave 1: '", key1, "'")
	print("   Clave 2: '", key2, "'")
	print("   Total recetas disponibles: ", recipes.size())
	
	if recipes.has(key1):
		var resultado = recipes[key1]
		print("   ✅ RECETA ENCONTRADA (key1): ", resultado)
		return resultado
	elif recipes.has(key2):
		var resultado = recipes[key2]
		print("   ✅ RECETA ENCONTRADA (key2): ", resultado)
		return resultado
	else:
		print("   ❌ RECETA NO ENCONTRADA")
		print("   Primeras 5 recetas disponibles:")
		var count = 0
		for k in recipes.keys():
			if count < 5:
				print("      '", k, "' -> '", recipes[k], "'")
				count += 1
		return ""


## Verifica si un item es un material base (no un producto)
func is_base_material(item_type: String) -> bool:
	return item_type in base_materials


## Obtiene el color de un material o producto
func get_material_color(material_type: String) -> Color:
	return material_colors.get(material_type, Color.MAGENTA)


## Obtiene un material base aleatorio
func get_random_base_material() -> String:
	if base_materials.size() == 0:
		return "Papel"  # Default si está vacío
	return base_materials[randi() % base_materials.size()]


## Incrementa el contador de fusiones exitosas
func register_fusion() -> void:
	successful_fusions += 1
	print("Fusiones exitosas: ", successful_fusions)


## Registra una fusión completada en el array de objetivos
func register_completed_fusion(product: String) -> void:
	completed_fusions.append(product)
	print("🎯 Fusión registrada: ", product)
	print("📊 Fusiones completadas hasta ahora: ", completed_fusions)
	print("   Total de productos creados: ", completed_fusions.size())


## Muestra el contenido completo del array de fusiones
func show_completed_fusions() -> void:
	print("\n=== ARRAY DE FUSIONES COMPLETADAS ===")
	print("Total de fusiones: ", completed_fusions.size())
	if completed_fusions.is_empty():
		print("   (vacío)")
	else:
		for i in range(completed_fusions.size()):
			print("   [", i, "] ", completed_fusions[i])
	print("=====================================\n")


## Reinicia las estadísticas del nivel
func reset_stats() -> void:
	items_produced = 0
	successful_fusions = 0
	completed_fusions.clear()
	print("📊 Estadísticas reiniciadas")
	print("   Array de fusiones limpiado")
