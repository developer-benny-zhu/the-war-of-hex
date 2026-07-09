package game

import "core:fmt"
import "vendor:raylib"

Main_Menu :: struct {
	timer: f32,
}
main_menu_update :: proc(main_menu: ^Main_Menu, game_state: ^Game_State) {
	main_menu.timer += raylib.GetFrameTime()
	raylib.BeginDrawing()
	raylib.BeginMode2D(game_state.ui_camera)
	color := raylib.WHITE
	update_fade_in(&color, main_menu.timer, 0, 1)
	raylib.ClearBackground(raylib.BLACK)

	draw_text(
		"Hex Arena",
		{WINDOW_WIDTH / 2, WINDOW_HEIGHT / 2 - 200},
		raylib.GetFontDefault(),
		32,
		.Center,
		tint = color,
	)
	if button(
		"Play",
		{WINDOW_WIDTH / 2, WINDOW_HEIGHT / 2 + 100},
		{200, 30},
		game_state.ui_camera,
		.Center,
	) {
        raylib.DisableCursor()
        game_state.scene = .Main_Game
	}
	raylib.EndMode2D()
	raylib.EndDrawing()
}
