package game

import "vendor:raylib"
import "core:math/linalg"

Crosshair :: struct {
    top_arm: Line,
    right_arm: Line,
    left_arm: Line,
    bottom_arm: Line,
}

crosshair_init :: proc(crosshair: ^Crosshair) {
    line_init(&crosshair.top_arm)
    line_init(&crosshair.left_arm)
    line_init(&crosshair.right_arm)
    line_init(&crosshair.bottom_arm)
    spacing := 5
    length := 20
    center := linalg.Vector2f32 {
        f32(raylib.GetScreenWidth()) / 2,
        f32(raylib.GetScreenHeight()) / 2
    }
    crosshair.top_arm.start_position = center - {0, f32(spacing)} - {0, f32(length)}
    crosshair.top_arm.end_position = center - {0, f32(spacing)}

    crosshair.right_arm.start_position = center + {f32(spacing), 0} + {f32(length), 0}
    crosshair.right_arm.end_position = center + {f32(spacing), 0}

    crosshair.left_arm.start_position = center - {f32(spacing), 0} - {f32(length), 0}
    crosshair.left_arm.end_position = center - {f32(spacing), 0}

    crosshair.bottom_arm.start_position = center + {0, f32(spacing)} + {0, f32(length)}
    crosshair.bottom_arm.end_position = center + {0, f32(spacing)}
}

crosshair_draw :: proc(crosshair: Crosshair) {
    line_draw(crosshair.top_arm)
    line_draw(crosshair.right_arm)
    line_draw(crosshair.left_arm)
    line_draw(crosshair.bottom_arm)
}

