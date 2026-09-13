extends Control
class_name QR_Code_UI_Controller

signal open_link
signal copy_content

@onready var b_content: Button = %B_Content
@onready var b_copy: Button = %B_Copy

@export var i_text : CompressedTexture2D
@export var i_web : CompressedTexture2D

var isLink := true 

func set_qr_code_ui_content(_isLink : bool, content: String) -> void:
	
	isLink = _isLink
	
	if (isLink):
		b_content.icon = i_web
	else:
		b_content.icon = i_text
	
	b_content.text = content

func _on_b_content_pressed() -> void:
	if (isLink):
		open_link.emit()
	else:
		on_copy_content()


func _on_b_copy_pressed() -> void:
	on_copy_content()


func on_copy_content() -> void:
	copy_content.emit()
	
	b_copy.text = "copied"
	await get_tree().create_timer(1).timeout
	b_copy.text = ""
