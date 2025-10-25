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
		push_error("❌ No se pudo abrir la base de datos")
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
		
		print("🔬 Cargadas", len(combinaciones), "combinaciones")
	
	db.close_db()


## Datos hardcodeados de respaldo
func _load_hardcoded_data() -> void:
	base_materials = ["Papel", "Metal", "Plastico", "Madera", "Vidrio"]
	recipes = {
		"Papel+Metal": "Lata con etiqueta",
		"Metal+Papel": "Lata con etiqueta", 
		"Metal+Plastico": "Cable recubierto",
		"Plastico+Metal": "Cable recubierto",
		"Plastico+Madera": "Juguete",
		"Madera+Plastico": "Juguete"
	}
	print("📦 Usando datos hardcodeados")


## Verifica si existe una receta válida con dos materiales
func check_recipe(material_a: String, material_b: String) -> String:
	var key1 = material_a + "+" + material_b
	var key2 = material_b + "+" + material_a
	
	if recipes.has(key1):
		return recipes[key1]
	elif recipes.has(key2):
		return recipes[key2]
	else:
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


## Reinicia las estadísticas del nivel
func reset_stats() -> void:
	items_produced = 0
	successful_fusions = 0
