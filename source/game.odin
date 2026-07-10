package game

import "core:c"
import "vendor:raylib"

run: bool

WINDOW_WIDTH :: 720
WINDOW_HEIGHT :: 720
WINDOW_TITLE :: "Hex Arena"

init :: proc() {
	run = true
	raylib.SetConfigFlags({.WINDOW_RESIZABLE, .VSYNC_HINT})
	raylib.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, WINDOW_TITLE)
	raylib.InitAudioDevice()
}

update :: proc() {
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

