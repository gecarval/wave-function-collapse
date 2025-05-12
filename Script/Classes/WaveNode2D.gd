class_name WaveNode2D extends Node2D


@export var tile_coords: Vector2i
@export var spawn_weight: float = 10
@export var valid_north_connection: Array[int]
@export var valid_south_connection: Array[int]
@export var valid_west_connection: Array[int]
@export var valid_east_connection: Array[int]


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
