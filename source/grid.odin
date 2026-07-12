package game

import "core:math"
import "core:math/linalg"
import "core:math/rand"
import "vendor:raylib"

GRID_SIZE_X :: 50
GRID_SIZE_Y :: 50
TILE_RADIUS :: 70

Grid :: struct {
    tiles: [GRID_SIZE_Y][GRID_SIZE_X]Tile,
}

grid_init :: proc(grid: ^Grid) {
    seed_x := rand.float32_range(-10000, 10000)
    seed_y := rand.float32_range(-10000, 10000)

    for row_idx in 0..<GRID_SIZE_Y {
        for col_idx in 0..<GRID_SIZE_X {
            nx := (f32(col_idx) * 0.08) + seed_x
            ny := (f32(row_idx) * 0.08) + seed_y

            noise_val := 0.55 * basic_noise_2d(nx, ny) +
                         0.35 * basic_noise_2d(nx * 2.5, ny * 2.5) +
                         0.10 * basic_noise_2d(nx * 5.0, ny * 5.0)

            normalized_elevation := (noise_val + 1.0) * 0.5
            normalized_elevation = math.clamp(normalized_elevation, 0.0, 1.0)

            tile_init_procedural(&grid.tiles[row_idx][col_idx], normalized_elevation)
        }
    }
}

basic_noise_2d :: proc(x, y: f32) -> f32 {
    ix := math.floor(x)
    iy := math.floor(y)
    fx := x - ix
    fy := y - iy

    ux := fx * fx * (3.0 - 2.0 * fx)
    uy := fy * fy * (3.0 - 2.0 * fy)

    hash :: proc(x, y: f32) -> f32 {
        h := math.sin(x * 12.9898 + y * 78.233) * 43758.5453123
        return h - math.floor(h)
    }

    a := hash(ix, iy)
    b := hash(ix + 1.0, iy)
    c := hash(ix, iy + 1.0)
    d := hash(ix + 1.0, iy + 1.0)

    return math.lerp(math.lerp(a, b, ux), math.lerp(c, d, ux), uy) * 2.0 - 1.0
}

grid_draw :: proc(grid: Grid, game_state: ^Game_State) {
    hexagon_height := get_hexagon_height(TILE_RADIUS * 2)
    for row, row_index in grid.tiles {
        y_position := f32(row_index) * (TILE_RADIUS * 1.5)
        for tile, column_index in row {
            x_position := f32(column_index) * hexagon_height
            if !is_even(i32(row_index)) {
                x_position += hexagon_height / 2
            }
            tile_position := linalg.Vector2f32{x_position, y_position}
            tile_draw(tile, tile_position, TILE_RADIUS, game_state)
        }
    }
}