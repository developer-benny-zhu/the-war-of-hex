package game

import "core:math/linalg"

Item :: struct {
	position: linalg.Vector2f32,
	rotation: f32,
	type: Item_Type		
}

Item_Type :: enum {
	Pole,
	Curved_Shield
}

item_update :: proc(item: Item) {
	switch item.type {
		case .Pole:
			draw_texture_from_tile_sheet(game_state.assets.kenney_scribble_dungeons_tile_sheet, TILE_SIZE, POLE_TILE_COORDINATE, item.position, .Center, item.rotation)
		case .Curved_Shield:
			draw_texture_from_tile_sheet(game_state.assets.kenney_scribble_dungeons_tile_sheet, TILE_SIZE, CURVED_SHIELD_TILE_COORDINATE, item.position, .Center, item.rotation)
		
	}
}
