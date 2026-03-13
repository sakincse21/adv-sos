extends Node3D

var tiles = []
var grid_size = 8

var player_1_node: Node3D
var player_2_node: Node3D

# Track what we have already animated to avoid duplicates
var last_animated_move = null
var p1_home: Vector3
var p2_home: Vector3

# SOS pattern line markers
var sos_line_nodes: Array = []
var rendered_pattern_count: int = 0

func _ready():
	# Board base platform
	var base = CSGBox3D.new()
	base.size = Vector3(grid_size + 0.6, 0.3, grid_size + 0.6)
	base.position = Vector3((grid_size - 1) * 0.5, -0.25, (grid_size - 1) * 0.5)
	var base_mat = StandardMaterial3D.new()
	base_mat.albedo_color = Color(0.25, 0.15, 0.08)
	base.material = base_mat
	add_child(base)

	# Create tiles
	for r in range(grid_size):
		var row = []
		for c in range(grid_size):
			var box = CSGBox3D.new()
			box.size = Vector3(0.92, 0.12, 0.92)
			box.position = Vector3(c, -0.04, r)
			var mat = StandardMaterial3D.new()
			if (r + c) % 2 == 0:
				mat.albedo_color = Color(0.85, 0.80, 0.65)
			else:
				mat.albedo_color = Color(0.45, 0.32, 0.18)
			mat.roughness = 0.4
			box.material = mat
			add_child(box)
			row.append({"node": box, "symbol": 0, "piece": null})
		tiles.append(row)

	# Create players
	p1_home = Vector3(-2.5, 0, 3.5)
	p2_home = Vector3(grid_size + 1.5, 0, 3.5)
	player_1_node = _build_kingkong(p1_home)
	player_2_node = _build_godzilla(p2_home)

	var http = get_node("../HttpClient")
	http.state_updated.connect(_on_state_updated)

# ========================
#  KING KONG MODEL
# ========================
func _build_kingkong(start_pos: Vector3) -> Node3D:
	var root = Node3D.new()
	root.position = start_pos

	# --- Torso ---
	var torso = CSGBox3D.new()
	torso.size = Vector3(0.7, 0.8, 0.5)
	torso.position = Vector3(0, 0.9, 0)
	var torso_mat = StandardMaterial3D.new()
	torso_mat.albedo_color = Color(0.22, 0.12, 0.06)
	torso.material = torso_mat
	root.add_child(torso)

	# --- Belly patch ---
	var belly = CSGBox3D.new()
	belly.size = Vector3(0.35, 0.35, 0.08)
	belly.position = Vector3(0, 0.8, 0.26)
	var belly_mat = StandardMaterial3D.new()
	belly_mat.albedo_color = Color(0.35, 0.22, 0.12)
	belly.material = belly_mat
	root.add_child(belly)

	# --- Head ---
	var head = CSGSphere3D.new()
	head.radius = 0.28
	head.position = Vector3(0, 1.55, 0)
	head.radial_segments = 16
	head.rings = 8
	var head_mat = StandardMaterial3D.new()
	head_mat.albedo_color = Color(0.18, 0.10, 0.05)
	head.material = head_mat
	root.add_child(head)

	# --- Eyes ---
	for side in [-1, 1]:
		var eye = CSGSphere3D.new()
		eye.radius = 0.06
		eye.position = Vector3(side * 0.12, 1.60, 0.22)
		eye.radial_segments = 8
		eye.rings = 4
		var eye_mat = StandardMaterial3D.new()
		eye_mat.albedo_color = Color.WHITE
		eye_mat.emission = Color.WHITE
		eye_mat.emission_energy_multiplier = 0.3
		eye.material = eye_mat
		root.add_child(eye)

		var pupil = CSGSphere3D.new()
		pupil.radius = 0.03
		pupil.position = Vector3(side * 0.12, 1.60, 0.27)
		pupil.radial_segments = 6
		pupil.rings = 3
		var pupil_mat = StandardMaterial3D.new()
		pupil_mat.albedo_color = Color(0.05, 0.02, 0.0)
		pupil.material = pupil_mat
		root.add_child(pupil)

	# --- Mouth ---
	var mouth = CSGBox3D.new()
	mouth.size = Vector3(0.18, 0.06, 0.06)
	mouth.position = Vector3(0, 1.42, 0.24)
	var mouth_mat = StandardMaterial3D.new()
	mouth_mat.albedo_color = Color(0.4, 0.12, 0.1)
	mouth.material = mouth_mat
	root.add_child(mouth)

	# --- Arms ---
	for side in [-1, 1]:
		var arm = CSGCylinder3D.new()
		arm.radius = 0.12
		arm.height = 0.7
		arm.position = Vector3(side * 0.5, 0.75, 0)
		arm.rotation_degrees = Vector3(0, 0, side * 20)
		arm.sides = 8
		var arm_mat = StandardMaterial3D.new()
		arm_mat.albedo_color = Color(0.20, 0.11, 0.05)
		arm.material = arm_mat
		root.add_child(arm)

		# Fists
		var fist = CSGSphere3D.new()
		fist.radius = 0.13
		fist.position = Vector3(side * 0.6, 0.4, 0)
		fist.radial_segments = 8
		fist.rings = 4
		fist.material = arm_mat
		root.add_child(fist)

	# --- Legs ---
	for side in [-1, 1]:
		var leg = CSGCylinder3D.new()
		leg.radius = 0.14
		leg.height = 0.5
		leg.position = Vector3(side * 0.2, 0.25, 0)
		leg.sides = 8
		var leg_mat = StandardMaterial3D.new()
		leg_mat.albedo_color = Color(0.18, 0.10, 0.04)
		leg.material = leg_mat
		root.add_child(leg)

	# --- Name Label ---
	var lbl = Label3D.new()
	lbl.text = "KING KONG"
	lbl.font_size = 32
	lbl.pixel_size = 0.01
	lbl.position = Vector3(0, 2.0, 0)
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.modulate = Color(1, 0.85, 0.2)
	lbl.outline_size = 8
	root.add_child(lbl)

	add_child(root)
	return root

