package game

import "vendor:raylib"

Game_Input :: struct {
	move_up: bool,
	move_right: bool,
	move_left: bool,
	move_down: bool
}


game_input_update :: proc(game_input: ^Game_Input) {
	game_input.move_up = raylib.IsKeyDown(.W)
	game_input.move_down = raylib.IsKeyDown(.S)
	game_input.move_left = raylib.IsKeyDown(.A)
	game_input.move_right = raylib.IsKeyDown(.D)
}
