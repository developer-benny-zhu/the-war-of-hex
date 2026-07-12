package game

import "vendor:raylib"
import "core:math/linalg"

Camera_2D :: struct {
    using _: raylib.Camera2D,
    velocity: linalg.Vector2f32
}

camera_2d_init :: proc(camera_2d: ^Camera_2D) {
    camera_2d.zoom = 1
}

camera_2d_update :: proc(camera_2d: ^Camera_2D) {
    camera_2d.target += camera_2d.velocity
}