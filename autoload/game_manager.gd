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
	load_data_from_database()


## Carga elementos y combinaciones desde SQLite
func load_data_from_database() -> void:
	if not ClassDB.class_exists("SQLite"):
		push_error("❌ SQLite no disponible, usando datos hardcodeados")
		_load_hardcoded_data()
		return
	
	db = SQLite.new()
	db.path = DB_PATH
	
	if not db.open_db():
		push_error("❌ No se pudo abrir la base de datos, usando datos hardcodeados")
		_load_hardcoded_data()
		return
	
	print("✅ Base de datos abierta:", DB_PATH)
	
	# Cargar solo los elementos base (id <= 5: Papel, Metal, Plastico, Madera, Vidrio)
	db.query("SELECT nombre FROM elementos WHERE id_elemento <= 5")
	var elementos = db.query_result
	
	if elementos and len(elementos) > 0:
		base_materials.clear()
		for row in elementos:
			base_materials.append(row["nombre"])
		print("📦 Cargados", len(base_materials), "materiales base:", base_materials)
	else:
		push_error("❌ No se pudieron cargar elementos, usando hardcoded")
		_load_hardcoded_data()
		db.close_db()
		return
	
	# Cargar combinaciones
	db.query("""
		SELECT 
			e1.nombre as elemento1, 
			e2.nombre as elemento2, 
			e3.nombre as resultado
		FROM combinaciones c
		JOIN elementos e1 ON c.elemento1 = e1.id_elemento
		JOIN elementos e2 ON c.elemento2 = e2.id_elemento
		JOIN elementos e3 ON c.resultado = e3.id_elemento
	""")
	var combinaciones = db.query_result
	
	if combinaciones and len(combinaciones) > 0:
		recipes.clear()
		for row in combinaciones:
			var elem1 = row["elemento1"]
			var elem2 = row["elemento2"]
			var resultado = row["resultado"]
			
			recipes[elem1 + "+" + elem2] = resultado
			recipes[elem2 + "+" + elem1] = resultado
		
		print("🔬 Cargadas", len(combinaciones), "combinaciones:")
		for key in recipes.keys():
			print("   ", key, " -> ", recipes[key])
	else:
		push_error("❌ No se pudieron cargar recetas, usando hardcoded")
		_load_hardcoded_data()
	
	db.close_db()


## Datos hardcodeados de respaldo (TODAS las combinaciones posibles)
func _load_hardcoded_data() -> void:
	base_materials = ["Papel", "Metal", "Plastico", "Madera", "Vidrio"]
	recipes = {
		# Lata con etiqueta (Papel + Metal)
		"Papel+Metal": "Lata con etiqueta",
		"Metal+Papel": "Lata con etiqueta",
		
		# Botella con etiqueta (Papel + Vidrio)
		"Papel+Vidrio": "Botella con etiqueta",
		"Vidrio+Papel": "Botella con etiqueta",
		
		# Libro (Papel + Papel)
		"Papel+Papel": "Libro",
		
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
	
	print("🔍 Buscando receta: ", key1)
	print("   Recetas disponibles: ", recipes.size(), " combinaciones")
	
	if recipes.has(key1):
		print("   ✅ Receta encontrada: ", recipes[key1])
		return recipes[key1]
	elif recipes.has(key2):
		print("   ✅ Receta encontrada: ", recipes[key2])
		return recipes[key2]
	else:
		print("   ❌ Receta NO encontrada")
		print("   Recetas cargadas:", recipes.keys())
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
