package game

import "core:math"
import "core:math/linalg"
import "vendor:raylib"

SENSITIVITY :: 0.05
SPEED :: 5
Player :: struct {
	position: linalg.Vector3f32,
	velocity: linalg.Vector3f32,
	yaw:      f32,
	pitch:    f32,
}


player_init :: proc(player: ^Player) {
}

player_update :: proc(player: ^Player) {
	mouse_delta := raylib.GetMouseDelta()
	player.yaw -= mouse_delta.x * SENSITIVITY
	player.pitch -= mouse_delta.y * SENSITIVITY
	player.pitch = clamp(player.pitch, -89, 89)
    forward := player_forward_direction(player^)
	forward_ground := linalg.normalize(linalg.Vector3f32{forward.x, 0, forward.z})
	right := linalg.normalize(linalg.cross(forward_ground, linalg.Vector3f32{0, 1, 0}))
	move_direction := linalg.Vector3f32{0, 0, 0}
	if raylib.IsKeyDown(.W) {
		move_direction += forward_ground
	}
	if raylib.IsKeyDown(.S) {
		move_direction -= forward_ground
	}
	if raylib.IsKeyDown(.D) {
		move_direction += right
	}
	if raylib.IsKeyDown(.A) {
		move_direction -= right
	}
	if linalg.length(move_direction) > 0 {
		move_direction = linalg.normalize(move_direction)
	}
	player.velocity = move_direction * SPEED
	player.position += player.velocity * raylib.GetFrameTime()
}

player_forward_direction :: proc(player: Player) -> linalg.Vector3f32 {
    yaw_radians := linalg.to_radians(player.yaw)
	pitch_radians := linalg.to_radians(player.pitch)
	forward: linalg.Vector3f32
	forward.x = math.cos(pitch_radians) * math.sin(yaw_radians)
	forward.y = math.sin(pitch_radians)
	forward.z = math.cos(pitch_radians) * math.cos(yaw_radians)
	forward = linalg.normalize(forward)
    return forward
}

player_head_position :: proc(player: Player) -> linalg.Vector3f32 {
    return player.position + linalg.Vector3f32 {0, 4, 0}
}

player_is_moving :: proc(player: Player) -> bool {
	return linalg.length(player.velocity) > 0
}