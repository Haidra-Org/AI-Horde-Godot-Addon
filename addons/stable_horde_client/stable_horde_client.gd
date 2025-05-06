class_name StableHordeClient
extends StableHordeHTTPRequest

signal images_generated(completed_payload)
signal image_processing(stats)
signal kudos_calculated(kudos)

enum SamplerMethods {
	k_lms = 0,
	k_heun,
	k_euler,
	k_euler_a,
	k_dpm_2,
	k_dpm_2_a,
	k_dpm_fast,
	k_dpm_adaptive,
	k_dpmpp_2s_a,
	k_dpmpp_2m,
	k_dpmpp_sde,
	dpmsolver,
	lcm,
}

enum ControlTypes {
	none = 0,
	canny,
	hed,
	depth,
	normal,
	openpose,
	seg,
	scribble,
	fakescribbles,
	hough,
}

enum Workflows {
	auto_detect = 0,
	qr_code,
}

enum OngoingRequestOperations {
	CHECK,
	GET,
	CANCEL,
}

@export var prompt: String = "A horde of cute blue robots with gears on their head"
# The API key you've generated from https://aihorde.net/register
# You can pass either your own key (make sure you encrypt your app)
# Or ask each player to register on their own
# You can also pass the 0000000000 Anonymous key, but it has the lowest priority
@export var api_key := '0000000000'
# How many images following the same prompt to do
@export var amount := 1
# The exact size of the image to generate. If you put too high, you might have to wait longer
# For a worker which can generate it
# Try not to go lower than 512 on both sizes, as 512 is what the model has been trained on.
@export var width := 512 # (int,64,1024,64)
@export var height := 512 # (int,64,1024,64)
# The steps correspond directly to the time it takes to get back your image.
# Generally there's usually no reason to go above 50 unless you know what you're doing.
@export var steps := 30 # (int,1,100)
# Advanced: The sampler used to generate. Provides slight variations on the same prompt.
@export var sampler_name := "k_euler_a" # (String, "k_lms", "k_heun", "k_euler", "k_euler_a", "k_dpm_2", "k_dpm_2_a", "k_dpm_fast", "k_dpm_adaptive", "k_dpmpp_2s_a", "k_dpmpp_2m", "k_dpmpp_sde", "dpmsolver", "lcm")
# How closely to follow the prompt given
@export var cfg_scale := 7.5 # (float,0,30,0.5)
# The number of CLIP language processor layers to skip.
@export var clip_skip := 1 # (int,1,12,1)
# How closely to follow the source image in img2img
@export var denoising_strength := 0.7 # (float,0,1,0.01)
# The unique seed for the prompt. If you pass a value in the seed and keep all the values the same
# The same image will always be generated.
@export var gen_seed := ''
# Post Processors to use.
@export var post_processing := []
# Loras to use. Each entry needs to be a dictionary in the form of
#{"name": String, "model": float, "clip": float}
@export var lora := []
@export var tis := []
# If set to True, will enable the karras noise scheduler
@export var karras := true
# If set to True, will activate the HiRes Fix
@export var hires_fix := false
# If set to True, will mark this generation as NSFW and only workers which accept NSFW requests
# Will fulfill it
@export var nsfw := false
# Only active is nsfw == false
# Will request workers to censor accidentally generated NSFW images. 
# If set to false, and a sfw request accidently generates nsfw content, the worker
# will automatically set it to a black image.
@export var censor_nsfw := true
# When true, will allow untrusted workers to also generate for this request.
@export var trusted_workers := true
# The model to be used to generate this request. If you change this, use the StableHordeModels class 
# To ensure there is a worker serving that model first.
# An empty array here picks the first available models from the workers
@export var models := ["stable_diffusion"]
@export var source_image: Image
# If true, the image will be sent as a URL to download instead of a base64 string
@export var r2 := true
# If true, the image will be stored permanently in a dataset that will be provided to LAION
# top help train future models
@export var shared := true
@export var control_type := "none" # (String, "none", "canny", "hed", "depth", "normal", "openpose", "seg", "scribble", "fakescribbles", "hough")
@export var dry_run := false
@export var replacement_filter := true
@export var workers := []
@export var worker_blacklist := false
@export var allow_downgrade := false
@export var extra_slow_workers := false
@export var transparent := false
@export var workflow := "auto-detect" # (String, "auto-detect", "qr_code")
@export var extra_texts: Array = []

var all_image_textures := []
var latest_image_textures := []
# The open request UUID to track its status
var async_request_id : String
# We store the params sent to the current generation, then pass them to the AIImageTexture to remember them
# They are replaced every time a new generation begins
var imgen_params : Dictionary
# When set to true, we will abort the current generation and try to retrieve whatever images we can
var request_start_time : float # We use that to get the accurate amount of time the request took
var async_retrievals_completed = 0
var delete_sent = false

