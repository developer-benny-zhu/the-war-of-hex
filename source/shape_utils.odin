package game

import "core:math/linalg"
import "vendor:raylib"

draw_hexagon :: proc(center: linalg.Vector2f32, radius: f32 = 50, rotation: f32 = 0, color := raylib.WHITE) {
	raylib.DrawPoly(center, 6, radius, rotation, color)	
}

draw_hexagon_lines :: proc(center: linalg.Vector2f32, radius: f32 = 50, rotation: f32 = 0, color := raylib.WHITE) {
	raylib.DrawPolyLinesEx(center, 6, radius, rotation, 5, color)
}