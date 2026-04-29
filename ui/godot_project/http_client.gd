extends HTTPRequest

signal state_updated(state)

var base_url = "http://127.0.0.1:8000/api"
var polling = false
var json = JSON.new()

func _ready():
	request_completed.connect(_on_request_completed)

func start_polling():
	polling = true
	_poll()

func stop_polling():
	polling = false

func _poll():
	if polling:
		request(base_url + "/state")

func _on_request_completed(result, response_code, headers, body):
	if response_code == 200:
		var err = json.parse(body.get_string_from_utf8())
		if err == OK:
			emit_signal("state_updated", json.data)
			
	if polling:
		await get_tree().create_timer(0.5).timeout
		_poll()

func send_command(endpoint, data={}):
	var req = HTTPRequest.new()
	add_child(req)
	var headers = ["Content-Type: application/json"]
	var body_str = JSON.stringify(data)
	req.request(base_url + endpoint, headers, HTTPClient.METHOD_POST, body_str)
	req.request_completed.connect(func(res, code, h, b): req.queue_free())
