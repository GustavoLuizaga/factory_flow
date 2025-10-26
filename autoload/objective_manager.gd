# res://autoload/objective_manager.gd
extends Node
# Autoload: Project Settings → Autoload → Path: este archivo, Name: ObjectiveManager

# ---- Señales para la UI ----
signal objective_updated(id: String, current: int, target: int)
signal objective_completed(id: String)
signal all_objectives_completed()

var db: SQLite

# ---- Config DB ----
const DB_PATH: String = "res://database/factory_db.db" # Ajusta la ruta si tu .db está en otra carpeta

# Instancia de godot-sqlite (addon). Tipado ancho para evitar "Variant".
var sqlite: Object = null

# ---- Cachés en memoria ----
var elem_id_to_name: Dictionary = {}     # int -> String
var elem_name_to_id: Dictionary = {}     # String -> int
var recipes: Array[Dictionary] = []      # [{e1:int,e2:int,res:int}]
var objectives: Dictionary = {}          # id:String -> {id,title,target,current,element_id,done:bool}

# Nivel activo (si manejas varios niveles, cámbialo desde fuera)
@export var current_level_number: int = 1


func _ready() -> void:
	_open_db()
	if db == null:
		return
	_load_elements()
	_load_recipes()
	_load_level_objectives(current_level_number)
	_check_all_done()
	

# =========================
#         DB
# =========================
func _open_db() -> void:
	# Si el plugin está activo, esta clase ya existe
	if not ClassDB.class_exists("SQLite"):
		push_error("El plugin Godot SQLite no está activo o no fue cargado correctamente.")
		return

	db = SQLite.new()
	db.path = DB_PATH  # usa la ruta real donde guardaste tu DB
	if not db.open_db():
		push_error("No se pudo abrir DB: " + DB_PATH)
		db = null

func _q(sql: String) -> Array:
	# Helper de consulta.
	if db == null:
		push_error("DB no inicializada")
		return []
	var ok := db.query(sql)
	if not ok or db.query_result == null:
		return []
	return db.query_result


# =========================
#      CARGAS INICIALES
# =========================
func _load_elements() -> void:
	elem_id_to_name.clear()
	elem_name_to_id.clear()
	var rows: Array[Dictionary] = _q("SELECT id_elemento, nombre FROM elementos")
	for r in rows:
		var id_el: int = int(r.id_elemento)
		var nom: String = String(r.nombre)
		elem_id_to_name[id_el] = nom
		elem_name_to_id[nom] = id_el
	print("[BD] elementos:", elem_id_to_name)

func _load_recipes() -> void:
	recipes.clear()
	var rows: Array[Dictionary] = _q("SELECT elemento1, elemento2, resultado FROM combinaciones")
	for r in rows:
		recipes.append({
			"e1": int(r.elemento1),
			"e2": int(r.elemento2),
			"res": int(r.resultado)
		})

func _load_level_objectives(nivel_num: int) -> void:
	# 1) Buscar id_nivel por número de nivel
	var niv: Array[Dictionary] = _q("SELECT id_nivel FROM nivel WHERE numero_nivel = %d" % nivel_num)
	if niv.is_empty():
		return
	var id_nivel: int = int(niv[0].id_nivel)

	# 2) Cargar objetivos: tabla objetivo_elemento (target implícito = 1)
	objectives.clear()
	var rows: Array[Dictionary] = _q("SELECT id_elemento FROM objetivo_elemento WHERE id_nivel = %d" % id_nivel)
	for r in rows:
		var eid: int = int(r.id_elemento)
		var name: String = String(elem_id_to_name.get(eid, "???"))
		var id_str: String = "make_%d" % eid
		objectives[id_str] = {
			"id": id_str,
			"title": name,       # Texto opcional para HUD
			"target": 1,         # La tabla no define cantidades → 1 por defecto
			"current": 0,
			"element_id": eid,   # Referencia al producto objetivo
			"done": false
		}
	# DEBUG: listar lo cargado
	for k in objectives.keys():
		var o: Dictionary = objectives[k]
		print("[OBJ] loaded:", o.title)


# =========================
#     API PARA LA UI
# =========================
func get_all_for_ui() -> Array[Dictionary]:
	# Devuelve objetos listos para tu Hub: textura ya resuelta.
	var arr: Array[Dictionary] = []
	for k in objectives.keys():
		var o = objectives[k]
		arr.append({
			"title": "",  # si no quieres títulos en tu HUD
			"target": int(o.target),
			"current": int(o.current),
			"icon_tex": _icon_for(int(o.element_id)) as Texture2D
		})
	return arr

func _icon_for(element_id: int) -> Texture2D:
	# Mapea elemento → icono. Ajusta nombres/rutas a tu proyecto.
	var name: String = String(elem_id_to_name.get(element_id, ""))
	match name:
		"Lata con etiqueta":
			return load("res://ui/img/lata.png") as Texture2D
		"Botella con etiqueta":
			return load("res://ui/img/botella.png") as Texture2D
		"Libro":
			return load("res://ui/img/factory.png") as Texture2D
		"Caja de cartón prensado":
			return load("res://ui/img/caja.png") as Texture2D
		"Botella con tapa metálica":
			return load("res://ui/img/botella.png") as Texture2D
		_:
			return null


# =========================
#      PROGRESO / ESTADO
# =========================
func inc_by_element_id(element_id: int, amt: int = 1) -> void:
	# Sumar progreso cuando se produce un elemento objetivo (p.ej., al completar fusión)
	for k in objectives.keys():
		var o: Dictionary = objectives[k]
		if int(o.element_id) == element_id:
			_add_progress(String(k), amt)
			return

# objective_manager.gd
static func _norm(s: String) -> String:
	return s.to_lower().replace("á","a").replace("é","e").replace("í","i").replace("ó","o").replace("ú","u")

func inc_by_element_name(name: String, amt: int = 1) -> void:
	var n = _norm(name)
	for k in objectives.keys():
		var o = objectives[k]
		if _norm(String(o.title)) == n:
			_add_progress(String(k), amt) # <- forzar String
			return


func _add_progress(id: String, amt: int) -> void:
	if not objectives.has(id):
		return
	var o = objectives[id]
	if o.done:
		return

	o.current = clamp(o.current + amt, 0, o.target)
	objectives[id] = o
	print("[OBJ] progress:", o.title, o.current, "/", o.target)

	# --- emitir señales usando siempre String ---
	var id_str = String(id)
	objective_updated.emit(id_str, o.current, o.target)

	if o.current >= o.target and not o.done:
		o.done = true
		objectives[id] = o
		print("[OBJ] completed:", o.title)
		objective_completed.emit(id_str)
		_check_all_done()

func _set_value(id: String, v: int) -> void:
	if not objectives.has(id):
		return
	var o: Dictionary = objectives[id]
	o.current = clamp(v, 0, int(o.target))
	objectives[id] = o

	objective_updated.emit(id, int(o.current), int(o.target))

	if int(o.current) >= int(o.target) and not bool(o.done):
		o.done = true
		objectives[id] = o
		objective_completed.emit(id)
		_check_all_done()

func _check_all_done() -> void:
	for k in objectives.keys():
		var o: Dictionary = objectives[k]
		if not bool(o.done):
			return
	all_objectives_completed.emit()

func reset_for_level(nivel_num: int) -> void:
	# Asegura catálogos cargados
	if elem_id_to_name.is_empty():
		_load_elements()

	# Reinicia y carga objetivos del nivel
	objectives.clear()
	_load_level_objectives(nivel_num)

	# Opcional: log
	print("[OBJ] objetivos reiniciados para nivel:", nivel_num)
