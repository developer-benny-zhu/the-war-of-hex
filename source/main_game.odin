package game

import "vendor:raylib"


MAIN_GAME_BACKGROUND_COLOR :: raylib.BLACK

main_game_update :: proc(game_state: ^Game_State) {
	raylib.BeginDrawing()
	raylib.ClearBackground(MAIN_GAME_BACKGROUND_COLOR)
	player_update(&game_state.player, game_state)

	raylib.EndDrawing()
}
