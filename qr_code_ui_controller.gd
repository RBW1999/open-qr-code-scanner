extends VBoxContainer

signal open_link
signal copy_content


func _on_open_link_pressed() -> void:
	open_link.emit()
