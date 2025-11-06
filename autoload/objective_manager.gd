# res://autoload/objective_manager.gd
extends Node
# Autoload: Name: ObjectiveManager

#Señales para la UI
signal objective_updated(id_obj: String, current: int, target: int) #cambio incremental del progreso
signal objective_completed(id_obj: String) #objetivo alcanzado por primera vez
signal all_objectives_completed() #todos los objetivos del nivel listos

#Diccionarios creados vacíos inicialmente
var elem_id_to_name: Dictionary = {}     # (id de los elementos)int -> String
var elem_name_to_id: Dictionary = {}     # String -> int
var recipes: Array[Dictionary] = []      # [{e1:int,e2:int,res:int}], almacena todas las conbinaciones
var objectives: Dictionary = {}          # id:String -> {id,title,target,current,element_id,done:bool}

# Nivel activo (se puede cambiar el nivel desde fuera)
@export var current_level_number: int = 1


func _ready() -> void:
	print("[ObjectiveManager] Inicializando...")
	print("[ObjectiveManager] OS:", OS.get_name())
	
	# Usar JSON en todas las plataformas
	_load_from_json()
	_load_level_objectives_from_json(current_level_number)
	_check_all_done()
	

## Cargar datos desde JSON
func _load_from_json() -> void:
	var json_path = "res://database/game_data.json"
	
	if not FileAccess.file_exists(json_path):
		print("[ObjectiveManager] ❌ JSON no encontrado, usando hardcoded")
		_load_hardcoded_data()
		return
	
	var file = FileAccess.open(json_path, FileAccess.READ)
	if not file:
		print("[ObjectiveManager] ❌ Error al abrir JSON")
		_load_hardcoded_data()
		return
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_text)
	
	if error != OK:
		print("[ObjectiveManager] ❌ Error al parsear JSON")
		_load_hardcoded_data()
		return
	
	var data = json.data
	print("[ObjectiveManager] ✅ JSON cargado")
	
	# Limpiar
	elem_id_to_name.clear()
	elem_name_to_id.clear()
	recipes.clear()
	
	# Cargar elementos
	if data.has("elementos"):
		for elem in data["elementos"]:
			var id = elem["id"]
			var nombre = elem["nombre"]
			elem_id_to_name[id] = nombre
			elem_name_to_id[nombre] = id
	
	# Cargar combinaciones
	if data.has("combinaciones"):
		for combo in data["combinaciones"]:
			recipes.append({
				"e1": combo["elemento1"],
				"e2": combo["elemento2"],
				"res": combo["resultado"]
			})
	
	print("[ObjectiveManager] 📦 Elementos:", elem_id_to_name.size())
	print("[ObjectiveManager] 🔧 Recetas:", recipes.size())


## Cargar objetivos de nivel desde JSON
func _load_level_objectives_from_json(nivel_num: int) -> void:
	var json_path = "res://database/game_data.json"
	
	if not FileAccess.file_exists(json_path):
		_load_level_objectives_hardcoded(nivel_num)
		return
	
	var file = FileAccess.open(json_path, FileAccess.READ)
	if not file:
		_load_level_objectives_hardcoded(nivel_num)
		return
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_text)
	
	if error != OK:
		_load_level_objectives_hardcoded(nivel_num)
		return
	
	var data = json.data
	objectives.clear()
	
	if data.has("niveles"):
		for nivel in data["niveles"]:
			if nivel["numero"] == nivel_num:
				for elem_id in nivel["objetivos"]:
					var elem_name = elem_id_to_name.get(elem_id, "Desconocido")
					var obj_id = "obj_" + str(elem_id)
					
					objectives[obj_id] = {
						"id": obj_id,
						"title": elem_name,
						"target": 1,
						"current": 0,
						"element_id": elem_id,
						"done": false
					}
				
				print("[ObjectiveManager] 🎯 Objetivos nivel ", nivel_num, ": ", objectives.size())
				return
	
	print("[ObjectiveManager] ⚠️ Nivel no encontrado, usando hardcoded")
	_load_level_objectives_hardcoded(nivel_num)


