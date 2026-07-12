package game

import "core:math/linalg"
import "core:math"




get_hexagon_height :: proc(diameter: f32) -> f32 {
	return diameter * (math.sqrt_f32(3) / 2)
}

get_distance :: proc(position_1: linalg.Vector2f32, position_2: linalg.Vector2f32) -> f32 {
	position_difference := position_2 - position_1
	x_squared := math.pow(position_difference.x, 2)
	y_squared := math.pow(position_difference.y, 2)
	distance := math.sqrt(x_squared + y_squared)
	return distance
}



get_angle_radians :: proc(position_1: linalg.Vector2f32, position_2: linalg.Vector2f32) -> f32 {
	position_difference := position_2 - position_1
	adjacent := position_difference.x
	opposite := position_difference.y
	angle_radians := math.atan2(opposite, adjacent)
	return angle_radians
}

get_angle_degrees :: proc(position_1: linalg.Vector2f32, position_2: linalg.Vector2f32) -> f32 {
	angle_radians := get_angle_radians(position_1, position_2)
	angle_degrees := radians_to_degrees(angle_radians)
	return angle_degrees
}

radians_to_degrees :: proc(value: f32) -> f32 {
	return value * (180/math.PI)
}

degrees_to_radians :: proc(value: f32) -> f32 {
	return value * (math.PI / 180)
}

is_even :: proc(value: i32) -> bool {
	return i32(value) % 2 == 0
}