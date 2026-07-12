package game

import "core:math/linalg"
import "vendor:raylib"

Button_Style :: struct {
	font:             raylib.Font,
	font_size:        f32,
	text_color:       raylib.Color,
	normal_color:     raylib.Color,
	hover_color:      raylib.Color,
	pressed_color:    raylib.Color,
	border_color:     raylib.Color,
	border_thickness: f32,
	roundness:        f32,
	segments:         i32,
}

button :: proc(rect: raylib.Rectangle, text: cstring, style: Button_Style) -> bool {

	mouse := raylib.GetMousePosition()

	hovered := raylib.CheckCollisionPointRec(mouse, rect)
	pressed := hovered && raylib.IsMouseButtonDown(.LEFT)
	clicked := hovered && raylib.IsMouseButtonReleased(.LEFT)

	color := style.normal_color

	if hovered {
		color = style.hover_color
	}

	if pressed {
		color = style.pressed_color
	}

	raylib.DrawRectangleRounded(rect, style.roundness, style.segments, color)

	if style.border_thickness > 0 {
		raylib.DrawRectangleRoundedLinesEx(
			rect,
			style.roundness,
			style.segments,
			style.border_thickness,
			style.border_color,
		)
	}

	draw_text(
		text,
		{rect.x + rect.width / 2, rect.y + rect.height / 2},
		style.font,
		style.font_size,
		.Center,
		tint = style.text_color,
	)

	return clicked
}
