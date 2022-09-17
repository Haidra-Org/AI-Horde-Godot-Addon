extends VBoxContainer

onready var stable_horde_client = $"%StableHordeClient"
onready var grid = $"%Grid"
onready var line_edit = $"%LineEdit"



func _ready():
	stable_horde_client.connect("images_generated",self, "_on_images_generated")

func _on_Button_pressed():
	stable_horde_client.generate(line_edit.text)

func _on_images_generated(textures_list):
	for texture in textures_list:
		var tr = TextureRect.new()
		tr.rect_min_size = Vector2(128,128)
		tr.expand = true
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.texture = texture
		grid.add_child(tr)


func _on_RichTextLabel_meta_clicked(meta):
	OS.shell_open("https://github.com/db0/Stable-Horde-Client")
