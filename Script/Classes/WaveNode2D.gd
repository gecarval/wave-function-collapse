class_name WaveNode2D extends Node2D


@export var tile_coords: Vector2i
@export var valid_north_connection: Array[int]
@export var valid_south_connection: Array[int]
@export var valid_west_connection: Array[int]
@export var valid_east_connection: Array[int]


func _init(
		new_tile_coords: Vector2i = Vector2i.ZERO,
		north_valids: Array[int] = [-1],
		south_valids: Array[int] = [-1],
		west_valids: Array[int] = [-1],
		east_valids: Array[int] = [-1]
) -> void:
	tile_coords = new_tile_coords
	valid_north_connection = north_valids
	valid_south_connection = south_valids
	valid_west_connection = west_valids
	valid_east_connection = east_valids


func is_valid_north_connection(possible_connection: int) -> bool:
	if valid_north_connection != null:
		for x in valid_north_connection:
			if x == possible_connection:
				return true
	return false


func is_valid_south_connection(possible_connection: int) -> bool:
	if valid_south_connection != null:
		for x in valid_south_connection:
			if x == possible_connection:
				return true
	return false


func is_valid_west_connection(possible_connection: int) -> bool:
	if valid_west_connection != null:
		for x in valid_west_connection:
			if x == possible_connection:
				return true
	return false


func is_valid_east_connection(possible_connection: int) -> bool:
	if valid_east_connection != null:
		for x in valid_east_connection:
			if x == possible_connection:
				return true
	return false
