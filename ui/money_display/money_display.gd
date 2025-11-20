extends CanvasLayer

## MoneyDisplay - Muestra el balance de monedas en pantalla

@onready var money_label: Label = $Panel/MoneyLabel

func _ready() -> void:
	# Conectar señal del EconomyManager
	if EconomyManager:
		EconomyManager.money_changed.connect(_on_money_changed)
		EconomyManager.purchase_failed.connect(_on_purchase_failed)
		
		# Actualizar display inicial
		_on_money_changed(EconomyManager.get_money())


func _on_money_changed(new_amount: int) -> void:
	if money_label:
		money_label.text = "🪙 " + str(new_amount)


func _on_purchase_failed(item_name: String, cost: int) -> void:
	# Feedback visual de compra fallida
	if money_label:
		money_label.modulate = Color(1, 0.3, 0.3, 1)  # Rojo
		await get_tree().create_timer(0.3).timeout
		money_label.modulate = Color(1, 1, 1, 1)  # Normal
	
	print("⚠️ No tienes suficiente dinero para ", item_name, ". Costo: ", cost)
