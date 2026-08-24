extends Timer


func _on_timeout() -> void:
	DisplayServer.clipboard_set("Test")
	OS.shell_open("https://www.google.de")
	get_tree().quit()
