package game

import "core:c"
import "vendor:raylib"

run: bool

VIRTUAL_SCREEN_WIDTH :: 720
VIRTUAL_SCREEN_HEIGHT :: 720
WINDOW_TITLE :: "Hex Arena"

game_state: Game_State

init :: proc() {
	run = true
	raylib.SetConfigFlags({.WINDOW_RESIZABLE, .VSYNC_HINT})
	raylib.InitWindow(VIRTUAL_SCREEN_WIDTH, VIRTUAL_SCREEN_HEIGHT, WINDOW_TITLE)
	raylib.InitAudioDevice()
	game_state_init(&game_state)
}

update :: proc() {
	game_state_update(&game_state)
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