# ========================
#  GODZILLA MODEL
# ========================
func _build_godzilla(start_pos: Vector3) -> Node3D:
	var root = Node3D.new()
	root.position = start_pos

	# --- Body ---
	var body = CSGBox3D.new()
	body.size = Vector3(0.6, 0.9, 0.7)
	body.position = Vector3(0, 0.85, 0)
	var body_mat = StandardMaterial3D.new()
	body_mat.albedo_color = Color(0.15, 0.28, 0.12)
	body.material = body_mat
	root.add_child(body)

	# --- Underbelly ---
	var belly = CSGBox3D.new()
	belly.size = Vector3(0.3, 0.5, 0.08)
	belly.position = Vector3(0, 0.75, 0.36)
	var belly_mat = StandardMaterial3D.new()
	belly_mat.albedo_color = Color(0.35, 0.45, 0.25)
	belly.material = belly_mat
	root.add_child(belly)

	# --- Head ---
	var head = CSGBox3D.new()
	head.size = Vector3(0.35, 0.3, 0.45)
	head.position = Vector3(0, 1.55, 0.15)
	var head_mat = StandardMaterial3D.new()
	head_mat.albedo_color = Color(0.14, 0.24, 0.10)
	head.material = head_mat
	root.add_child(head)

	# --- Snout ---
	var snout = CSGBox3D.new()
	snout.size = Vector3(0.22, 0.15, 0.25)
	snout.position = Vector3(0, 1.45, 0.4)
	var snout_mat = StandardMaterial3D.new()
	snout_mat.albedo_color = Color(0.16, 0.26, 0.12)
	snout.material = snout_mat
	root.add_child(snout)

	# --- Jaw ---
	var jaw = CSGBox3D.new()
	jaw.size = Vector3(0.20, 0.06, 0.22)
	jaw.position = Vector3(0, 1.35, 0.42)
	var jaw_mat = StandardMaterial3D.new()
	jaw_mat.albedo_color = Color(0.4, 0.15, 0.1)
	jaw.material = jaw_mat
	root.add_child(jaw)

	# --- Eyes (glowing) ---
	for side in [-1, 1]:
		var eye = CSGSphere3D.new()
		eye.radius = 0.05
		eye.position = Vector3(side * 0.12, 1.60, 0.35)
		eye.radial_segments = 8
		eye.rings = 4
		var eye_mat = StandardMaterial3D.new()
		eye_mat.albedo_color = Color(1.0, 0.6, 0.0)
		eye_mat.emission = Color(1.0, 0.5, 0.0)
		eye_mat.emission_energy_multiplier = 2.0
		eye.material = eye_mat
		root.add_child(eye)

	# --- Dorsal Spines ---
	for i in range(5):
		var spine = CSGPolygon3D.new()
		# Create triangle cross-section for spine
		spine.polygon = PackedVector2Array([
			Vector2(-0.04, 0), Vector2(0, 0.18 - i * 0.02), Vector2(0.04, 0)
		])
		spine.depth = 0.04
		spine.position = Vector3(0, 1.3 - i * 0.18, -0.28)
		spine.rotation_degrees = Vector3(-90, 0, 0)
		var spine_mat = StandardMaterial3D.new()
		spine_mat.albedo_color = Color(0.6, 0.65, 0.7)
		spine_mat.emission = Color(0.2, 0.4, 0.8)
		spine_mat.emission_energy_multiplier = 0.5
		spine.material = spine_mat
		root.add_child(spine)

	# --- Arms (small) ---
	for side in [-1, 1]:
		var arm = CSGCylinder3D.new()
		arm.radius = 0.08
		arm.height = 0.35
		arm.position = Vector3(side * 0.38, 0.85, 0.15)
		arm.rotation_degrees = Vector3(0, 0, side * 35)
		arm.sides = 6
		var arm_mat = StandardMaterial3D.new()
		arm_mat.albedo_color = Color(0.15, 0.26, 0.11)
		arm.material = arm_mat
		root.add_child(arm)

	# --- Legs (thick) ---
	for side in [-1, 1]:
		var leg = CSGCylinder3D.new()
		leg.radius = 0.15
		leg.height = 0.5
		leg.position = Vector3(side * 0.2, 0.25, 0)
		leg.sides = 8
		var leg_mat = StandardMaterial3D.new()
		leg_mat.albedo_color = Color(0.13, 0.22, 0.09)
		leg.material = leg_mat
		root.add_child(leg)

	# --- Tail ---
	for i in range(4):
		var seg = CSGCylinder3D.new()
		seg.radius = 0.12 - i * 0.025
		seg.height = 0.35
		seg.position = Vector3(0, 0.55 - i * 0.1, -0.45 - i * 0.3)
		seg.rotation_degrees = Vector3(65 + i * 5, 0, 0)
		seg.sides = 6
		var seg_mat = StandardMaterial3D.new()
		seg_mat.albedo_color = Color(0.14, 0.24, 0.10)
		seg.material = seg_mat
		root.add_child(seg)

	# --- Name Label ---
	var lbl = Label3D.new()
	lbl.text = "GODZILLA"
	lbl.font_size = 32
	lbl.pixel_size = 0.01
	lbl.position = Vector3(0, 2.1, 0)
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.modulate = Color(0.3, 1.0, 0.3)
	lbl.outline_size = 8
	root.add_child(lbl)

	add_child(root)
	return root

