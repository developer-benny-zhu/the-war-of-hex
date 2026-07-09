package game

import "core:math"
import "vendor:raylib"

Camera_Mode :: enum u8 {
	First_Person,
}

Scene :: enum u8 {
	Splash_Screen,
	Main_Menu,
	Main_Game,
}


Game_State :: struct {
	scene:             Scene,
	main_menu:         Main_Menu,
	splash_screen:     Splash_Screen,
	player:            Player,
	world_camera:      raylib.Camera3D,
	view_model_camera: raylib.Camera3D,
	ui_camera:         raylib.Camera2D,
	view_model:        View_Model,
	camera_mode:       Camera_Mode,
	assets:            Assets,
	crosshair:         Crosshair,
	ui_scale:          f32,
}

world_camera_update :: proc(game_state: ^Game_State) {
	switch game_state.camera_mode {
	case .First_Person:
		game_state.world_camera.position = player_head_position(game_state.player)
		game_state.world_camera.target =
			game_state.world_camera.position + player_forward_direction(game_state.player)
	}
}

view_model_camera_init :: proc(camera_3d: ^raylib.Camera3D) {
	camera_3d.target = {0, 0, -1}
	camera_3d.up = {0, 1, 0}
	camera_3d.fovy = 60
	camera_3d.projection = .PERSPECTIVE
}

game_state_init :: proc(game_state: ^Game_State) {
	game_state.world_camera.fovy = 60
	game_state.world_camera.projection = .PERSPECTIVE
	game_state.world_camera.up = {0, 1, 0}
	view_model_camera_init(&game_state.view_model_camera)
	assets_init(&game_state.assets)
	player_init(&game_state.player)
	crosshair_init(&game_state.crosshair)
}

game_state_update :: proc(game_state: ^Game_State, delta_time: f32) {
	switch game_state.scene {
	case .Splash_Screen:
		splash_screen_update(&game_state.splash_screen, game_state)
		ui_camera_update(&game_state.ui_camera)
	case .Main_Menu:
		main_menu_update(&game_state.main_menu, game_state)
		ui_camera_update(&game_state.ui_camera)
	case .Main_Game:
		world_camera_update(game_state)
		main_game_update(game_state)
	}
}

ui_camera_update :: proc(ui_camera: ^raylib.Camera2D) {
	scale_x := f32(raylib.GetScreenWidth()) / f32(WINDOW_WIDTH)
	scale_y := f32(raylib.GetScreenHeight()) / f32(WINDOW_HEIGHT)

	zoom := math.min(scale_x, scale_y)

	game_state.ui_camera.zoom = zoom
	game_state.ui_camera.rotation = 0
	game_state.ui_camera.target = {0, 0}
	game_state.ui_camera.offset = {
		(f32(raylib.GetScreenWidth()) - f32(WINDOW_WIDTH) * zoom) / 2,
		(f32(raylib.GetScreenHeight()) - f32(WINDOW_HEIGHT) * zoom) / 2,
	}
}
game_state_destroy :: proc(game_state: ^Game_State) {
	assets_destroy(&game_state.assets)
}
