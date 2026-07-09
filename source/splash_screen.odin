package game


import "core:math"
import "core:math/linalg"
import "vendor:raylib"


BLACK_SCREEN_START :: 0
BLACK_SCREEN_END :: 1

LOGO_SCREEN_START :: 1
LOGO_SCREEN_END :: 3


LOGO_SCREEN_TEXT :: "A Game By COOKIE POLICE"
LOGO_SCREEN_FONT_SIZE :: 32
LOGO_SCREEN_FONT_COlOR :: raylib.WHITE

MADE_WITH_SCREEN_START :: 3
MADE_WITH_SCREEN_END :: 7
MADE_WITH_SCREEN_FONT_COLOR :: raylib.WHITE
MADE_WITH_SCREEN_TEXT :: "Made With Odin and Raylib"
MADE_WITH_SCREEN_FONT_SIZE :: 32

TRANSITION_TIME :: 0.3

// HOLY hard coding, good thing im never touching this code ever again in my life... maybe... if my OCD doesn't get to me

Splash_Screen :: struct {
	timer: f32,
}


splash_screen_update :: proc(splash_screen: ^Splash_Screen, game_state: ^Game_State) {
	splash_screen.timer += raylib.GetFrameTime()
	raylib.BeginDrawing()
	raylib.BeginMode2D(game_state.ui_camera)
	switch splash_screen.timer {
	case BLACK_SCREEN_START ..< BLACK_SCREEN_END:
		raylib.ClearBackground(raylib.BLACK)
	case LOGO_SCREEN_START ..< LOGO_SCREEN_END:
		raylib.ClearBackground(raylib.BLACK)
		color := LOGO_SCREEN_FONT_COlOR
		update_fade(
			&color,
			splash_screen.timer,
			LOGO_SCREEN_START,
			LOGO_SCREEN_END,
			TRANSITION_TIME,
		)
		draw_text(
			LOGO_SCREEN_TEXT,
			{WINDOW_WIDTH / 2, WINDOW_HEIGHT / 2},
			raylib.GetFontDefault(),
			LOGO_SCREEN_FONT_SIZE,
			.Center,
			tint = color,
		)
	case MADE_WITH_SCREEN_START ..< MADE_WITH_SCREEN_END:
		raylib.ClearBackground(raylib.BLACK)
		color := MADE_WITH_SCREEN_FONT_COLOR
		update_fade(
			&color,
			splash_screen.timer,
			MADE_WITH_SCREEN_START,
			MADE_WITH_SCREEN_END,
			TRANSITION_TIME,
		)
		draw_text(
			MADE_WITH_SCREEN_TEXT,
			{WINDOW_WIDTH / 2, WINDOW_HEIGHT / 2 - 200},
			raylib.GetFontDefault(),
			MADE_WITH_SCREEN_FONT_SIZE,
			.Center,
			tint = color,
		)
		source := raylib.Rectangle {
			0,
			0,
			f32(game_state.assets.ginger_bill.width),
			f32(game_state.assets.ginger_bill.height),
		}
		position := linalg.Vector2f32 {
			WINDOW_WIDTH / 2,
			WINDOW_HEIGHT / 2,
		}
		draw_texture(
			game_state.assets.ginger_bill,
			source,
			position,
			.Center,
			tint = color,
			scale = {0.25, 0.25},
		)
		case:
			game_state.scene = .Main_Menu



	}
	raylib.EndMode2D()
	raylib.EndDrawing()
}

fade_in :: proc(color: ^raylib.Color, elapsed: f32, duration: f32) {
	t: f32 = math.clamp(elapsed / duration, 0.0, 1.0)
	color.a = u8(linalg.lerp(f32(0), f32(255), t))
}

fade_out :: proc(color: ^raylib.Color, elapsed: f32, duration: f32) {
	t: f32 = math.clamp(elapsed / duration, 0.0, 1.0)
	color.a = u8(linalg.lerp(f32(255), f32(0), t))
}


update_fade :: proc(
	color: ^raylib.Color,
	time: f32,
	start_time: f32,
	end_time: f32,
	duration: f32,
) {
	update_fade_in(color, time, start_time, duration)
	update_fade_out(color, time, end_time, duration)
}

update_fade_in :: proc(color: ^raylib.Color, time: f32, start_time: f32, duration: f32) {
	if time < start_time + duration {
		fade_in(color, time - start_time, duration)
	}
}

update_fade_out :: proc(color: ^raylib.Color, time: f32, end_time: f32, duration: f32) {
	if time > end_time - duration {
		fade_out(color, time - (end_time - duration), duration)
	}
}
