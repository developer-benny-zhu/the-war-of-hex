package game

import "vendor:raylib"

Camera_Mode :: enum u8 {
	First_Person,
}


Game_State :: struct {
	player:      Player,
	camera:      raylib.Camera3D,
	camera_mode: Camera_Mode,
}

camera_update :: proc(game_state: ^Game_State) {
	switch game_state.camera_mode {
	case .First_Person:
		game_state.camera.position = player_head_position(game_state.player)
		game_state.camera.target =
			game_state.camera.position + player_forward_direction(game_state.player)
	}
}
game_state_init :: proc(game_state: ^Game_State) {
	game_state.camera.fovy = 60
	game_state.camera.projection = .PERSPECTIVE
	game_state.camera.up = {0, 1, 0}
	player_init(&game_state.player)
}

game_state_update :: proc(game_state: ^Game_State, delta_time: f32) {
	camera_update(game_state)
	player_update(&game_state.player, delta_time)
}
