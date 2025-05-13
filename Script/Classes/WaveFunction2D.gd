class_name WaveFunction2D extends Node2D


@export var source_id: int = 0
@export var alternative_tile: int = 0
@export var tile_map_layer: TileMapLayer
@export var map_size: Vector2i = Vector2i(32, 32)
@export var wave_node_cluster: Node2D
@export var label: Label
var wave_node_array: Array[WaveNode2D]
var tile_map_possibilities: Dictionary
var possible_connections: Array[int]


func initialize_tile_map_possibilities() -> void:
	for x in range(-map_size.x, map_size.x + 1):
		for y in range(-map_size.y, map_size.y + 1):
			var coord: Vector2i = Vector2i(x, y)
			var possibilities: Array[Vector2i] = []
			for wave_node in wave_node_array:
				var node_vec: Vector2i = Vector2i(
					wave_node.tile_coords.x,
					wave_node.tile_coords.y
				)
				possibilities.append(node_vec)
			tile_map_possibilities[coord] = possibilities


func generate_wave_nodes() -> void:
	if wave_node_cluster != null:
		var children: Array[Node] = wave_node_cluster.get_children()
		var unique_connections: Dictionary = {}
		for child in children:
			if child is WaveNode2D:
				wave_node_array.append(child)
				for valid_connection in [
					child.valid_south_connection,
					child.valid_north_connection,
					child.valid_west_connection,
					child.valid_east_connection
				]:
					for connection in valid_connection:
						if connection not in unique_connections:
							unique_connections[connection] = true
							possible_connections.append(connection)
	possible_connections.sort()
	initialize_tile_map_possibilities()


func clear_tiles() -> void:
	for x in range(-map_size.x, map_size.x + 1):
		for y in range(-map_size.y, map_size.y + 1):
			var pos: Vector2i = Vector2i(x, y)
			tile_map_layer.set_cell(pos, -1)  # Erase the tile
	initialize_tile_map_possibilities()


func get_wave_node(pos: Vector2i) -> WaveNode2D:
	for wave_node in wave_node_array:
		if pos == wave_node.tile_coords:
			return wave_node
	return null


func set_wave_node(pos: Vector2i, new_wave_node: WaveNode2D) -> bool:
	if wave_node_array == null or new_wave_node == null:
		return false
	for wave_node in wave_node_array:
		if pos == wave_node.tile_coords:
			wave_node = new_wave_node
	return true


func west_connection(new_node: WaveNode2D) -> Array[Vector3i]:
	return get_possible_connections(new_node,
		func(node, connection): return node.is_valid_east_connection(connection),
		func(node, connection): return node.is_valid_west_connection(connection))


func east_connection(new_node: WaveNode2D) -> Array[Vector3i]:
	return get_possible_connections(new_node,
		func(node, connection): return node.is_valid_west_connection(connection),
		func(node, connection): return node.is_valid_east_connection(connection))


func north_connection(new_node: WaveNode2D) -> Array[Vector3i]:
	return get_possible_connections(new_node,
		func(node, connection): return node.is_valid_south_connection(connection),
		func(node, connection): return node.is_valid_north_connection(connection))


func south_connection(new_node: WaveNode2D) -> Array[Vector3i]:
	return get_possible_connections(new_node,
		func(node, connection): return node.is_valid_north_connection(connection),
		func(node, connection): return node.is_valid_south_connection(connection))


func get_possible_connections(
		node: WaveNode2D,
		is_valid_connection_func: Callable,
		is_valid_opposite_func: Callable
) -> Array[Vector3i]:
	var possible_nodes: Array[Vector3i] = []
	if node != null:
		# Initialize possible nodes with z=0
		for wave_node in wave_node_array:
			var possible_node_pos: Vector3i = Vector3i(
					wave_node.tile_coords.x,
					wave_node.tile_coords.y,
					0
			)
			possible_nodes.append(possible_node_pos)
		# Check connections and update z-values
		for connection in possible_connections:
			if is_valid_connection_func.call(node, connection):
				for i in range(possible_nodes.size()):
					var node_pos: Vector2i = Vector2i(
							possible_nodes[i].x,
							possible_nodes[i].y
					)
					var possible_node = get_wave_node(node_pos)
					if is_valid_opposite_func.call(possible_node, connection):
						possible_nodes[i].z = 1
	else:
		# If no node, all nodes are possible (z=1)
		for wave_node in wave_node_array:
			var possible_node_pos: Vector3i = Vector3i(
					wave_node.tile_coords.x,
					wave_node.tile_coords.y,
					1
			)
			possible_nodes.append(possible_node_pos)
	return possible_nodes


