class_name WaveFunction2D extends Node2D


@export var source_id: int = 0
@export var alternative_tile: int = 0
@export var tile_map_layer: TileMapLayer
@export var map_size: Vector2i = Vector2i(4, 4)
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


func collapse():
	return


func west_connection(node: WaveNode2D) -> Array[Vector3i]:
	var possible_nodes: Array[Vector3i]
	var index: int
	if node != null:
		for wave_node in wave_node_array:
			possible_nodes.append(Vector3i(wave_node.tile_coords.x, wave_node.tile_coords.y, 0))
		for connection in possible_connections:
			if node.is_valid_east_connection(connection):
				index = 0
				for possible_node in possible_nodes:
					if get_wave_node(Vector2i(possible_node.x, possible_node.y)).is_valid_west_connection(connection):
						possible_nodes[index].z = 1
					index += 1
	else:
		for wave_node in wave_node_array:
			possible_nodes.append(Vector3i(wave_node.tile_coords.x, wave_node.tile_coords.y, 1))
	return possible_nodes


func east_connection(node: WaveNode2D) -> Array[Vector3i]:
	var possible_nodes: Array[Vector3i]
	var index: int
	if node != null:
		for wave_node in wave_node_array:
			possible_nodes.append(Vector3i(wave_node.tile_coords.x, wave_node.tile_coords.y, 0))
		for connection in possible_connections:
			if node.is_valid_west_connection(connection):
				index = 0
				for possible_node in possible_nodes:
					if get_wave_node(Vector2i(possible_node.x, possible_node.y)).is_valid_east_connection(connection):
						possible_nodes[index].z = 1
					index += 1
	else:
		for wave_node in wave_node_array:
			possible_nodes.append(Vector3i(wave_node.tile_coords.x, wave_node.tile_coords.y, 1))
	return possible_nodes


func north_connection(node: WaveNode2D) -> Array[Vector3i]:
	var possible_nodes: Array[Vector3i]
	var index: int
	if node != null:
		for wave_node in wave_node_array:
			possible_nodes.append(Vector3i(wave_node.tile_coords.x, wave_node.tile_coords.y, 0))
		for connection in possible_connections:
			if node.is_valid_south_connection(connection):
				index = 0
				for possible_node in possible_nodes:
					if get_wave_node(Vector2i(possible_node.x, possible_node.y)).is_valid_north_connection(connection):
						possible_nodes[index].z = 1
					index += 1
	else:
		for wave_node in wave_node_array:
			possible_nodes.append(Vector3i(wave_node.tile_coords.x, wave_node.tile_coords.y, 1))
	return possible_nodes


func south_connection(node: WaveNode2D) -> Array[Vector3i]:
	var possible_nodes: Array[Vector3i]
	var index: int
	if node != null:
		for wave_node in wave_node_array:
			possible_nodes.append(Vector3i(wave_node.tile_coords.x, wave_node.tile_coords.y, 0))
		for connection in possible_connections:
			if node.is_valid_north_connection(connection):
				index = 0
				for possible_node in possible_nodes:
					if get_wave_node(Vector2i(possible_node.x, possible_node.y)).is_valid_south_connection(connection):
						possible_nodes[index].z = 1
					index += 1
	else:
		for wave_node in wave_node_array:
			possible_nodes.append(Vector3i(wave_node.tile_coords.x, wave_node.tile_coords.y, 1))
	return possible_nodes


func get_collapsing_node(pos: Vector2i) -> WaveNode2D:
	var possible_nodes_north: Array[Vector3i]
	var possible_nodes_south: Array[Vector3i]
	var possible_nodes_west: Array[Vector3i]
	var possible_nodes_east: Array[Vector3i]
	var final_nodes: Array[Vector2i]
	var atlas_coords: Vector2i
	atlas_coords = tile_map_layer.get_cell_atlas_coords(Vector2i(pos.x - 1, pos.y))
	possible_nodes_west = west_connection(get_wave_node(atlas_coords))
	atlas_coords = tile_map_layer.get_cell_atlas_coords(Vector2i(pos.x, pos.y + 1))
	possible_nodes_south = south_connection(get_wave_node(atlas_coords))
	atlas_coords = tile_map_layer.get_cell_atlas_coords(Vector2i(pos.x + 1, pos.y))
	possible_nodes_east = east_connection(get_wave_node(atlas_coords))
	atlas_coords = tile_map_layer.get_cell_atlas_coords(Vector2i(pos.x, pos.y - 1))
	possible_nodes_north = north_connection(get_wave_node(atlas_coords))
	var check_error: int = 0
	for possible_node in possible_nodes_north:
		check_error += possible_node.z
	for possible_node in possible_nodes_south:
		check_error += possible_node.z
	for possible_node in possible_nodes_east:
		check_error += possible_node.z
	for possible_node in possible_nodes_west:
		check_error += possible_node.z
	if check_error == 0:
		return null
	var index: int = 0
	for wave_node in wave_node_array:
		if (
			possible_nodes_west[index].z == 1 and
			possible_nodes_east[index].z == 1 and
			possible_nodes_north[index].z == 1 and
			possible_nodes_south[index].z == 1
		):
			final_nodes.append(wave_node_array[index].tile_coords)
		index += 1
	var result: Vector2i
	if final_nodes != []:
		result = final_nodes[randi() % final_nodes.size()]
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


func propagate(pos: Vector2i) -> bool:
	if abs(pos.x) > map_size.x or abs(pos.y) > map_size.y:
		return false
	if select_connection(pos) == true:
		if propagate(Vector2i(pos.x - 1, pos.y)):
			propagate(pos)
			return true
		if propagate(Vector2i(pos.x, pos.y + 1)):
			propagate(pos)
			return true
		if propagate(Vector2i(pos.x + 1, pos.y)):
			propagate(pos)
			return true
		if propagate(Vector2i(pos.x, pos.y - 1)):
			propagate(pos)
			return true
	return false


func _ready() -> void:
	tile_map_layer.set_cell(Vector2i.ZERO, 0, Vector2i(4, 2), 0)
	propagate(Vector2i(0, 1))
