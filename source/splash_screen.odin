package game

import "core:math"
import "core:math/linalg"
import "vendor:raylib"

BLACK_SCREEN_START     :: 0.0
BLACK_SCREEN_END       :: 1.0

COOKIE_SCREEN_START    :: 1.0
COOKIE_SCREEN_END      :: 3.5

ODIN_SCREEN_START      :: 3.5
ODIN_SCREEN_END        :: 6.5

WAR_SCREEN_START       :: 6.5
WAR_SCREEN_END         :: 9.5

TRANSITION_TIME        :: 0.5



Splash_Screen :: struct {
    timer: f32,
}

splash_screen_init :: proc(splash: ^Splash_Screen) {
    splash.timer = 0.0
}

splash_screen_update :: proc(splash: ^Splash_Screen, game_state: ^Game_State) {
    splash.timer += raylib.GetFrameTime()

    if splash.timer >= WAR_SCREEN_END {
        game_state.scene = .Main_Menu
        return
    }

    raylib.BeginDrawing()
    raylib.ClearBackground(raylib.BLACK)

    window_w := f32(raylib.GetScreenWidth())
    window_h := f32(raylib.GetScreenHeight())
    screen_center := linalg.Vector2f32{window_w / 2, window_h / 2}

    scale := window_h / f32(VIRTUAL_SCREEN_HEIGHT)

    switch splash.timer {
    case COOKIE_SCREEN_START ..< COOKIE_SCREEN_END:
        color := raylib.WHITE
        update_fade(&color, splash.timer, COOKIE_SCREEN_START, COOKIE_SCREEN_END, TRANSITION_TIME)
        
        font_size := i32(math.round(40 * scale))
        draw_text("Made by COOKIE POLICE", screen_center, raylib.GetFontDefault(), f32(font_size), .Center, tint = color)

    case ODIN_SCREEN_START ..< ODIN_SCREEN_END:
        color := raylib.WHITE
        update_fade(&color, splash.timer, ODIN_SCREEN_START, ODIN_SCREEN_END, TRANSITION_TIME)

        font_size := i32(math.round(40 * scale))
        text_pos := linalg.Vector2f32{screen_center.x, screen_center.y - (200 * scale)}
        draw_text("Made with Odin and Raylib", text_pos, raylib.GetFontDefault(), f32(font_size), .Center, tint = color)

        source := raylib.Rectangle{
            0,
            0,
            f32(game_state.assets.ginger_bill.width),
            f32(game_state.assets.ginger_bill.height),
        }
        
        texture_scale := linalg.Vector2f32{0.25 * scale, 0.25 * scale}
        draw_texture(game_state.assets.ginger_bill, source, screen_center, .Center, tint = color, scale = texture_scale)

    case WAR_SCREEN_START ..= WAR_SCREEN_END:
        color := raylib.WHITE
        update_fade(&color, splash.timer, WAR_SCREEN_START, WAR_SCREEN_END, TRANSITION_TIME)
        
        font_size := i32(math.round(60 * scale))
        draw_text("The War of Hex", screen_center, raylib.GetFontDefault(), f32(font_size), .Center, tint = color)
    }

    raylib.EndDrawing()
}

update_fade :: proc(color: ^raylib.Color, time, start_time, end_time, duration: f32) {
    if time < start_time + duration {
        t := math.clamp((time - start_time) / duration, 0.0, 1.0)
        color.a = u8(linalg.lerp(f32(0), f32(255), t))
    } else if time > end_time - duration {
        t := math.clamp((time - (end_time - duration)) / duration, 0.0, 1.0)
        color.a = u8(linalg.lerp(f32(255), f32(0), t))
    } else {
        color.a = 255
    }
}