package game

import "core:math/linalg"
import "vendor:raylib"

@(private = "file")
credits_scroll_time: f32 = 0.0

credits_update :: proc(game_state: ^Game_State) {
	if raylib.IsKeyPressed(raylib.KeyboardKey.ESCAPE) {
		credits_scroll_time = 0.0
		game_state.scene = .Main_Menu
		main_menu_init(&game_state.main_menu, game_state)
	}

	credits_scroll_time += raylib.GetFrameTime() * 45.0

	raylib.BeginDrawing()
	raylib.ClearBackground(raylib.Color{15, 15, 22, 255})

	window_w := f32(raylib.GetScreenWidth())
	window_h := f32(raylib.GetScreenHeight())
	screen_center := linalg.Vector2f32{window_w / 2, window_h / 2}

	draw_background_effects(window_w, window_h)

	start_y := window_h - credits_scroll_time

	current_y := start_y
	font := raylib.GetFontDefault()

	draw_text("CREDITS", {screen_center.x, current_y}, font, 48, .Center)
	current_y += 80

	draw_text("Graphics & Art", {screen_center.x, current_y}, font, 24, .Center)
	current_y += 35
	draw_text("Big thanks to Kenney (kenney.nl)", {screen_center.x, current_y}, font, 32, .Center)
	draw_text("for the amazing game assets.", {screen_center.x, current_y + 35}, font, 32, .Center)
	current_y += 120

	draw_text("Built With", {screen_center.x, current_y}, font, 24, .Center)
	current_y += 35
	draw_text(
		"Odin Programming Language & Raylib",
		{screen_center.x, current_y},
		font,
		32,
		.Center,
	)
	current_y += 150

	if current_y < -50 {
		credits_scroll_time = 0
	}

	instruction_color := raylib.Color{200, 200, 200, 180}
	raylib.DrawRectangle(0, i32(window_h - 50), i32(window_w), 50, raylib.Color{0, 0, 0, 150})
	draw_text(
		"Press ESC to return to main menu",
		{screen_center.x, window_h - 35},
		font,
		20,
		.Center,
	)

	raylib.EndDrawing()
}

draw_background_effects :: proc(w, h: f32) {
	grid_size :: 60
	grid_color := raylib.Color{255, 255, 255, 10}

	for x: f32 = 0; x < w; x += grid_size {
		raylib.DrawLineV({x, 0}, {x, h}, grid_color)
	}
	for y: f32 = 0; y < h; y += grid_size {
		raylib.DrawLineV({0, y}, {w, y}, grid_color)
	}
}
