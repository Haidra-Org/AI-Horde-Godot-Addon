extends VBoxContainer

@onready var stable_horde_client = $"%StableHordeClient"
@onready var grid = $"%Grid"
@onready var line_edit = $"%LineEdit"
@onready var status = $"%Status"


func _ready():
	stable_horde_client.connect("images_generated", Callable(self, "_on_images_generated"))
	stable_horde_client.connect("image_processing", Callable(self, "_on_image_process_update"))
	
func _on_Button_pressed():
	if line_edit.text != '':
		stable_horde_client.prompt = line_edit.text
	else:
		stable_horde_client.prompt = line_edit.placeholder_text
	stable_horde_client.generate()

func _on_images_generated(textures_list):
	status.text = "Status"
	for texture in textures_list["image_textures"]:
		var tr = TextureRect.new()
		tr.custom_minimum_size = Vector2(128, 128)
		tr.ignore_texture_size = true
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.texture = texture
		grid.add_child(tr)

func _on_image_process_update(stats: Dictionary) -> void:
#	print_debug(stats)
	status.text = str(stats)

func _on_rich_text_label_meta_clicked(meta):
	# warning-ignore:return_value_discarded
	OS.shell_open("https://github.com/db0/Lucid-Creations")