## FALLBACK: Datos hardcodeados por si falla JSON
func _load_hardcoded_data() -> void:
	print("[ObjectiveManager] ⚠️ Usando datos hardcodeados de respaldo")
	
	elem_id_to_name = {
		1: "Papel",
		2: "Metal",
		3: "Plastico",
		4: "Madera",
		5: "Vidrio",
		6: "Lata con etiqueta",
		7: "Botella con etiqueta",
		8: "Libro",
		9: "Caja de carton prensado",
		10: "Botella con tapa metalica",
		11: "Cable recubierto",
		12: "Herramienta con mango de madera",
		13: "Botella con tapa plastica",
		14: "Juguete",
		15: "Ventana con marco de madera"
	}
	
	elem_name_to_id.clear()
	for id in elem_id_to_name.keys():
		elem_name_to_id[elem_id_to_name[id]] = id
	
	print("[ObjectiveManager] ✅ Cargados", elem_id_to_name.size(), "elementos")


func _load_level_objectives_hardcoded(nivel_num: int) -> void:
	objectives.clear()
	
	if nivel_num == 1:
		# Nivel 1: Lata con etiqueta, Botella con etiqueta, Libro, Caja de carton prensado, Botella con tapa metalica
		var level_objectives = [6, 7, 8, 9, 10]
		
		for eid in level_objectives:
			var name = elem_id_to_name.get(eid, "???")
			var id_str = "make_%d" % eid
			objectives[id_str] = {
				"id": id_str,
				"title": name,
				"target": 1,
				"current": 0,
				"element_id": eid,
				"done": false
			}
			print("[OBJ] hardcoded loaded:", name)
	
	print("[ObjectiveManager] ✅ Nivel", nivel_num, "con", objectives.size(), "objetivos")


#     API PARA LA UI
# =========================
#Creamos un arreglo de diccionarios para que la HUD pinte cada objetivo
func get_all_for_ui() -> Array[Dictionary]:
	var arr: Array[Dictionary] = []
	for k in objectives.keys():
		var o = objectives[k]
		arr.append({
			"title": String(o.title),  # si no quieres títulos en tu HUD
			"target": int(o.target),
			"current": int(o.current),
			"icon_tex": _icon_for(int(o.element_id)) as Texture2D
		})
	return arr

#Traducción del elemento id a un icono (Texture2D)
func _icon_for(element_id: int) -> Texture2D:
	# Mapeo directo por ID de elemento
	match element_id:
		6:  # Lata con etiqueta
			return load("res://assets/images/Lata_con_etiqueta.png") as Texture2D
		7:  # Botella con etiqueta
			return load("res://assets/images/Botella_con_etiqueta.png") as Texture2D
		8:  # Libro
			return load("res://assets/images/Libro.png") as Texture2D
		9:  # Caja de carton prensado
			return load("res://assets/images/Caja_de_carton_prensado.png") as Texture2D
		10: # Botella con tapa metalica
			return load("res://assets/images/Botella_con_tapa_metalica.png") as Texture2D
		11: # Cable recubierto
			return load("res://assets/images/Cable_recubierto.png") as Texture2D
		12: # Herramienta con mango de madera
			return load("res://assets/images/Herramienta_con_mango_de_madera.png") as Texture2D
		13: # Botella con tapa plastica
			return load("res://assets/images/Botella_con_tapa_plastica.png") as Texture2D
		14: # Juguete
			return load("res://assets/images/Juguete.png") as Texture2D
		15: # Ventana con marco de madera
			return load("res://assets/images/Ventana_con_marco_de_madera.png") as Texture2D
		##De momento las la img por defecto esta ventana
		16: # Pack de bebidas reciclado
			return load("res://assets/images/subFusiones/Pack_de_bebidas_reciclado.png") as Texture2D
		17: # Biblioteca reciclada
			return load("res://assets/images/subFusiones/Biblioteca_reciclada.png") as Texture2D
		18: # Colección de envases
			return load("res://assets/images/subFusiones/Coleccion_de_envases.png") as Texture2D
		19: # Kit electrico reciclado
			return load("res://assets/images/subFusiones/Kit_electrico_reciclado.png") as Texture2D
		20: # Botella de colección
			return load("res://assets/images/subFusiones/Botella_de_coleccion.png") as Texture2D
		21: # Invernadero basico
			return load("res://assets/images/subFusiones/Invernadero_basico.png") as Texture2D
		22: # E-book
			return load("res://assets/images/subFusiones/E_book.png") as Texture2D
		23: # Botella con sorpresa
			return load("res://assets/images/subFusiones/Botella_con_sorpresa.png") as Texture2D
		24: # Casa infantil de juguetes
			return load("res://assets/images/subFusiones/Casa_infantil_de_juguetes.png") as Texture2D
		_:
			var name = elem_id_to_name.get(element_id, "Desconocido")
			print("⚠️ No se encontró imagen para elemento ID: ", element_id, " (", name, ")")
			return null


