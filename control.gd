extends Control
@onready var texture_rect: TextureRect = $TextureRect


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var image = Image.new()
	image.load("res://addons/stable_horde_client/icon.png")
	var imaget = ImageTexture.new()
	texture_rect.texture = imaget.create_from_image(image)
	print_debug(texture_rect.texture)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
