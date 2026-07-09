package game

import "core:c"
import "core:math/linalg"
import "vendor:raylib"

draw_text :: proc(
	text: cstring,
	position: linalg.Vector2f32,
	font: raylib.Font,
	font_size: f32,
	$origin: Origin,
	rotation: f32 = 0,
	tint := raylib.WHITE,
	spacing: f32 = 2,
) {
	text_size := raylib.MeasureTextEx(font, text, font_size, spacing)
	when origin == .Center {
		raylib.DrawTextPro(font, text, position, text_size / 2, rotation, font_size, spacing, tint)
	}
	when origin == .Top_Left {
		raylib.DrawTextPro(font, text, position, {0, 0}, rotation, font_size, spacing, tint)
	}
	when origin == .Top_Right {
		raylib.DrawTextPro(
			font,
			text,
			position,
			{text_size.x, 0},
			rotation,
			font_size,
			spacing,
			tint,
		)
	}
	when origin == .Bottom_Left {
		raylib.DrawTextPro(font, text, position, {0, size.y}, rotation, font_size, spacing, tint)
	}
	when origin == .Bottom_Right {
		raylib.DrawTextPro(font, text, position, text_size, rotation, font_size, spacing, tint)
	}
}

draw_texture :: proc(
	texture: raylib.Texture2D,
	source: raylib.Rectangle,
	position: linalg.Vector2f32,
	$origin: Origin,
	scale := linalg.Vector2f32{1, 1},
	rotation: f32 = 0,
	tint := raylib.WHITE,
) {
	destination := raylib.Rectangle {
		position.x,
		position.y,
		source.width * scale.x,
		source.height * scale.y,
	}
	when origin == .Top_Left {
		raylib.DrawTexturePro(texture, source, destination, {0, 0}, rotation, tint)
	}
	when origin == .Center {
		raylib.DrawTexturePro(
			texture,
			source,
			destination,
			{destination.width / 2, destination.height / 2},
			rotation,
			tint,
		)
	}
	when origin == .Top_Right {
		raylib.DrawTexturePro(texture, source, destination, {destination.width, 0}, rotation, tint)
	}
	when origin == .Bottom_Left {
		raylib.DrawTexturePro(
			texture,
			source,
			destination,
			{0, destination.height},
			rotation,
			tint,
		)
	}
	when origin == .Bottom_Right {
		destination := linalg.Vector2f32 {
			position.x,
			position.y,
			source.width * scale.x,
			source.height * scale.y,
		}
		raylib.DrawTexturePro(texture, source, destination, destination, rotation, tint)
	}
}
