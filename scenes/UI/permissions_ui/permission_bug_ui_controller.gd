extends PanelContainer

@onready var quit_button: Button = %Button

func _ready() -> void:
	quit_button.pressed.connect(_on_quit_btn_pressed)
	

func _on_quit_btn_pressed() -> void :
	get_tree().quit()
