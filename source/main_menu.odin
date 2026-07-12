package game

import "core:math"
import "core:math/linalg"
import "vendor:raylib"

Main_Menu :: struct {}

main_menu_init :: proc(menu: ^Main_Menu, game_state: ^Game_State) {
	raylib.PlayMusicStream(game_state.assets.menu_music)
}

main_menu_update :: proc(menu: ^Main_Menu, game_state: ^Game_State) {
	raylib.UpdateMusicStream(game_state.assets.menu_music)

	raylib.BeginDrawing()
	raylib.ClearBackground(raylib.Color{10, 10, 15, 255})

	window_w := f32(raylib.GetScreenWidth())
	window_h := f32(raylib.GetScreenHeight())
	screen_center := linalg.Vector2f32{window_w / 2, window_h / 2}
	scale := window_h / f32(VIRTUAL_SCREEN_HEIGHT)

	time := f32(raylib.GetTime())

	draw_menu_background(window_w, window_h, screen_center, scale, time)

	font := raylib.GetFontDefault()
	title_size := f32(math.round(60 * scale))
	title_pos := linalg.Vector2f32{screen_center.x, screen_center.y - (120 * scale)}

	text_bounce := f32(math.sin(time * 2.0)) * (8 * scale)
	current_title_pos := title_pos + {0, text_bounce}

	for i in 1 ..= 3 {
		layer_offset := f32(i) * 2.0 * scale
		layer_pulse := f32(math.sin(time * 4.0 + f32(i))) * 1.5 * scale
		layer_color := raylib.Color{20, 15, 30, u8(150 / i)}

		draw_text(
			"War of Hex",
			current_title_pos + {layer_offset + layer_pulse, layer_offset},
			font,
			title_size,
			.Center,
			tint = layer_color,
		)
	}

	shadow_offset := 4 * scale
	draw_text(
		"War of Hex",
		current_title_pos + {shadow_offset, shadow_offset},
		font,
		title_size,
		.Center,
		tint = raylib.Color{5, 5, 8, 220},
	)

	title_color := raylib.GOLD
	color_pulse := 0.5 + 0.5 * f32(math.sin(time * 3.0))
	title_color.r = u8(220 + (35 * color_pulse))
	title_color.g = u8(180 + (35 * (1.0 - color_pulse)))

	draw_text("War of Hex", current_title_pos, font, title_size, .Center, tint = title_color)

	button_style := Button_Style {
		font             = font,
		font_size        = 24 * scale,
		text_color       = raylib.WHITE,
		normal_color     = raylib.Color{35, 35, 50, 200},
		hover_color      = raylib.Color{55, 55, 75, 255},
		pressed_color    = raylib.Color{25, 25, 35, 255},
		border_color     = raylib.GOLD,
		border_thickness = 2,
		roundness        = 0.25,
		segments         = 8,
	}

	button_width := (260.0 + f32(math.sin(time * 2.5)) * 4.0) * scale
	button_height := 50.0 * scale

	play_rect := raylib.Rectangle {
		screen_center.x - button_width / 2,
		screen_center.y + (30 * scale),
		button_width,
		button_height,
	}

	if button(play_rect, "PLAY", button_style) {
		raylib.StopMusicStream(game_state.assets.menu_music)
		game_state.scene = .World
	}

	credits_rect := raylib.Rectangle {
		screen_center.x - button_width / 2,
		screen_center.y + (100 * scale),
		button_width,
		button_height,
	}

	if button(credits_rect, "CREDITS", button_style) {
		raylib.StopMusicStream(game_state.assets.menu_music)
		game_state.scene = .Credits
	}

	raylib.EndDrawing()
}

draw_menu_background :: proc(w, h: f32, center: linalg.Vector2f32, scale: f32, time: f32) {
	grid_size :: 60
	grid_shift_x := f32(math.sin(time * 0.5)) * 10.0
	grid_shift_y := time * 15.0

	grid_color := raylib.Color{255, 255, 255, 6}

	for x := i32(grid_shift_x) % grid_size; f32(x) < w; x += grid_size {
		raylib.DrawLineV({f32(x), 0}, {f32(x), h}, grid_color)
	}
	for y := i32(grid_shift_y) % grid_size; f32(y) < h; y += grid_size {
		raylib.DrawLineV({0, f32(y)}, {w, f32(y)}, grid_color)
	}

	accent_pulse := 0.5 + 0.5 * f32(math.sin(time * 1.0))
	accent_color := raylib.Color{255, 215, 0, u8(8 + 8 * accent_pulse)}
	raylib.DrawCircleGradient(
		i32(center.x),
		i32(center.y),
		350 * scale,
		accent_color,
		raylib.BLANK,
	)

	pulse_1 := 1.0 + (f32(math.sin(time * 1.2)) * 0.10)
	raylib.DrawPolyLinesEx(
		{center.x, center.y},
		6,
		160.0 * scale * pulse_1,
		time * 1.5,
		2.5 * scale,
		raylib.Color{255, 215, 0, 20},
	)

	pulse_2 := 1.0 + (f32(math.sin(time * 1.8 + 0.5)) * 0.07)
	raylib.DrawPolyLinesEx(
		{center.x, center.y},
		6,
		230.0 * scale * pulse_2,
		-time * 2.2,
		1.5 * scale,
		raylib.Color{100, 150, 255, 15},
	)

	pulse_3 := 1.0 + (f32(math.sin(time * 0.6 + 1.2)) * 0.15)
	raylib.DrawPolyLinesEx(
		{center.x, center.y},
		6,
		310.0 * scale * pulse_3,
		time * 0.8,
		1.0 * scale,
		raylib.Color{255, 255, 255, 10},
	)

	for i in 0 ..< 4 {
		seed := f32(i) * 1.57
		p_time := time * 0.8 + seed

		p_radius := (280.0 + f32(math.sin(time * 0.4 + seed)) * 60.0) * scale
		p_x := center.x + f32(math.cos(p_time)) * p_radius
		p_y := center.y + f32(math.sin(p_time)) * p_radius

		p_size := (6.0 + f32(math.sin(time * 3.0 + seed)) * 3.0) * scale
		p_alpha := u8(20 + 15 * f32(math.sin(time * 2.0 + seed)))

		raylib.DrawPoly({p_x, p_y}, 6, p_size, time * 5.0, raylib.Color{255, 230, 150, p_alpha})
	}
}