func generate(replacement_prompt := '', replacement_params := {}) -> void:
	if state != States.READY:
		push_error("Client currently working. Cannot do more than 1 request at a time with the same Stable Horde Client.")
		return
	delete_sent = false
	request_start_time = Time.get_ticks_msec()
	state = States.WORKING
	latest_image_textures.clear()
	async_request_id = ''
	imgen_params = {
		"n": amount,
		"width": width,
		"height": height,
		"steps": steps,
		"sampler_name": sampler_name,
		"karras": karras,
		"hires_fix": hires_fix,
		"cfg_scale": cfg_scale,
		"seed": gen_seed,
		"post_processing": post_processing,
		"clip_skip": clip_skip,
		"transparent": transparent,
	}
	if control_type != 'none':
		imgen_params["control_type"] = control_type
	if lora.size() > 0:
		imgen_params["loras"] = _get_loras_payload()
	if tis.size() > 0:
		imgen_params["tis"] = _get_tis_payload()
	if workflow != 'auto-detect':
		imgen_params["workflow"] = workflow
	if extra_texts != null and extra_texts.size() > 0:
		imgen_params["extra_texts"] = extra_texts
	for param in replacement_params:
		imgen_params[param] = replacement_params[param]
	var submit_dict = {
		"prompt": prompt,
		"params": imgen_params,
		"nsfw": nsfw,
		"censor_nsfw": censor_nsfw,
		"trusted_workers": trusted_workers,
		"models": models,
		"r2": r2,
		"shared": shared,
		"dry_run": dry_run,
		"workers": workers,
		"worker_blacklist": worker_blacklist,
		"allow_downgrade": allow_downgrade,
		"extra_slow_workers": extra_slow_workers,
		"replacement_filter": replacement_filter
#		"workers": [
#			"dc0704ab-5b42-4c65-8471-561be16ad696", #portal
#		], # debug
	}
	if false: # Debug
		print_debug(submit_dict)
		push_warning("Aborting due to debug")
		return
	if source_image:
		submit_dict["source_image"] = get_img2img_b64(source_image)
		submit_dict["params"]["denoising_strength"] = denoising_strength
	if replacement_prompt != '':
		submit_dict['prompt'] = replacement_prompt
	var body = JSON.new().stringify(submit_dict)
#	print_debug(body)
	var headers = [
		"Content-Type: application/json", 
		"apikey: " + api_key,
		"Client-Agent: " + client_agent,
	]
#	print_debug(body)
#	print_debug(headers)
	var error = request(aihorde_url + "/api/v2/generate/async", headers, HTTPClient.METHOD_POST, body)
	if error != OK:
		var error_msg := "Something went wrong when initiating the stable horde request"
		push_error(error_msg)
		state = States.READY
		emit_signal("request_failed",error_msg)
	emit_signal("request_initiated")

# Function to overwrite to process valid return from the horde
func process_request(json_ret) -> void:
#	print_debug(json_ret)
	if typeof(json_ret) == TYPE_ARRAY:
		_extract_images(json_ret)
		return
	if 'generations' in json_ret:
		_extract_images(json_ret['generations'])
		return
	if 'kudos' in json_ret and dry_run:
		complete_dry_run_request(json_ret["kudos"])
		return
	if delete_sent:
		_return_empty()
		return
	if state == States.CANCELLING:
		check_request_process(OngoingRequestOperations.CANCEL)
	elif 'id' in json_ret:
		async_request_id = json_ret['id']
		check_request_process(OngoingRequestOperations.CHECK)
	elif 'done' in json_ret:
		var operation = OngoingRequestOperations.CHECK
		if json_ret['done']:
			operation = OngoingRequestOperations.GET
		elif state == States.WORKING:
			json_ret["elapsed_time"] = Time.get_ticks_msec() - request_start_time
			emit_signal("image_processing", json_ret)
		check_request_process(operation)


func check_request_process(operation := OngoingRequestOperations.CHECK) -> void:
	# We do one check request per second
	await get_tree().create_timer(1).timeout
	var url = aihorde_url + "/api/v2/generate/check/" + async_request_id
	var method = HTTPClient.METHOD_GET
	if operation == OngoingRequestOperations.GET:
		url = aihorde_url + "/api/v2/generate/status/" + async_request_id
	elif operation == OngoingRequestOperations.CANCEL:
		url = aihorde_url + "/api/v2/generate/status/" + async_request_id
		method = HTTPClient.METHOD_DELETE
		delete_sent = true
	var error = request(
		url, 
		["Client-Agent: " + client_agent], 
		method)
	if state == States.WORKING and error != OK:
		var error_msg := "Something went wrong when checking the status of AI Horde Request: " + async_request_id
		push_error(error_msg)
		emit_signal("request_failed",error_msg)
	elif state == States.CANCELLING and not error in [ERR_BUSY, OK] :
		var error_msg := "Something went wrong when cancelling the AI Horde Request: " + async_request_id
		push_error(error_msg)
		emit_signal("request_failed",error_msg)


