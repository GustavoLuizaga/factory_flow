extends Node

## GameManager - Singleton global
## Gestiona recetas, estado del juego y lógica compartida

# Diccionario de recetas: "Material1+Material2" -> "Producto"
var recipes: Dictionary = {
	"Papel+Metal": "Lata con etiqueta",
	"Metal+Papel": "Lata con etiqueta",
	"Metal+Plastico": "Cable recubierto",
	"Plastico+Metal": "Cable recubierto",
	"Plastico+Madera": "Juguete",
	"Madera+Plastico": "Juguete"
}

# Colores únicos para cada tipo de material/producto
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
var base_materials: Array[String] = ["Papel", "Metal", "Plastico", "Madera", "Vidrio"]

# Referencia al grid actual
var current_grid: Node = null

# Estadísticas del nivel
var items_produced: int = 0
var successful_fusions: int = 0


func _ready() -> void:
	print("GameManager inicializado")


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


## Obtiene el color de un material o producto
func get_material_color(material_type: String) -> Color:
	return material_colors.get(material_type, Color.MAGENTA)


## Obtiene un material base aleatorio
func get_random_base_material() -> String:
	return base_materials[randi() % base_materials.size()]


## Incrementa el contador de fusiones exitosas
func register_fusion() -> void:
	successful_fusions += 1
	print("Fusiones exitosas: ", successful_fusions)


## Reinicia las estadísticas del nivel
func reset_stats() -> void:
	items_produced = 0
	successful_fusions = 0
