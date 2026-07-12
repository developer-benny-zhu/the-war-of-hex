package game


import "vendor:raylib"
import "core:math/linalg"


TILE_SIZE_X :: 128
TILE_SIZE_Y :: 128
TILE_SIZE :: linalg.Vector2f32 {TILE_SIZE_X, TILE_SIZE_Y}



POLE_TILE_COORDINATE_X :: 4
POLE_TILE_COORDINATE_Y :: 9
POLE_TILE_COORDINATE :: linalg.Vector2f32 {POLE_TILE_COORDINATE_X, POLE_TILE_COORDINATE_Y}



CURVED_SHIELD_TILE_COORDINATE_X :: 6
CURVED_SHIELD_TILE_COORDINATE_Y :: 10
CURVED_SHIELD_TILE_COORDINATE :: linalg.Vector2f32 {CURVED_SHIELD_TILE_COORDINATE_X, CURVED_SHIELD_TILE_COORDINATE_Y}

GREEN_HAND_TILE_COORDINATE_X :: 7
GREEN_HAND_TILE_COORDINATE_Y :: 8
GREEN_HAND_TILE_COORDINATE :: linalg.Vector2f32 {GREEN_HAND_TILE_COORDINATE_X, GREEN_HAND_TILE_COORDINATE_Y}

Assets :: struct {
	kenney_scribble_dungeons_tile_sheet: raylib.Texture2D,
}

assets_init :: proc(assets: ^Assets) {
	assets.kenney_scribble_dungeons_tile_sheet = raylib.LoadTexture(
		"assets/kenney_scribble_dungeons_tile_sheet.png",
	)
}

assets_destroy :: proc(assets: ^Assets) {
	raylib.UnloadTexture(assets.kenney_scribble_dungeons_tile_sheet)
}

