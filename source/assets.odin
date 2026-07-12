package game


import "vendor:raylib"

Assets :: struct {
	kenney_hexagon_sheet: raylib.Texture2D,
	ginger_bill:          raylib.Texture2D,

	blue_footman: raylib.Texture2D,
	blue_peasant: raylib.Texture2D,
	blue_wizard: raylib.Texture2D,

	red_footman: raylib.Texture2D,
	red_peasant: raylib.Texture2D,
	red_wizard: raylib.Texture2D,

	menu_music: raylib.Music,
	game_music: raylib.Music,
}

assets_init :: proc(assets: ^Assets) {
	assets.kenney_hexagon_sheet = raylib.LoadTexture("assets/kenney_hexagon_sheet.png")
	assets.ginger_bill = raylib.LoadTexture("assets/ginger_bill.png")

	assets.blue_footman = raylib.LoadTexture("assets/kenney_medieval_rts/blue_footman.png")
	assets.blue_peasant = raylib.LoadTexture("assets/kenney_medieval_rts/blue_peasant.png")
	assets.blue_wizard = raylib.LoadTexture("assets/kenney_medieval_rts/blue_wizard.png")
	assets.red_footman = raylib.LoadTexture("assets/kenney_medieval_rts/red_footman.png")
	assets.red_peasant = raylib.LoadTexture("assets/kenney_medieval_rts/red_peasant.png")
	assets.red_wizard = raylib.LoadTexture("assets/kenney_medieval_rts/red_wizard.png")

	assets.game_music = raylib.LoadMusicStream("assets/menu_music.ogg")
	assets.game_music.looping = true
	assets.menu_music = raylib.LoadMusicStream("assets/game_music.ogg")
	assets.game_music.looping = true
}

assets_destroy :: proc(assets: ^Assets) {
	raylib.UnloadTexture(assets.kenney_hexagon_sheet)
	raylib.UnloadTexture(assets.ginger_bill)

	raylib.UnloadTexture(assets.blue_footman)
	raylib.UnloadTexture(assets.blue_peasant)
	raylib.UnloadTexture(assets.blue_wizard)
	raylib.UnloadTexture(assets.red_footman)
	raylib.UnloadTexture(assets.red_peasant)
	raylib.UnloadTexture(assets.red_wizard)

	raylib.UnloadMusicStream(assets.game_music)
	raylib.UnloadMusicStream(assets.menu_music)
}
