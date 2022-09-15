extends VBoxContainer

onready var stable_horde_client = $"%StableHordeClient"
onready var grid = $"%Grid"



func _ready():
	stable_horde_client.connect("images_generated",self, "_on_images_generated")

func _on_Button_pressed():
	stable_horde_client.generate()

func _on_images_generated(textures_list):
	for texture in textures_list:
		var tr = TextureRect.new()
		tr.rect_min_size = Vector2(128,128)
		tr.expand = true
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.texture = texture
		grid.add_child(tr)
