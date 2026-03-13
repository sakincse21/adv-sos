extends Node3D
## Attach this to Main. It procedurally spawns jungle trees and rocks around the board.

func _ready():
	_build_jungle_floor()
	_spawn_trees()

func _build_jungle_floor():
	# Green ground already in scene as CSGBox3D "JungleFloor", but let's add material
	var floor_node = get_node_or_null("../JungleFloor")
	if floor_node and floor_node is CSGBox3D:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.18, 0.35, 0.12)
		mat.roughness = 0.9
		floor_node.material = mat

func _spawn_trees():
	var rng = RandomNumberGenerator.new()
	rng.seed = 42 # deterministic for consistency

	# Place trees in a ring around the board
	var positions = []
	for i in range(20):
		var angle = i * (TAU / 20.0)
		var dist = rng.randf_range(7.0, 13.0)
		var x = 3.5 + cos(angle) * dist
		var z = 3.5 + sin(angle) * dist
		positions.append(Vector3(x, 0, z))

	# A few extra scattered ones
	for i in range(8):
		var x = rng.randf_range(-8.0, 15.0)
		var z = rng.randf_range(-8.0, 15.0)
		# Skip if too close to board center
		if abs(x - 3.5) < 5.5 and abs(z - 3.5) < 5.5:
			continue
		positions.append(Vector3(x, 0, z))

	for pos in positions:
		_make_tree(pos, rng)

func _make_tree(pos: Vector3, rng: RandomNumberGenerator):
	var tree = Node3D.new()
	tree.position = pos

	var trunk_h = rng.randf_range(2.5, 5.0)
	var trunk_r = rng.randf_range(0.12, 0.22)

	# Trunk
	var trunk = CSGCylinder3D.new()
	trunk.radius = trunk_r
	trunk.height = trunk_h
	trunk.position = Vector3(0, trunk_h * 0.5, 0)
	trunk.sides = 8
	var trunk_mat = StandardMaterial3D.new()
	trunk_mat.albedo_color = Color(
		rng.randf_range(0.25, 0.4),
		rng.randf_range(0.15, 0.25),
		rng.randf_range(0.05, 0.12)
	)
	trunk_mat.roughness = 0.85
	trunk.material = trunk_mat
	tree.add_child(trunk)

	# Canopy (2-3 overlapping spheres)
	var num_canopy = rng.randi_range(2, 3)
	for i in range(num_canopy):
		var canopy = CSGSphere3D.new()
		canopy.radius = rng.randf_range(0.8, 1.8)
		canopy.radial_segments = 12
		canopy.rings = 6
		canopy.position = Vector3(
			rng.randf_range(-0.4, 0.4),
			trunk_h + rng.randf_range(-0.3, 0.5),
			rng.randf_range(-0.4, 0.4)
		)
		var canopy_mat = StandardMaterial3D.new()
		canopy_mat.albedo_color = Color(
			rng.randf_range(0.1, 0.25),
			rng.randf_range(0.35, 0.65),
			rng.randf_range(0.08, 0.2)
		)
		canopy_mat.roughness = 0.7
		canopy.material = canopy_mat
		tree.add_child(canopy)

	add_child(tree)
