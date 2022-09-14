extends HTTPRequest

export(String) var prompt = "A horde of cute blue robots with gears on their head"
export(String) var api_key := '0000000000'
export(int) var amount := 1
export(int,64,1024,64) var width := 512
export(int,64,1024,64) var length := 512
export(int,1,200) var steps := 50

var image_textures := []

func _ready():
	connect("request_completed",self,"_on_request_completed")
	var imgen_params = {
		"n": amount,
		"width": width,
		"height": length,
		"steps": steps,
		# You can put extra SD webui params here if you wish
	}
	var submit_dict = {
		"prompt": prompt,
		"api_key": api_key,
		"params": imgen_params
	}
	var body = to_json(submit_dict)
	print_debug(body)
	var headers = ["Content-Type: application/json"]
	var error = request("https://stablehorde.net/api/v1/generate/sync", headers, false, HTTPClient.METHOD_POST, body)
	if error != OK:
		push_error("Something went wrong when submitting the stable horde request")

# warning-ignore:unused_argument
func _on_request_completed(result, response_code, headers, body):
# warning-ignore:unused_variable
	print_debug(response_code)
	print_debug(headers)
	print_debug(body.size())
	var json_ret = parse_json(body.get_string_from_utf8())
	for img_dict in json_ret:
		var b64img = img_dict["img"]
		var base64_bytes = Marshalls.base64_to_raw(b64img)
		var image = Image.new()
		var error = image.load_webp_from_buffer(base64_bytes)
		if error != OK:
			push_error("Couldn't load the image.")
		var texture = ImageTexture.new()
		texture.create_from_image(image)
		image_textures.append(texture)