# ========================
#  STATE UPDATE (NO QUEUE — DIRECT SYNC)
# ========================
func _on_state_updated(state):
	var board = state.get("board", [])
	if board.size() != grid_size:
		return

	var last_move = state.get("last_move", null)
	var dominated = false

	# Only animate if it's a genuinely new move
	if last_move != null:
		var move_key = str(last_move)
		if move_key != last_animated_move:
			last_animated_move = move_key
			dominated = true
			_animate_move(last_move)

	# Always sync the full board state (fixes desync glitches)
	_sync_board(board)
	
	# Render SOS pattern highlight lines
	var patterns = state.get("sos_patterns", [])
	_render_sos_patterns(patterns)


func _render_sos_patterns(patterns: Array):
	# Only render newly added patterns (skip already rendered ones)
	if patterns.size() <= rendered_pattern_count:
		if patterns.size() == 0 and rendered_pattern_count > 0:
			# Game was reset — clear all lines
			for node in sos_line_nodes:
				if is_instance_valid(node):
					node.queue_free()
			sos_line_nodes.clear()
			rendered_pattern_count = 0
		return
	
	for i in range(rendered_pattern_count, patterns.size()):
		var pat = patterns[i]
		var player = int(pat.get("player", 1))
		var cells = pat.get("cells", [])
		if cells.size() != 3:
			continue
		
		# Determine line color based on player
		var line_color: Color
		var glow_color: Color
		if player == 1:
			line_color = Color(0.2, 0.5, 1.0, 0.85)   # Blue for King Kong
			glow_color = Color(0.3, 0.6, 1.0)
		else:
			line_color = Color(0.3, 1.0, 0.3, 0.85)   # Green for Godzilla
			glow_color = Color(0.2, 0.9, 0.2)
		
		# Get start and end positions (cells[0] and cells[2])
		var start_cell = cells[0]
		var end_cell = cells[2]
		var start_pos = Vector3(start_cell[1], 0.15, start_cell[0])
		var end_pos = Vector3(end_cell[1], 0.15, end_cell[0])
		
		# Create the line as a stretched cylinder between the two endpoints
		var line_node = _create_sos_line(start_pos, end_pos, line_color, glow_color)
		sos_line_nodes.append(line_node)
		
		# Also add small glowing markers at each of the 3 cells
		for cell in cells:
			var marker = CSGSphere3D.new()
			marker.radius = 0.12
			marker.position = Vector3(cell[1], 0.18, cell[0])
			marker.radial_segments = 8
			marker.rings = 4
			var m_mat = StandardMaterial3D.new()
			m_mat.albedo_color = line_color
			m_mat.emission = glow_color
			m_mat.emission_energy_multiplier = 2.0
			m_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			marker.material = m_mat
			add_child(marker)
			sos_line_nodes.append(marker)
			
			# Scale-in animation
			marker.scale = Vector3(0.01, 0.01, 0.01)
			var mtw = create_tween()
			mtw.tween_property(marker, "scale", Vector3(1, 1, 1), 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	
	rendered_pattern_count = patterns.size()


func _create_sos_line(start: Vector3, end: Vector3, col: Color, glow: Color) -> Node3D:
	var mid = (start + end) * 0.5
	var diff = end - start
	var length = diff.length()
	
	# Create cylinder oriented along the line
	var cyl = CSGCylinder3D.new()
	cyl.radius = 0.04
	cyl.height = length
	cyl.sides = 8
	cyl.position = mid
	
	# Rotate cylinder to align with the direction
	# Default cylinder is along Y axis, we need to align it to the diff vector
	var dir_norm = diff.normalized()
	if dir_norm.length() > 0.001:
		# Calculate rotation to align Y-axis with direction
		var up = Vector3.UP
		var angle = up.angle_to(dir_norm)
		var axis = up.cross(dir_norm).normalized()
		if axis.length() > 0.001:
			cyl.transform.basis = Basis(axis, angle)
			cyl.position = mid
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = col
	mat.emission = glow
	mat.emission_energy_multiplier = 3.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cyl.material = mat
	add_child(cyl)
	
	# Animate line appearing
	cyl.scale = Vector3(0.01, 0.01, 0.01)
	var tw = create_tween()
	tw.tween_property(cyl, "scale", Vector3(1, 1, 1), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	return cyl

func _sync_board(board):
	for r in range(grid_size):
		for c in range(grid_size):
			var val = int(board[r][c])
			var tile = tiles[r][c]
			if val != tile.symbol:
				tile.symbol = val
				_spawn_symbol(r, c, val, tile)

func _animate_move(last_move):
	var p = int(last_move.get("player", 1))
	var p_type = int(last_move.get("move_type", 1))
	var p_sym = int(last_move.get("symbol", 0))
	var pos = last_move.get("position", [0, 0])
	var target_pos = Vector3(pos[1], 0, pos[0])
	var active = player_1_node if p == 1 else player_2_node
	var home = p1_home if p == 1 else p2_home

	# --- Smooth walk to tile ---
	var tw = create_tween()
	tw.tween_property(active, "position", target_pos, 0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

	if p_type == 2:
		# ===========================
		#  SKIP / FORCE: HEAD NOD "NO"
		# ===========================
		# Pause at tile
		tw.tween_interval(0.15)
		# Head nod: rotate Y back and forth (shaking head "no")
		tw.tween_property(active, "rotation_degrees", Vector3(0, 25, 0), 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(active, "rotation_degrees", Vector3(0, -25, 0), 0.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(active, "rotation_degrees", Vector3(0, 20, 0), 0.20).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(active, "rotation_degrees", Vector3(0, -18, 0), 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(active, "rotation_degrees", Vector3(0, 0, 0), 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_interval(0.15)
	elif p_sym == 3:
		# ===========================
		#  X PLACEMENT: THUNDER BOLT
		# ===========================
		# Character raises up (power charge)
		tw.tween_property(active, "position", target_pos + Vector3(0, 0.6, 0), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_interval(0.2)
		# Character stomps down (unleash power)
		tw.tween_property(active, "position", target_pos, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		# Spawn lightning bolt VFX via callback
		tw.tween_callback(_spawn_thunder_bolt.bind(pos[0], pos[1]))
		tw.tween_interval(0.6)
	else:
		# ===========================
		#  S / O PLACEMENT: GENTLE STOMP
		# ===========================
		tw.tween_property(active, "position", target_pos + Vector3(0, 0.35, 0), 0.12).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(active, "position", target_pos, 0.15).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		tw.tween_interval(0.25)

	# --- Smooth walk home ---
	tw.tween_property(active, "position", home, 0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

# ========================
#  THUNDER BOLT VFX
# ========================
func _spawn_thunder_bolt(r: int, c: int):
	var bolt_root = Node3D.new()
	bolt_root.position = Vector3(c, 0, r)
	add_child(bolt_root)

	# --- Main lightning beam ---
	var beam = CSGCylinder3D.new()
	beam.radius = 0.06
	beam.height = 8.0
	beam.position = Vector3(0, 4.0, 0)
	beam.sides = 6
	var beam_mat = StandardMaterial3D.new()
	beam_mat.albedo_color = Color(1.0, 1.0, 0.6)
	beam_mat.emission = Color(1.0, 0.9, 0.3)
	beam_mat.emission_energy_multiplier = 5.0
	beam_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	beam_mat.albedo_color.a = 0.9
	beam.material = beam_mat
	bolt_root.add_child(beam)

	# --- Electric glow sphere at impact ---
	var glow = CSGSphere3D.new()
	glow.radius = 0.5
	glow.position = Vector3(0, 0.25, 0)
	glow.radial_segments = 12
	glow.rings = 6
	var glow_mat = StandardMaterial3D.new()
	glow_mat.albedo_color = Color(1.0, 0.95, 0.4, 0.7)
	glow_mat.emission = Color(1.0, 0.8, 0.2)
	glow_mat.emission_energy_multiplier = 4.0
	glow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow.material = glow_mat
	bolt_root.add_child(glow)

	# --- Secondary thin bolts (forked lightning) ---
	for i in range(3):
		var fork = CSGCylinder3D.new()
		fork.radius = 0.025
		fork.height = 3.0
		fork.sides = 4
		fork.position = Vector3(0, 3.5, 0)
		fork.rotation_degrees = Vector3(15 + i * 8, i * 120, 10 + i * 5)
		var fork_mat = StandardMaterial3D.new()
		fork_mat.albedo_color = Color(0.8, 0.8, 1.0, 0.6)
		fork_mat.emission = Color(0.6, 0.6, 1.0)
		fork_mat.emission_energy_multiplier = 3.0
		fork_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		fork.material = fork_mat
		bolt_root.add_child(fork)

	# --- Animate: flash in, hold briefly, fade out ---
	bolt_root.scale = Vector3(0.3, 0.3, 0.3)
	var vfx_tw = create_tween()
	# Flash in
	vfx_tw.tween_property(bolt_root, "scale", Vector3(1.0, 1.0, 1.0), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Hold
	vfx_tw.tween_interval(0.35)
	# Fade out
	vfx_tw.tween_property(bolt_root, "scale", Vector3(0.0, 0.0, 0.0), 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	# Cleanup
	vfx_tw.tween_callback(bolt_root.queue_free)

# ========================
#  SPAWN 3D SYMBOLS
# ========================
func _spawn_symbol(r, c, val, tile_data):
	if tile_data.piece != null:
		tile_data.piece.queue_free()
		tile_data.piece = null
	if val == 0:
		return

	var mesh: Node3D
	if val == 1: # S
		var l = Label3D.new()
		l.text = "S"
		l.pixel_size = 0.018
		l.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		l.rotation_degrees = Vector3(-90, 0, 0)
		l.modulate = Color(0.2, 0.5, 1.0)
		l.outline_modulate = Color(0.05, 0.15, 0.5)
		l.outline_size = 12
		l.font_size = 80
		mesh = l
	elif val == 2: # O
		var m = CSGTorus3D.new()
		m.inner_radius = 0.12
		m.outer_radius = 0.28
		m.sides = 24
		m.ring_sides = 12
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.9, 0.2, 0.15)
		mat.roughness = 0.3
		mat.metallic = 0.2
		m.material = mat
		mesh = m
	elif val == 3: # X — scorched dark mark
		var l = Label3D.new()
		l.text = "X"
		l.pixel_size = 0.018
		l.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		l.rotation_degrees = Vector3(-90, 0, 0)
		l.modulate = Color(0.9, 0.6, 0.1)
		l.outline_modulate = Color(0.4, 0.1, 0.0)
		l.outline_size = 14
		l.font_size = 80
		mesh = l

	if mesh:
		add_child(mesh)
		if val == 3:
			# X appears at ground level instantly (placed by thunder)
			mesh.position = Vector3(c, 0.12, r)
			mesh.scale = Vector3(0.01, 0.01, 0.01)
			var tw = create_tween()
			tw.tween_property(mesh, "scale", Vector3(1, 1, 1), 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		else:
			# S and O do a smooth gentle drop
			mesh.position = Vector3(c, 2.0, r)
			var tw = create_tween()
			tw.tween_property(mesh, "position", Vector3(c, 0.12, r), 0.5).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		tile_data.piece = mesh

