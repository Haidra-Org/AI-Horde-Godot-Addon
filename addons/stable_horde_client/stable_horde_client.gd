class_name StableHordeClient
extends HTTPRequest

signal images_generated(texture_list)

export(String) var prompt = "A horde of cute blue robots with gears on their head"
export(String) var api_key := '0000000000'
export(int) var amount := 1
export(int,64,1024,64) var width := 512
export(int,64,1024,64) var length := 512
export(int,1,200) var steps := 50
export(String, "k_lms", "k_heun", "k_euler", "k_euler_a", "k_dpm_2", "k_dpm_2_a", "DDIM", "PLMS") var sampler_name := "k_lms"

var all_image_textures := []
var latest_image_textures := []

func _ready():
	# warning-ignore:return_value_discarded
	connect("request_completed",self,"_on_request_completed")

func generate(replacement_prompt := '', replacement_params := {}) -> void:
	latest_image_textures.clear()
	var imgen_params = {
		"n": amount,
		"width": width,
		"height": length,
		"steps": steps,
		"sampler_name": sampler_name,
		# You can put extra SD webui params here if you wish
	}
	for param in replacement_params:
		imgen_params[param] = replacement_params[param]
	var submit_dict = {
		"prompt": prompt,
		"api_key": api_key,
		"params": imgen_params
	}
	if replacement_prompt != '':
		submit_dict['prompt'] = replacement_prompt
	var body = to_json(submit_dict)
	var headers = ["Content-Type: application/json"]
	var error = request("https://stablehorde.net/api/v1/generate/sync", headers, false, HTTPClient.METHOD_POST, body)
	if error != OK:
		push_error("Something went wrong when submitting the stable horde request")

# warning-ignore:unused_argument
func _on_request_completed(_result, _response_code, _headers, body):
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
		latest_image_textures.append(texture)
		all_image_textures.append(texture)
	emit_signal("images_generated",latest_image_textures)
