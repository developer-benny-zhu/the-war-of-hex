package game

import "vendor:raylib"
import "core:math/linalg"
import "core:math"

draw_hexagon_floor :: proc(grid_width: i32, grid_height: i32, hexagon_radius: f32, hexagon_height : f32 = 0.5) {
	for vertical_index in 0 ..< grid_height {
		for horizontal_index in 0 ..< grid_width {
			x_offset := (f32(horizontal_index) + f32(vertical_index % 2) * 0.5) * (math.SQRT_THREE * hexagon_radius)
			z_offset := f32(vertical_index) * (1.5 * hexagon_radius)

			center_position := linalg.Vector3f32{x_offset, -hexagon_height / 2, z_offset}

			draw_hexagon_3d(
				center_position,
				linalg.Vector3f32{0.0, 0.0, 0.0},
				hexagon_radius,
				hexagon_height,
                .Center,
			)
		}
	}
}

main_game_update :: proc(game_state: ^Game_State) {
	raylib.BeginDrawing()
	raylib.ClearBackground(raylib.WHITE)
	raylib.BeginMode3D(game_state.world_camera)

	player_update(&game_state.player)
	draw_hexagon_floor(20, 20, 10.0)

	raylib.EndMode3D()

    update_view_model_animation(&game_state.view_model, game_state.player, raylib.GetFrameTime())
    raylib.BeginMode3D(game_state.view_model_camera)

    view_model_draw(game_state.view_model, game_state.assets)

    raylib.EndMode3D()
	raylib.EndDrawing()
}