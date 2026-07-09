package game

import "core:c"
import "vendor:raylib"

run: bool

WINDOW_WIDTH :: 720
WINDOW_HEIGHT :: 720
WINDOW_TITLE :: "Hex Arena"
splash_screen: Splash_Screen


game_state: Game_State
init :: proc() {
	run = true
	raylib.SetConfigFlags({.WINDOW_RESIZABLE, .VSYNC_HINT})
	raylib.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, WINDOW_TITLE)
	raylib.InitAudioDevice()

	game_state_init(&game_state)
}

update :: proc() {
	delta_time := raylib.GetFrameTime()
	game_state_update(&game_state, delta_time)
	main_menu_update(&game_state.main_menu, game_state)
	free_all(context.temp_allocator)
}

parent_window_size_changed :: proc(width: int, height: int) {
	raylib.SetWindowSize(c.int(width), c.int(height))
}

shutdown :: proc() {
	raylib.CloseWindow()
}

should_run :: proc() -> bool {
	when ODIN_OS != .JS {
		if raylib.WindowShouldClose() {
			run = false
		}
	}

	return run
}