func get_collapsing_node(pos: Vector2i) -> bool:
	# Get possible nodes for each direction
	var possible_nodes_north: Array[Vector3i]
	var possible_nodes_south: Array[Vector3i]
	var possible_nodes_west: Array[Vector3i]
	var possible_nodes_east: Array[Vector3i]
	
	var north_pos: Vector2i = Vector2i(pos.x, pos.y - 1)
	var south_pos: Vector2i = Vector2i(pos.x, pos.y + 1)
	var west_pos: Vector2i = Vector2i(pos.x - 1, pos.y)
	var east_pos: Vector2i = Vector2i(pos.x + 1, pos.y)
	
	var north_atlas_coords: Vector2i = tile_map_layer.get_cell_atlas_coords(north_pos)
	var south_atlas_coords: Vector2i = tile_map_layer.get_cell_atlas_coords(south_pos)
	var west_atlas_coords: Vector2i = tile_map_layer.get_cell_atlas_coords(west_pos)
	var east_atlas_coords: Vector2i = tile_map_layer.get_cell_atlas_coords(east_pos)
	
	var north_node: WaveNode2D = get_wave_node(north_atlas_coords)
	var south_node: WaveNode2D = get_wave_node(south_atlas_coords)
	var west_node: WaveNode2D = get_wave_node(west_atlas_coords)
	var east_node: WaveNode2D = get_wave_node(east_atlas_coords)
	
	possible_nodes_north = north_connection(north_node)
	possible_nodes_south = south_connection(south_node)
	possible_nodes_west = west_connection(west_node)
	possible_nodes_east = east_connection(east_node)
	
	# Find nodes that satisfy all directions
	var final_nodes: Array[Vector2i] = []
	for i in range(wave_node_array.size()):
		if (
				possible_nodes_west[i].z == 1 and
				possible_nodes_east[i].z == 1 and
				possible_nodes_north[i].z == 1 and
				possible_nodes_south[i].z == 1
		):
			final_nodes.append(wave_node_array[i].tile_coords)
	
	tile_map_possibilities[pos] = final_nodes
	# Return false if no valid nodes found
	if final_nodes.size() == tile_map_possibilities[pos].size():
		return false
	if final_nodes.is_empty():
		return false
	return true


func select_collapsing_node(pos: Vector2i) -> WaveNode2D:
	# Randomly select a final node
	var total_weight: float = 0.0
	for node_coords in tile_map_possibilities[pos]:
		var node = get_wave_node(node_coords)
		total_weight += node.spawn_weight

	var random_value: float = randf() * total_weight
	var cumulative_weight: float = 0.0
	for node_coords in tile_map_possibilities[pos]:
		var node = get_wave_node(node_coords)
		cumulative_weight += node.spawn_weight
		if random_value < cumulative_weight:
			return node
	# Fallback in case of rounding errors
	return null


func propagate(pos: Vector2i):
	var stack: Array[Vector2i] = [pos]
	while not stack.is_empty():
		var current: Vector2i = stack.pop_back()
		if (
				tile_map_layer.get_cell_atlas_coords(pos) != Vector2i(-1, -1) or
				abs(current.x) > map_size.x or
				abs(current.y) > map_size.y
		):
			continue
		if get_collapsing_node(current):
			stack.push_back(Vector2i(current.x, current.y - 1))
			stack.push_back(Vector2i(current.x + 1, current.y))
			stack.push_back(Vector2i(current.x, current.y + 1))
			stack.push_back(Vector2i(current.x - 1, current.y))


