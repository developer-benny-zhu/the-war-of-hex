package game


import "core:math/linalg"
import "vendor:raylib"


Line :: struct {
	color:          raylib.Color,
	start_position: linalg.Vector2f32,
	end_position:   linalg.Vector2f32,
	thickness:      f32,
}

line_init :: proc(line: ^Line) {
    line.thickness = 2
    line.color = raylib.GREEN
}
line_draw :: proc(line: Line) {
	raylib.DrawLineEx(line.start_position, line.end_position, line.thickness, line.color)
}
