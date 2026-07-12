package game

import "core:math/linalg"
import "vendor:raylib"
import "core:math"

PLAYER_RADIUS :: 100
PLAYER_COLOR :: raylib.GREEN
PLAYER_SPEED :: 120
PLAYER_TILE_COORDINATE_X :: 6
PLAYER_TILE_COORDINATE_Y :: 8
EQUIPPED_RADIUS :: 100
Player :: struct {
	position: linalg.Vector2f32,
	velocity: linalg.Vector2f32,
	rotation: f32,
	equipped: ^Item
}


player_init :: proc(player: ^Player) {
	player.position = {200, 200}
}

player_update :: proc(player: ^Player, game_state: ^Game_State) {
	player.velocity = {0, 0}
	draw_texture_from_tile_sheet(game_state.assets.kenney_scribble_dungeons_tile_sheet, {TILE_SIZE_X, TILE_SIZE_Y}, {PLAYER_TILE_COORDINATE_X, PLAYER_TILE_COORDINATE_Y}, player.position, .Center, rotation = player.rotation)
	if game_state.game_input.move_up {
		player.velocity.y = -PLAYER_SPEED * raylib.GetFrameTime()
	}
	else if game_state.game_input.move_down {
		player.velocity.y = PLAYER_SPEED * raylib.GetFrameTime()
	}
	if game_state.game_input.move_left {
		player.velocity.x = -PLAYER_SPEED * raylib.GetFrameTime()
	}
	else if game_state.game_input.move_right {
		player.velocity.x = PLAYER_SPEED * raylib.GetFrameTime()
	}

	player.position += player.velocity


	mouse_position := raylib.GetMousePosition()
	player.rotation = get_angle_degrees(player.position, mouse_position)
	if player.equipped != nil {
		player.equipped.position = {
			player.position.x + EQUIPPED_RADIUS * math.cos(get_angle_radians(player.position, mouse_position)),
			player.position.y + EQUIPPED_RADIUS * math.sin(get_angle_radians(player.position, mouse_position))
		}
		player.equipped.rotation = player.rotation + 90
		#partial switch player.equipped.type {
		case .Pole:
		draw_texture_from_tile_sheet(game_state.assets.kenney_scribble_dungeons_tile_sheet, TILE_SIZE, GREEN_HAND_TILE_COORDINATE, {player.equipped.position.x, player.equipped.position.y + 25}, .Center)
		
		}
	}
}
