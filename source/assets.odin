package game


import "vendor:raylib"

Assets :: struct {
    kenney_hexagon_sheet: raylib.Texture2D
}

assets_init :: proc(assets: ^Assets) {
    assets.kenney_hexagon_sheet = raylib.LoadTexture("assets/kenney_hexagon_sheet.png")
}

assets_destroy :: proc(assets: ^Assets) {
    raylib.UnloadTexture(assets.kenney_hexagon_sheet)
}