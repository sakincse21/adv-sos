extends Control

var logs_label: RichTextLabel
var stats_panel: PanelContainer
var stats_label: Label
var btn_panel: VBoxContainer

func _ready():
	# --- Left side: Move log panel ---
	var log_panel = PanelContainer.new()
	log_panel.position = Vector2(12, 12)
	log_panel.size = Vector2(320, 200)
	var log_style = StyleBoxFlat.new()
	log_style.bg_color = Color(0, 0, 0, 0.65)
	log_style.corner_radius_top_left = 8
	log_style.corner_radius_top_right = 8
	log_style.corner_radius_bottom_left = 8
	log_style.corner_radius_bottom_right = 8
	log_style.content_margin_left = 10
	log_style.content_margin_top = 10
	log_style.content_margin_right = 10
	log_style.content_margin_bottom = 10
	log_panel.add_theme_stylebox_override("panel", log_style)
	add_child(log_panel)

	logs_label = RichTextLabel.new()
	logs_label.bbcode_enabled = true
	logs_label.fit_content = true
	logs_label.scroll_active = false
	logs_label.add_theme_font_size_override("normal_font_size", 13)
	log_panel.add_child(logs_label)

	# --- Left side: Scoreboard panel ---
	stats_panel = PanelContainer.new()
	stats_panel.position = Vector2(12, 225)
	stats_panel.size = Vector2(320, 160)
	var stats_style = StyleBoxFlat.new()
	stats_style.bg_color = Color(0, 0, 0, 0.65)
	stats_style.corner_radius_top_left = 8
	stats_style.corner_radius_top_right = 8
	stats_style.corner_radius_bottom_left = 8
	stats_style.corner_radius_bottom_right = 8
	stats_style.content_margin_left = 10
	stats_style.content_margin_top = 10
	stats_style.content_margin_right = 10
	stats_style.content_margin_bottom = 10
	stats_panel.add_theme_stylebox_override("panel", stats_style)
	add_child(stats_panel)

	stats_label = Label.new()
	stats_label.add_theme_font_size_override("font_size", 18)
	stats_label.add_theme_color_override("font_color", Color(1, 0.95, 0.6))
	stats_panel.add_child(stats_label)

	# --- Right side: Buttons ---
	btn_panel = VBoxContainer.new()
	btn_panel.position = Vector2(get_viewport_rect().size.x - 250, 12)
	btn_panel.size = Vector2(230, 200)
	add_child(btn_panel)

	_add_button("Minimax vs MCTS", _on_start_m_vs_mc)
	_add_button("MCTS vs MCTS", _on_start_mc_vs_mc)
	_add_button("Minimax vs Minimax", _on_start_m_vs_m)
	_add_button("Pause / Resume", _on_pause)

	var http = get_node("../../HttpClient")
	http.state_updated.connect(_on_state_updated)
	http.start_polling()

func _add_button(text: String, callback: Callable):
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(220, 36)
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.12, 0.12, 0.12, 0.8)
	btn_style.corner_radius_top_left = 6
	btn_style.corner_radius_top_right = 6
	btn_style.corner_radius_bottom_left = 6
	btn_style.corner_radius_bottom_right = 6
	btn_style.border_color = Color(0.4, 0.6, 0.3, 0.7)
	btn_style.border_width_bottom = 1
	btn_style.border_width_top = 1
	btn_style.border_width_left = 1
	btn_style.border_width_right = 1
	btn.add_theme_stylebox_override("normal", btn_style)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_font_size_override("font_size", 14)
	btn.pressed.connect(callback)
	btn_panel.add_child(btn)

func _on_state_updated(state):
	# Logs
	var lgs = state.get("logs", [])
	var log_text = "[b][color=lime][ Move History ][/color][/b]\n"
	for l in lgs:
		log_text += "[color=white]" + str(l) + "[/color]\n"
	logs_label.text = log_text

	# Stats
	var p1 = state.get("score_p1", 0)
	var p2 = state.get("score_p2", 0)
	var st = state.get("running", false)
	var turn = state.get("turn", 1)

	var stat_str = ""
	if st:
		stat_str += "⚡ MATCH RUNNING\n\n"
	else:
		stat_str += "⏹ MATCH STOPPED\n\n"
	stat_str += "🦍  KING KONG (P1):  " + str(p1) + "\n"
	stat_str += "🦎  GODZILLA  (P2):  " + str(p2) + "\n"
	if st:
		var turn_name = "KING KONG 🦍" if turn == 1 else "GODZILLA 🦎"
		stat_str += "\n>> " + turn_name + "'s TURN <<"

	stats_label.text = stat_str

func _on_start_m_vs_mc():
	var http = get_node("../../HttpClient")
	http.send_command("/start", {"agent1": "minimax", "agent2": "mcts"})

func _on_start_mc_vs_mc():
	var http = get_node("../../HttpClient")
	http.send_command("/start", {"agent1": "mcts", "agent2": "mcts"})

func _on_start_m_vs_m():
	var http = get_node("../../HttpClient")
	http.send_command("/start", {"agent1": "minimax", "agent2": "minimax"})

func _on_pause():
	var http = get_node("../../HttpClient")
	http.send_command("/pause", {})
