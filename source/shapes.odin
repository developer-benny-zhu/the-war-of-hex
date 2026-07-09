package game

import "core:math/linalg"
import "vendor:raylib"
import "vendor:raylib/rlgl"

draw_hexagon_3d :: proc(
	position: linalg.Vector3f32,
	rotation: linalg.Vector3f32,
	radius: f32,
	height: f32,
	$origin: Origin,
    color := raylib.BLUE,
	border_color := raylib.BLACK,
	draw_borders: bool = true,
) {
	sides_count: i32 = 6
	sqrt_three: f32 = 1.7320508

	extent_x := 2.0 * radius
	extent_z := sqrt_three * radius

	local_origin := raylib.Vector3{0.0, 0.0, 0.0}

	when origin == .Center {
		local_origin = raylib.Vector3{0.0, 0.0, 0.0}
	}
	when origin == .Top_Left {
		local_origin = raylib.Vector3{extent_x / 2.0, 0.0, extent_z / 2.0}
	}
	when origin == .Top_Right {
		local_origin = raylib.Vector3{-extent_x / 2.0, 0.0, extent_z / 2.0}
	}
	when origin == .Bottom_Left {
		local_origin = raylib.Vector3{extent_x / 2.0, 0.0, -extent_z / 2.0}
	}
	when origin == .Bottom_Right {
		local_origin = raylib.Vector3{-extent_x / 2.0, 0.0, -extent_z / 2.0}
	}

	rlgl.PushMatrix()
	rlgl.Translatef(position.x, position.y, position.z)

	rlgl.Rotatef(rotation.z, 0.0, 0.0, 1.0)
	rlgl.Rotatef(rotation.y, 0.0, 1.0, 0.0)
	rlgl.Rotatef(rotation.x, 1.0, 0.0, 0.0)

	raylib.DrawCylinder(local_origin, radius, radius, height, sides_count, color)

	if draw_borders {
		raylib.DrawCylinderWires(local_origin, radius, radius, height, sides_count, border_color)
	}

	rlgl.PopMatrix()
}
