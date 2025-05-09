class_name WaveFunction2D extends Node2D


@export var source_id: int = 0
@export var alternative_tile: int = 0
@export var tile_map_layer: TileMapLayer
@export var map_size: Vector2i = Vector2i(32, 32)
@export var wave_node_array: Array[WaveNode2D]
@export var possible_connections: Array[int]


func _init(
		wave_node_array_list: Array[WaveNode2D] = [null],
		new_source_id: int = -1
) -> void:
	source_id = new_source_id
	wave_node_array = wave_node_array_list


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


func west_connection(node: WaveNode2D) -> Array[Vector3i]:
	return get_possible_connections(node,
		func(n, c): return n.is_valid_east_connection(c),
		func(n, c): return n.is_valid_west_connection(c))


func east_connection(node: WaveNode2D) -> Array[Vector3i]:
	return get_possible_connections(node,
		func(n, c): return n.is_valid_west_connection(c),
		func(n, c): return n.is_valid_east_connection(c))


func north_connection(node: WaveNode2D) -> Array[Vector3i]:
	return get_possible_connections(node,
		func(n, c): return n.is_valid_south_connection(c),
		func(n, c): return n.is_valid_north_connection(c))


func south_connection(node: WaveNode2D) -> Array[Vector3i]:
	return get_possible_connections(node,
		func(n, c): return n.is_valid_north_connection(c),
		func(n, c): return n.is_valid_south_connection(c))


func get_possible_connections(
		node: WaveNode2D, is_valid_connection_func: Callable,
		is_valid_opposite_func: Callable
) -> Array[Vector3i]:
	var possible_nodes: Array[Vector3i] = []
	if node != null:
		# Initialize possible nodes with z=0
		for wave_node in wave_node_array:
			possible_nodes.append(Vector3i(wave_node.tile_coords.x, wave_node.tile_coords.y, 0))
		# Check connections and update z-values
		for connection in possible_connections:
			if is_valid_connection_func.call(node, connection):
				for i in range(possible_nodes.size()):
					var possible_node = get_wave_node(Vector2i(possible_nodes[i].x, possible_nodes[i].y))
					if is_valid_opposite_func.call(possible_node, connection):
						possible_nodes[i].z = 1
	else:
		# If no node, all nodes are possible (z=1)
		for wave_node in wave_node_array:
			possible_nodes.append(Vector3i(wave_node.tile_coords.x, wave_node.tile_coords.y, 1))
	return possible_nodes


func get_collapsing_node(pos: Vector2i) -> WaveNode2D:
	# Get possible nodes for each direction
	var possible_nodes_north: Array[Vector3i] = north_connection(get_wave_node(tile_map_layer.get_cell_atlas_coords(Vector2i(pos.x, pos.y - 1))))
	var possible_nodes_south: Array[Vector3i] = south_connection(get_wave_node(tile_map_layer.get_cell_atlas_coords(Vector2i(pos.x, pos.y + 1))))
	var possible_nodes_west: Array[Vector3i] = west_connection(get_wave_node(tile_map_layer.get_cell_atlas_coords(Vector2i(pos.x - 1, pos.y))))
	var possible_nodes_east: Array[Vector3i] = east_connection(get_wave_node(tile_map_layer.get_cell_atlas_coords(Vector2i(pos.x + 1, pos.y))))
	
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
	var result: Vector2i = final_nodes[randi() % final_nodes.size()]
	return get_wave_node(result)


func select_connection(pos: Vector2i) -> bool:
	var setter_node: WaveNode2D
	if tile_map_layer.get_cell_atlas_coords(pos) != Vector2i(-1, -1):
		return false
	setter_node = get_collapsing_node(pos)
	if setter_node == null:
		return false
	tile_map_layer.set_cell(pos, 0, setter_node.tile_coords, 0)
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
	return


func _ready() -> void:
	tile_map_layer.set_cell(Vector2i.ZERO, 0, Vector2i(4, 2), 0)
	propagate(Vector2i(0, 1))