func collapse():
	while true:
		# Step 1: Find position with minimal entropy
		var min_entropy: int = wave_node_array.size() + 1  # Larger than any possible size initially
		var entropy_pos: Vector2i = Vector2i.ZERO
		var total_entropy: int = 0
		var has_unset_tiles: bool = false
		
		for x in range(-map_size.x, map_size.x + 1):
			for y in range(-map_size.y, map_size.y + 1):
				var pos: Vector2i = Vector2i(x, y)
				var pos_size: int = tile_map_possibilities[pos].size()
				total_entropy += pos_size
				if pos_size > 0 and pos_size < min_entropy:
					min_entropy = pos_size
					entropy_pos = pos
					has_unset_tiles = true
		
		# Step 2: Check termination conditions
		if total_entropy == 0 or not has_unset_tiles:
			print("Tilemap fully collapsed")
			return
		
		# Step 3: Select and set a tile
		var setter_node: WaveNode2D = select_collapsing_node(entropy_pos)
		if setter_node == null:
			print("Contradiction at position ", entropy_pos, ": No valid tile available")
			return  # Stop on contradiction; backtracking could be added here
			
		# Set the tile and clear possibilities
		tile_map_layer.set_cell(entropy_pos, source_id, setter_node.tile_coords, alternative_tile)
		tile_map_possibilities[entropy_pos].clear()
		
		if label != null:
			label.text = str(total_entropy)
		# Step 4: Propagate constraints to neighbors
		var thread01: Thread = Thread.new()
		var thread02: Thread = Thread.new()
		var thread03: Thread = Thread.new()
		var thread04: Thread = Thread.new()
		thread01.start(propagate.bind(entropy_pos + Vector2i(0, -1)))
		thread02.start(propagate.bind(entropy_pos + Vector2i(1, 0)))
		thread03.start(propagate.bind(entropy_pos + Vector2i(0, 1)))
		thread04.start(propagate.bind(entropy_pos + Vector2i(-1, 0)))
		thread01.wait_to_finish()
		thread02.wait_to_finish()
		thread03.wait_to_finish()
		thread04.wait_to_finish()


func random_collapse() -> void:
	var random_pos: Vector2i = Vector2i(randi() % map_size.x, randi() % map_size.y)
	tile_map_layer.set_cell(random_pos, source_id, Vector2i.ZERO, alternative_tile)
	tile_map_possibilities[random_pos].clear()
	propagate(random_pos + Vector2i(0, -1))
	propagate(random_pos + Vector2i(1, 0))
	propagate(random_pos + Vector2i(0, 1))
	propagate(random_pos + Vector2i(-1, 0))


func step_collapse() -> void:
	# Step 1: Find position with minimal entropy
	var min_entropy: int = wave_node_array.size() + 1  # Larger than any possible size initially
	var entropy_pos: Vector2i = Vector2i.ZERO
	var total_entropy: int = 0
	var has_unset_tiles: bool = false
	
	for x in range(-map_size.x, map_size.x + 1):
		for y in range(-map_size.y, map_size.y + 1):
			var pos: Vector2i = Vector2i(x, y)
			var pos_size: int = tile_map_possibilities[pos].size()
			total_entropy += pos_size
			if pos_size > 0 and pos_size < min_entropy:
				min_entropy = pos_size
				entropy_pos = pos
				has_unset_tiles = true
			elif pos_size == min_entropy and randi() % 2:
				min_entropy = pos_size
				entropy_pos = pos
	
	# Step 2: Check termination conditions
	if total_entropy == 0 or not has_unset_tiles:
		print("Tilemap fully collapsed")
		return
	
	# Step 3: Select and set a tile
	var setter_node: WaveNode2D = select_collapsing_node(entropy_pos)
	if setter_node == null:
		print("Contradiction at position ", entropy_pos, ": No valid tile available")
		return  # Stop on contradiction; backtracking could be added here
		
	# Set the tile and clear possibilities
	tile_map_layer.set_cell(entropy_pos, source_id, setter_node.tile_coords, alternative_tile)
	tile_map_possibilities[entropy_pos].clear()
	
	if label != null:
		label.text = str(total_entropy)
	# Step 4: Propagate constraints to neighbors
	var thread01: Thread = Thread.new()
	var thread02: Thread = Thread.new()
	var thread03: Thread = Thread.new()
	var thread04: Thread = Thread.new()
	thread01.start(propagate.bind(entropy_pos + Vector2i(0, -1)))
	thread02.start(propagate.bind(entropy_pos + Vector2i(1, 0)))
	thread03.start(propagate.bind(entropy_pos + Vector2i(0, 1)))
	thread04.start(propagate.bind(entropy_pos + Vector2i(-1, 0)))
	thread01.wait_to_finish()
	thread02.wait_to_finish()
	thread03.wait_to_finish()
	thread04.wait_to_finish()


func _ready() -> void:
	generate_wave_nodes()
	initialize_tile_map_possibilities()
	random_collapse()


func _process(_delta: float) -> void:
	if Input.is_action_pressed("step"):
		step_collapse()
	if Input.is_action_just_pressed("collapse"):
		collapse()
	if Input.is_action_just_pressed("clear"):
		clear_tiles()
		random_collapse()
