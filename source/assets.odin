package game


import "vendor:raylib"

Assets :: struct {
	kenney_hexagon_sheet: raylib.Texture2D,
	ginger_bill:          raylib.Texture2D,
	button_tile:          raylib.Texture2D,
	banner_tile_1:        raylib.Texture2D,
	banner_tile_2:        raylib.Texture2D,
	banner_tile_3:        raylib.Texture2D,
	pop_up_tile:          raylib.Texture2D,

	blue_footman: raylib.Texture2D,
	blue_peasant: raylib.Texture2D,
	blue_wizard: raylib.Texture2D,

	red_footman: raylib.Texture2D,
	red_peasant: raylib.Texture2D,
	red_wizard: raylib.Texture2D
}

assets_init :: proc(assets: ^Assets) {
	assets.kenney_hexagon_sheet = raylib.LoadTexture("assets/kenney_hexagon_sheet.png")
	assets.ginger_bill = raylib.LoadTexture("assets/ginger_bill.png")

	assets.button_tile = raylib.LoadTexture("assets/kenney_pixel_adventure_ui/button_tile.png")
	assets.banner_tile_1 = raylib.LoadTexture("assets/kenney_pixel_adventure_ui/banner_tile_1.png")
	assets.banner_tile_2 = raylib.LoadTexture("assets/kenney_pixel_adventure_ui/banner_tile_2.png")
	assets.banner_tile_3 = raylib.LoadTexture("assets/kenney_pixel_adventure_ui/banner_tile_3.png")
	assets.pop_up_tile = raylib.LoadTexture("assets/kenney_pixel_adventure_ui/pop_up_tile.png")

	assets.blue_footman = raylib.LoadTexture("assets/kenney_medieval_rts/blue_footman.png")
	assets.blue_peasant = raylib.LoadTexture("assets/kenney_medieval_rts/blue_peasant.png")
	assets.blue_wizard = raylib.LoadTexture("assets/kenney_medieval_rts/blue_wizard.png")
	assets.red_footman = raylib.LoadTexture("assets/kenney_medieval_rts/red_footman.png")
	assets.red_peasant = raylib.LoadTexture("assets/kenney_medieval_rts/red_peasant.png")
	assets.red_wizard = raylib.LoadTexture("assets/kenney_medieval_rts/red_wizard.png")
}

assets_destroy :: proc(assets: ^Assets) {
	raylib.UnloadTexture(assets.kenney_hexagon_sheet)
	raylib.UnloadTexture(assets.ginger_bill)

	raylib.UnloadTexture(assets.button_tile)
	raylib.UnloadTexture(assets.banner_tile_1)
	raylib.UnloadTexture(assets.banner_tile_2)
	raylib.UnloadTexture(assets.banner_tile_3)
	raylib.UnloadTexture(assets.pop_up_tile)
	raylib.UnloadTexture(assets.blue_footman)
	raylib.UnloadTexture(assets.blue_peasant)
	raylib.UnloadTexture(assets.blue_wizard)
	raylib.UnloadTexture(assets.red_footman)
	raylib.UnloadTexture(assets.red_peasant)
	raylib.UnloadTexture(assets.red_wizard)
}
