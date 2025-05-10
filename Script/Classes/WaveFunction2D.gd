class_name WaveFunction2D extends Node2D


@export var source_id: int = 0
@export var alternative_tile: int = 0
@export var tile_map_layer: TileMapLayer
@export var map_size: Vector2i = Vector2i(32, 32)
@export var wave_node_cluster: Node2D
var wave_node_array: Array[WaveNode2D]
var possible_connections: Array[int]


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


func get_collapsing_node(pos: Vector2i) -> WaveNode2D:
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
		if (possible_nodes_west[i].z == 1 and
			possible_nodes_east[i].z == 1 and
			possible_nodes_north[i].z == 1 and
			possible_nodes_south[i].z == 1):
			final_nodes.append(wave_node_array[i].tile_coords)
	
	# Return null if no valid nodes found
	if final_nodes.is_empty():
		return null
	
	# Randomly select a final node
	var total_weight: float = 0.0
	for node_coords in final_nodes:
		var node = get_wave_node(node_coords)
		total_weight += node.spawn_weight

	var random_value: float = randf() * total_weight
	var cumulative_weight: float = 0.0
	for node_coords in final_nodes:
		var node = get_wave_node(node_coords)
		cumulative_weight += node.spawn_weight
		if random_value < cumulative_weight:
			return node
	# Fallback in case of rounding errors
	return null


func select_connection(pos: Vector2i) -> bool:
	var setter_node: WaveNode2D
	if tile_map_layer.get_cell_atlas_coords(pos) != Vector2i(-1, -1):
		return false
	setter_node = get_collapsing_node(pos)
	if setter_node == null:
		return false
	tile_map_layer.set_cell(pos, source_id, setter_node.tile_coords, alternative_tile)
	return true


func propagate(pos: Vector2i) -> void:
	var stack: Array[Vector2i] = [pos]
	while not stack.is_empty():
		var current: Vector2i = stack.pop_back()
		if abs(current.x) > map_size.x or abs(current.y) > map_size.y:
			continue
		if select_connection(current):
			stack.push_back(Vector2i(current.x - 1, current.y))
			stack.push_back(Vector2i(current.x, current.y + 1))
			stack.push_back(Vector2i(current.x + 1, current.y))
			stack.push_back(Vector2i(current.x, current.y - 1))


func collapse():
	propagate(Vector2i(0, 1))


func _ready() -> void:
	generate_wave_nodes()
	collapse()