#      PROGRESO / ESTADO
# =========================
#Incrementa el progreso del objetivo cuyo element_id coincide
func inc_by_element_id(element_id: int, amt: int = 1) -> void:
	# Sumar progreso cuando se produce un elemento objetivo, atm (cantidad)
	for k in objectives.keys():
		var o: Dictionary = objectives[k]
		if int(o.element_id) == element_id:
			_add_progress(String(k), amt)
			return

#Normaliza texto para comparar nombres
static func _norm(s: String) -> String:
	return s.to_lower().replace("á","a").replace("é","e").replace("í","i").replace("ó","o").replace("ú","u")

#Incrementa progreso buscando por nombre de producto.
func inc_by_element_name(name: String, amt: int = 1) -> void:
	var n = _norm(name)
	for k in objectives.keys():
		var o = objectives[k]
		if _norm(String(o.title)) == n:
			_add_progress(String(k), amt) # <- forzar String
			return

#Nucleo de actualización y señalización
func _add_progress(id_obj_dic: String, amt: int) -> void:
	if not objectives.has(id_obj_dic):
		return
	var o = objectives[id_obj_dic]
	if o.done:
		return
		
	#atm representa cuanto se va sumar al progreso actual del objetivo
	o.current = clamp(o.current + amt, 0, o.target) #Suma y limita
	objectives[id_obj_dic] = o
	print("[OBJ] progress:", o.title, o.current, "/", o.target)

	#Emitir señales usando siempre String
	var id_str = String(id_obj_dic)
	objective_updated.emit(id_str, o.current, o.target)

	if o.current >= o.target and not o.done:
		o.done = true
		objectives[id_obj_dic] = o
		print("[OBJ] completed:", o.title)
		objective_completed.emit(id_str)
		_check_all_done()

#Setter directo con mismas validaciones y señales
func _set_value(id_objectives_dic: String, valor_asignado: int) -> void:
	if not objectives.has(id_objectives_dic):
		return
	var o: Dictionary = objectives[id_objectives_dic]
	o.current = clamp(valor_asignado, 0, int(o.target))
	objectives[id_objectives_dic] = o

	objective_updated.emit(id_objectives_dic, int(o.current), int(o.target))

	if int(o.current) >= int(o.target) and not bool(o.done):
		o.done = true
		objectives[id_objectives_dic] = o
		objective_completed.emit(id_objectives_dic)
		_check_all_done()

#Comprueba si todos los objetivos están completos
func _check_all_done() -> void:
	for k in objectives.keys():
		var o: Dictionary = objectives[k]
		if not bool(o.done):
			return
	all_objectives_completed.emit()

#Reinicia y carga objetivos del nivel dado
func reset_for_level(nivel_num: int) -> void:
	print("[ObjectiveManager] 🔄 Reset nivel:", nivel_num)
	
	# Recargar desde JSON
	if elem_id_to_name.is_empty():
		_load_from_json()
	
	objectives.clear()
	_load_level_objectives_from_json(nivel_num)
	_check_all_done()
	
	print("[ObjectiveManager] ✅ Reset completado")
