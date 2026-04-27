extends Control

# References
var logs_label: RichTextLabel
var stats_label: Label
var btn_panel: VBoxContainer

# ─────────────────────────────────────────────────────────────────
#  Layout:
#   ┌──────────────────────────────────────────────────────────────┐
#   │ [Score / Turn]      [GAMEPLAY AREA]      [Buttons + Logs]   │
#   │  compact left strip      free             compact right strip│
#   └──────────────────────────────────────────────────────────────┘
#  Both side panels are narrow (200 px) and stay at the top, so the
#  3D board and the Kaiju characters remain fully visible.
# ─────────────────────────────────────────────────────────────────

func _ready():
	# ── LEFT PANEL: score / turn ──────────────────────────────────
	var left = PanelContainer.new()
	# Anchor to top-left corner, fixed width 200 px, height auto
	left.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	left.offset_right  = 200
	left.offset_bottom = 168
	left.offset_left   = 0
	left.offset_top    = 0
	left.add_theme_stylebox_override("panel", _panel_style(Color(0, 0, 0, 0.70)))
	add_child(left)

	var left_vbox = VBoxContainer.new()
	left.add_child(left_vbox)

	var title_lbl = Label.new()
	title_lbl.text = "⚔ SOS BATTLE"
	title_lbl.add_theme_font_size_override("font_size", 13)
	title_lbl.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	left_vbox.add_child(title_lbl)

	var sep = HSeparator.new()
	left_vbox.add_child(sep)

	stats_label = Label.new()
	stats_label.add_theme_font_size_override("font_size", 13)
	stats_label.add_theme_color_override("font_color", Color(1, 0.95, 0.6))
	stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left_vbox.add_child(stats_label)

	# ── RIGHT PANEL: buttons + log ────────────────────────────────
	var right = PanelContainer.new()
	# Anchor to top-right corner
	right.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	right.offset_left   = -210
	right.offset_right  = 0
	right.offset_top    = 0
	right.offset_bottom = 320
	right.add_theme_stylebox_override("panel", _panel_style(Color(0, 0, 0, 0.70)))
	add_child(right)

	var right_vbox = VBoxContainer.new()
	right.add_child(right_vbox)

	btn_panel = VBoxContainer.new()
	btn_panel.add_theme_constant_override("separation", 4)
	right_vbox.add_child(btn_panel)

	_add_button("Minimax vs MCTS",    _on_start_m_vs_mc)
	_add_button("MCTS vs MCTS",       _on_start_mc_vs_mc)
	_add_button("Minimax vs Minimax", _on_start_m_vs_m)
	_add_button("Pause / Resume",     _on_pause)

	var sep2 = HSeparator.new()
	right_vbox.add_child(sep2)

	logs_label = RichTextLabel.new()
	logs_label.bbcode_enabled = true
	logs_label.fit_content = false
	logs_label.scroll_active = false
	logs_label.custom_minimum_size = Vector2(190, 130)
	logs_label.add_theme_font_size_override("normal_font_size", 11)
	right_vbox.add_child(logs_label)

	# Connect HTTP client
	var http = get_node("../../HttpClient")
	http.state_updated.connect(_on_state_updated)
	http.start_polling()


# ── Helpers ──────────────────────────────────────────────────────

func _panel_style(bg: Color) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = bg
	s.corner_radius_top_left     = 0
	s.corner_radius_top_right    = 0
	s.corner_radius_bottom_left  = 8
	s.corner_radius_bottom_right = 8
	s.content_margin_left   = 8
	s.content_margin_top    = 8
	s.content_margin_right  = 8
	s.content_margin_bottom = 8
	return s


func _add_button(text: String, callback: Callable):
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(190, 30)

	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.10, 0.15, 0.10, 0.85)
	normal_style.corner_radius_top_left     = 5
	normal_style.corner_radius_top_right    = 5
	normal_style.corner_radius_bottom_left  = 5
	normal_style.corner_radius_bottom_right = 5
	normal_style.border_color = Color(0.35, 0.65, 0.35, 0.8)
	normal_style.border_width_bottom = 1
	normal_style.border_width_top    = 1
	normal_style.border_width_left   = 1
	normal_style.border_width_right  = 1

	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(0.12, 0.24, 0.12, 0.9)
	hover_style.corner_radius_top_left     = 5
	hover_style.corner_radius_top_right    = 5
	hover_style.corner_radius_bottom_left  = 5
	hover_style.corner_radius_bottom_right = 5
	hover_style.border_color = Color(0.5, 0.9, 0.5, 1.0)
	hover_style.border_width_bottom = 1
	hover_style.border_width_top    = 1
	hover_style.border_width_left   = 1
	hover_style.border_width_right  = 1

	btn.add_theme_stylebox_override("normal", normal_style)
	btn.add_theme_stylebox_override("hover",  hover_style)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_font_size_override("font_size", 12)
	btn.pressed.connect(callback)
	btn_panel.add_child(btn)


# ── State updates ─────────────────────────────────────────────────

func _on_state_updated(state):
	# ── Scoreboard ──
	var p1   = state.get("score_p1", 0)
	var p2   = state.get("score_p2", 0)
	var st   = state.get("running", false)
	var turn = state.get("turn", 1)

	var s = ""
	if st:
		s += "⚡ RUNNING\n\n"
	else:
		s += "⏹ STOPPED\n\n"

	s += "🦍 Kong: " + str(p1) + "\n"
	s += "🦎 Zilla: " + str(p2) + "\n"

	if st:
		s += "\n" + (">> KONG <<" if turn == 1 else ">> ZILLA <<")

	stats_label.text = s

	# ── Move log ──
	var lgs = state.get("logs", [])
	var log_text = "[b][color=lime]Moves[/color][/b]\n"
	for l in lgs:
		log_text += "[color=#cccccc]" + str(l) + "[/color]\n"
	logs_label.text = log_text


# ── Button callbacks ──────────────────────────────────────────────

func _on_start_m_vs_mc():
	get_node("../../HttpClient").send_command("/start", {"agent1": "minimax", "agent2": "mcts"})

func _on_start_mc_vs_mc():
	get_node("../../HttpClient").send_command("/start", {"agent1": "mcts", "agent2": "mcts"})

func _on_start_m_vs_m():
	get_node("../../HttpClient").send_command("/start", {"agent1": "minimax", "agent2": "minimax"})

func _on_pause():
	get_node("../../HttpClient").send_command("/pause", {})
