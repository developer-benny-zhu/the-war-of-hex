package game

import "vendor:raylib"
import "core:math/linalg"


button :: proc(
	text: cstring,
	position: linalg.Vector2f32,
	size: linalg.Vector2f32,
	camera: raylib.Camera2D,
	$origin: Origin,
	normal_background_color: raylib.Color = raylib.DARKGRAY,
	normal_border_color: raylib.Color = raylib.MAROON,
	hover_background_color: raylib.Color = raylib.GRAY,
	hover_border_color: raylib.Color = raylib.RED,
	pressed_background_color: raylib.Color = raylib.LIGHTGRAY,
	pressed_border_color: raylib.Color = raylib.ORANGE,
	text_color: raylib.Color = raylib.WHITE,
) -> bool {
	button_bounds: raylib.Rectangle
	when origin == .Center {
		button_bounds = raylib.Rectangle {
			position.x - size.x / 2,
			position.y - size.y / 2,
			size.x,
			size.y,
		}
	}
	when origin == .Top_Left {
		button_bounds = raylib.Rectangle{position.x, position.y, size.x, size.y}
	}
	when origin == .Top_Right {
		button_bounds = raylib.Rectangle{position.x + size.x, position.y, size.x, size.y}
	}
	when origin == .Bottom_Left {
		button_bounds = raylib.Rectangle{position.x, position.y + size.y, size.x, size.y}
	}
	when origin == .Bottom_Right {
		button_bounds = raylib.Rectangle{position.x + size.x, position.y + size.y, size.x, size.y}
	}

	mouse_screen_position := raylib.GetMousePosition()
	mouse_virtual_position := raylib.GetScreenToWorld2D(mouse_screen_position, camera)
	is_hovered := raylib.CheckCollisionPointRec(mouse_virtual_position, button_bounds)
	is_clicked := false

	current_background_color := normal_background_color
	current_border_color := normal_border_color

	if is_hovered {
		if raylib.IsMouseButtonDown(.LEFT) {
			current_background_color = pressed_background_color
			current_border_color = pressed_border_color
		} else {
			current_background_color = hover_background_color
			current_border_color = hover_border_color
		}

		if raylib.IsMouseButtonReleased(.LEFT) {
			is_clicked = true
		}
	}

	raylib.DrawRectangleRec(button_bounds, current_background_color)
	raylib.DrawRectangleLinesEx(button_bounds, 2, current_border_color)

	text_position := linalg.Vector2f32 {
		button_bounds.x + button_bounds.width / 2,
		button_bounds.y + button_bounds.height / 2,
	}

	draw_text(text, text_position, raylib.GetFontDefault(), 20.0, .Center, tint = text_color)

	return is_clicked
}