extends Control

onready var http_request = $"%HTTPRequest"
var return_imgs
onready var texture_rect = $TextureRect

func _ready():
	var imgen_params = {
		"n": 1,
		"width": 64*10,
		"height":64*6,
		"steps": 5,
		# You can put extra SD webui params here if you wish
	}
	var submit_dict = {
		"prompt": "a swarm of incredibly cute stable robots, intricate, highly detailed, artstation, concept art, smooth, sharp focus, colorful scene,  in the style of don bluth, greg rutkowski, disney, and hans zatzka",
		"api_key": "0000000000",
		"params": imgen_params
	}
	var body = to_json(submit_dict)
	print_debug(body)
	var headers = ["Content-Type: application/json"]
	var error = http_request.request("https://stablehorde.net/api/v1/generate/sync", headers, false, HTTPClient.METHOD_POST, body)
	print_debug(error)


# warning-ignore:unused_argument
func _on_HTTPRequest_request_completed(result, response_code, headers, body):
# warning-ignore:unused_variable
	var image = Image.new()
	print_debug(response_code)
	print_debug(headers)
	print_debug(body.size())
	return_imgs = parse_json(body.get_string_from_utf8())


func _on_Button_pressed():
	print_debug(http_request.get_http_client_status())
	for img_dict in return_imgs:
		var b64img = img_dict["img"]
		var base64_bytes = Marshalls.base64_to_raw(b64img)
		var image = Image.new()
		var error = image.load_webp_from_buffer(base64_bytes)
		if error != OK:
			push_error("Couldn't load the image.")

		var texture = ImageTexture.new()
		texture.create_from_image(image)

		# Display the image in a TextureRect node.
		texture_rect.texture = texture