func _extract_images(generations_array: Array) -> void:
	var timestamp := Time.get_unix_time_from_system()
	if generations_array.size() == 0:
		complete_image_request()
		return
	for img_dict in generations_array:
		var error
		var image: Image
		async_retrievals_completed = 0
		if 'https' in img_dict["img"]:
			var image_retriever := R2ImageRetriever.new()
			add_child(image_retriever)
			image_retriever.connect(
					"retrieval_failed",
					Callable(self, "_on_r2_retrieval_failed").bind(generations_array.size()) 
					)
			image_retriever.connect(
					"retrieval_success", 
					Callable(
						self, 
						"_on_r2_retrieval_success").bind(
							img_dict,  timestamp, generations_array.size()
							) 
					)
			image_retriever.download_image(img_dict["img"])
		else:
			var b64img = img_dict["img"]
			var base64_bytes = Marshalls.base64_to_raw(b64img)
			# Just in case a worker sends us randomly a b64
			async_retrievals_completed += 1
			prepare_aitexture(base64_bytes, img_dict, timestamp)
	if not r2:
		complete_image_request()
		
func _return_empty() -> void:
	complete_image_request()

func prepare_aitexture(imgbuffer: PackedByteArray, img_dict: Dictionary, timestamp: int) -> AIImageTexture:
	var image = Image.new()
	var error = image.load_webp_from_buffer(imgbuffer)
	if error != OK:
		var error_msg := "Couldn't load the image."
		push_error(error_msg)
		emit_signal("request_failed",error_msg)
		return null
	var texture = AIImageTexture.new(
		prompt,
		imgen_params,
		img_dict["seed"],
		img_dict["model"],
		img_dict["worker_id"],
		img_dict["worker_name"],
		timestamp,
		control_type,
		image,
		img_dict["id"],
		async_request_id,
		img_dict.get("gen_metadata", [])
	)
	texture.set_image(image)
	latest_image_textures.append(texture)
	# Avoid keeping all images in RAM. Until I find a reason for it.
#	all_image_textures.append(texture)
	return texture

func complete_image_request() -> void:
	var completed_payload = {
		"image_textures": latest_image_textures,
		"elapsed_time": Time.get_ticks_msec() - request_start_time
	}
	request_start_time = 0
	emit_signal("images_generated",completed_payload)
	state = States.READY

func complete_dry_run_request(kudos: int) -> void:
	var completed_payload = {
		"kudos": kudos,
		"elapsed_time": Time.get_ticks_msec() - request_start_time
	}
	request_start_time = 0
	emit_signal("kudos_calculated",completed_payload)
	state = States.READY

func _on_r2_retrieval_success(image_bytes: PackedByteArray, img_dict: Dictionary, timestamp: int, expected_amount: int) -> void:
	prepare_aitexture(image_bytes, img_dict, timestamp)
	async_retrievals_completed += 1
	if async_retrievals_completed >= expected_amount:
		complete_image_request()

func _on_r2_retrieval_failed(error_msg: String, expected_amount: int) -> void:
	async_retrievals_completed += 1
	if async_retrievals_completed >= expected_amount:
		complete_image_request()

func get_sampler_method_id() -> String:
	return(SamplerMethods[sampler_name])

func get_control_type_id() -> String:
	return(ControlTypes[control_type])

func cancel_request() -> void:
	print_debug("Cancelling...")
	push_warning("Cancelling...")
	state = States.CANCELLING

func get_img2img_b64(image: Image) -> String:
	var imgbuffer = image.save_png_to_buffer()
	return(Marshalls.raw_to_base64(imgbuffer))
	
func _get_loras_payload() -> Array:
	"""We replace the name with the ID, to ensure we find it easy on the worker"""
	var loras_array = []
	for item in lora:
		var new_item = item.duplicate()
		if new_item.has("id") and not new_item["name"].is_valid_int():
			new_item["original_name"] = str(new_item["name"])
			new_item["name"] = str(new_item["id"])
		loras_array.append(new_item)
	return loras_array
		
func _get_tis_payload() -> Array:
	"""We replace the name with the ID, to ensure we find it easy on the worker"""
	var tis_array = []
	for item in tis:
		var new_item = item.duplicate()
		if new_item.has("id") and not new_item["name"].is_valid_int():
			new_item["original_name"] = str(new_item["name"])
			new_item["name"] = str(new_item["id"])
		tis_array.append(new_item)
	return tis_array
		
