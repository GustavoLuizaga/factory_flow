# res://autoload/progress_manager.gd
extends Node

# Archivo donde se guardan TODOS los perfiles en el dispositivo
const SAVE_PATH := "user://profiles.json"

# username -> diccionario de perfil
var profiles: Dictionary = {}
# nombre del usuario que está usando el juego ahora
var current_user: String = ""

func _ready() -> void:
	_load_profiles()


# CARGA / GUARDADO
func _load_profiles() -> void:
	# Si no existe el archivo aún, iniciamos vacío
	if not FileAccess.file_exists(SAVE_PATH):
		profiles = {}
		current_user = ""
		return

	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f:
		var d : Variant = JSON.parse_string(f.get_as_text())
		f.close()
		
		# Estructura esperada:
		# { "profiles": { ... }, "current_user": "nombre" }
		if typeof(d) == TYPE_DICTIONARY:
			var dict: Dictionary = d as Dictionary
			profiles = dict.get("profiles", {}) as Dictionary
			current_user = String(dict.get("current_user", ""))
		else:
			profiles = {}
			current_user = ""

func _save_profiles() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not f:
		return

	var data := {
		"profiles": profiles,
		"current_user": current_user
	}
	f.store_string(JSON.stringify(data))
	f.close()


# API DE PERFILES (HU)

# Registrar un nuevo usuario
func register_user(full_name: String, username: String, password: String) -> bool:
	full_name = full_name.strip_edges()
	username = username.strip_edges()
	password = password.strip_edges()
	
	# Validación básica: nombre vacío o duplicado
	if full_name == "" or username == "" or password == "":
		return false
	
	# Usuario ya existe
	if profiles.has(username):
		return false
	
	# Perfil que se guardará en el JSON
	var profile := {
		"username": username,
		"highest_unlocked": 1,  # siempre empieza en nivel 1
		"created_at": Time.get_unix_time_from_system(),
		"stats": {}
	}
	

	profiles[username] = profile
	current_user = username    # al registrarse, se deja logueado
	_save_profiles()
	return true

# Iniciar sesión con un usuario ya existente
#func login(username: String, password: String) -> bool:
#	username = username.strip_edges()
#	password = password.strip_edges()
#	
#	if not profiles.has(username):
#		return false

#	var profile: Dictionary = profiles[username]

	# Si el perfil tiene contraseña, comparamos
#	if profile.has("password"):
#		if String(profile["password"]) != password:
#			return false
#	else:
		# Perfiles antiguos sin contraseña: solo aceptar si password viene vacío
#		if password != "":
#			return false
	
#	current_user = username
#	_save_profiles()
#	return true

# Devuelve el perfil actual (o {} si no hay nadie logueado)
func get_current_profile() -> Dictionary:
	if current_user != "" and profiles.has(current_user):
		return profiles[current_user]
	return {}

# Lista de nombres de todos los usuarios guardados (para combobox si quieres)
#func get_all_usernames() -> Array[String]:
#	var arr: Array[String] = []
#	for name in profiles.keys():
#		arr.append(str(name))
#	return arr

# -------------------------
# PROGRESO POR USUARIO
# (MISMA API QUE TENÍAS)
# -------------------------

func unlock(level: int) -> void:
	# No hay usuario actual => no guardamos nada
	if current_user == "":
		return

	var profile : Dictionary = profiles.get(current_user, {}) as Dictionary
	var current_max := int(profile.get("highest_unlocked", 1))

	# Solo actualizamos si es un nivel más alto
	if level <= current_max:
		return

	profile["highest_unlocked"] = level
	profiles[current_user] = profile
	_save_profiles()

func is_unlocked(level: int) -> bool:
	if level <= 1:
		return true  # nivel 1 siempre disponible

	if current_user == "":
		# si no hay usuario, solo habilitamos el nivel 1
		return false

	var profile : Dictionary = profiles.get(current_user, {}) as Dictionary
	var current_max := int(profile.get("highest_unlocked", 1))
	return level <= current_max

func get_highest_unlocked() -> int:
	if current_user == "":
		return 1
	var profile : Dictionary = profiles.get(current_user, {}) as Dictionary
	return int(profile.get("highest_unlocked", 1))

# ¿Hay un usuario actual válido?
func has_current_user() -> bool:
	return current_user != "" and profiles.has(current_user)


# Crea o selecciona un usuario simple (solo username).
# - Si username viene vacío, genera uno por defecto (Jugador_001, Jugador_002, ...).
# - Si ya existe, solo lo selecciona.
# - Si no existe, lo crea con valores por defecto.
# Devuelve SIEMPRE el nombre final usado.
func ensure_simple_user(username: String) -> String:
	username = username.strip_edges()

	# 1) Si NO escribe nada -> generamos uno tipo "Jugador_001"
	if username == "":
		var base := "Jugador"
		var n := profiles.size() + 1
		var candidate := "%s_%03d" % [base, n]

		# Asegurarnos de no repetir nombre
		while profiles.has(candidate):
			n += 1
			candidate = "%s_%03d" % [base, n]

		# Crear perfil nuevo mínimo
		var profile := {
			"username": candidate,
			"created_at": Time.get_unix_time_from_system(),
			"highest_unlocked": 1,
			"stats": {}
		}
		profiles[candidate] = profile
		current_user = candidate
		_save_profiles()
		return candidate

	# 2) Si escribió algo y ya existe -> solo seleccionarlo
	if profiles.has(username):
		current_user = username
		_save_profiles()
		return username

	# 3) Si escribió algo nuevo -> crearlo
	var new_profile := {
		"username": username,
		"created_at": Time.get_unix_time_from_system(),
		"highest_unlocked": 1,
		"stats": {}
	}
	profiles[username] = new_profile
	current_user = username
	_save_profiles()
	return username
