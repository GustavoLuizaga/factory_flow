extends Node

## EconomyManager - Sistema de economía para los niveles
## Gestiona monedas, costos y reembolsos
## Configuración cargada desde game_data.json

signal money_changed(new_amount: int)
signal purchase_failed(item_name: String, cost: int)

# Balance actual de monedas
var current_money: int = 0

# Configuración de costos por tipo de entidad (se carga del JSON)
var entity_costs: Dictionary = {}

# Porcentaje de reembolso al borrar (0-100, se carga del JSON)
var refund_percentage: int = 60

# Nivel actual
var current_level: int = 0


func _ready() -> void:
	print("💰 EconomyManager inicializado")


## Inicializa el balance y configuración de economía para un nivel específico
func initialize_for_level(level_number: int) -> void:
	current_level = level_number
	
	# Cargar configuración del JSON
	var level_config = _load_level_config(level_number)
	
	if level_config == null:
		print("💰 Nivel ", level_number, ": Sin sistema de economía")
		current_money = 0
		entity_costs.clear()
		money_changed.emit(current_money)
		return
	
	# Configurar monedas iniciales
	current_money = level_config.get("monedas_iniciales", 0)
	
	# Configurar costos
	var economia = level_config.get("economia", {})
	if economia.is_empty():
		print("💰 Nivel ", level_number, ": Sin configuración de economía")
		entity_costs.clear()
	else:
		entity_costs = {
			"conveyor": economia.get("cinta", 0),
			"fusion_machine": economia.get("maquina", 0),
			"super_fusion_machine": economia.get("super_maquina", 0)
		}
		refund_percentage = economia.get("reembolso_porcentaje", 60)
		
		print("💰 Configuración de economía cargada:")
		print("   - Monedas iniciales: ", current_money)
		print("   - Cinta: ", entity_costs["conveyor"], " monedas")
		print("   - Máquina: ", entity_costs["fusion_machine"], " monedas")
		print("   - Super-Máquina: ", entity_costs["super_fusion_machine"], " monedas")
		print("   - Reembolso: ", refund_percentage, "%")
	
	money_changed.emit(current_money)


## Carga la configuración de un nivel desde el JSON
func _load_level_config(level_number: int) -> Dictionary:
	var json_path = "res://database/game_data.json"
	
	if not FileAccess.file_exists(json_path):
		print("❌ JSON no encontrado")
		return {}
	
	var file = FileAccess.open(json_path, FileAccess.READ)
	if not file:
		print("❌ Error al abrir JSON")
		return {}
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_text)
	
	if error != OK:
		print("❌ Error al parsear JSON")
		return {}
	
	var data = json.data
	
	# Buscar configuración del nivel
	if data.has("niveles"):
		for nivel in data["niveles"]:
			if nivel.get("numero") == level_number:
				return nivel
	
	return {}


## Obtiene el balance actual
func get_money() -> int:
	return current_money


## Obtiene el costo de una entidad
func get_cost(entity_type: String) -> int:
	return entity_costs.get(entity_type, 0)


## Intenta comprar una entidad
func try_purchase(entity_type: String) -> bool:
	var cost = get_cost(entity_type)
	
	if cost == 0:
		# Sin costo, siempre permitir
		return true
	
	if current_money >= cost:
		current_money -= cost
		print("💸 Compra: ", entity_type, " por ", cost, " monedas. Balance: ", current_money)
		money_changed.emit(current_money)
		return true
	else:
		print("❌ Fondos insuficientes para ", entity_type, ". Costo: ", cost, ", Balance: ", current_money)
		purchase_failed.emit(entity_type, cost)
		return false


## Reembolsa dinero al borrar una entidad
func refund(entity_type: String) -> void:
	var cost = get_cost(entity_type)
	
	if cost == 0:
		# Sin costo, no hay reembolso
		return
	
	var refund_amount = int(cost * refund_percentage / 100.0)
	current_money += refund_amount
	print("💵 Reembolso: ", entity_type, " por ", refund_amount, " monedas (", refund_percentage, "%). Balance: ", current_money)
	money_changed.emit(current_money)


## Añade monedas (útil para bonificaciones)
func add_money(amount: int) -> void:
	current_money += amount
	print("💰 +", amount, " monedas. Balance: ", current_money)
	money_changed.emit(current_money)


## Reinicia el balance
func reset() -> void:
	current_money = 0
	entity_costs.clear()
	money_changed.emit(current_money)
	print("💰 Balance reiniciado")


## Verifica si hay suficiente dinero
func can_afford(entity_type: String) -> bool:
	var cost = get_cost(entity_type)
	return cost == 0 or current_money >= cost


## Verifica si el nivel actual tiene economía activa
func has_economy() -> bool:
	return not entity_costs.is_empty()
