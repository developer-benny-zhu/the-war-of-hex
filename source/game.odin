package game

import "core:c"
import "vendor:raylib"

run: bool

WINDOW_WIDTH :: 800
WINDOW_HEIGHT :: 600
WINDOW_TITLE :: "Hex Arena"
FPS :: 60
game_state: Game_State
init :: proc() {
	run = true
	raylib.SetConfigFlags({.WINDOW_RESIZABLE, .VSYNC_HINT})
	raylib.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, WINDOW_TITLE)
	raylib.SetTargetFPS(FPS)
	game_state_init(&game_state)
}

update :: proc() {
	game_state_update(&game_state, raylib.GetFrameTime())
	raylib.BeginDrawing()
	raylib.ClearBackground(raylib.RAYWHITE)
	raylib.BeginMode3D(game_state.camera)
	raylib.DrawGrid(20, 1.0)
    raylib.DrawCube({0.0, 1.0, 0.0}, 2.0, 2.0, 2.0, raylib.BLUE)
    raylib.DrawCubeWires({0.0, 1.0, 0.0}, 2.0, 2.0, 2.0, raylib.DARKBLUE)
	raylib.EndMode3D()

	raylib.EndDrawing()
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
