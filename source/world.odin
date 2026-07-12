package game


import "vendor:raylib"
import "core:math/linalg"

CAMERA_SPEED :: 100

World :: struct {
    grid: Grid,
    camera: Camera_2D,
    selected_row: int,
    selected_column: int,
}

world_init :: proc(world: ^World) {
    world.grid = Grid {}
    grid_init(&world.grid)
    world.camera = Camera_2D {}
    camera_2d_init(&world.camera)
    world.selected_row = -1
    world.selected_column = -1
}

world_update :: proc(world: ^World, game_state: ^Game_State) {
    world.camera.velocity = {}
    if raylib.IsKeyDown(MOVE_UP) {
        world.camera.velocity.y = -CAMERA_SPEED * raylib.GetFrameTime()
    }
    if raylib.IsKeyDown(MOVE_DOWN) {
        world.camera.velocity.y = CAMERA_SPEED * raylib.GetFrameTime()
    }
    if raylib.IsKeyDown(MOVE_LEFT) {
        world.camera.velocity.x = -CAMERA_SPEED * raylib.GetFrameTime()
    }
    if raylib.IsKeyDown(MOVE_RIGHT) {
        world.camera.velocity.x = CAMERA_SPEED * raylib.GetFrameTime()
    }
    camera_2d_update(&world.camera)
    if raylib.IsMouseButtonPressed(.LEFT) {
        mouse_position := raylib.GetScreenToWorld2D(raylib.GetMousePosition(), world.camera)
        found := false
        for row, row_index in world.grid.tiles {
            for _, column_index in row {
                tile_position := grid_tile_position(row_index, column_index)
                if get_distance(mouse_position, tile_position) <= TILE_RADIUS {
                    world.selected_row = row_index
                    world.selected_column = column_index
                    found = true
                    break
                }
            }
            if found {
                break
            }
        }
    }
    raylib.BeginDrawing()
    raylib.ClearBackground(raylib.BLACK)
    raylib.BeginMode2D(world.camera)
    for row, row_index in world.grid.tiles {
        for tile, column_index in row {
            tile_position := grid_tile_position(row_index, column_index)
            selected := row_index == world.selected_row && column_index == world.selected_column
            tile_draw(tile, tile_position, TILE_RADIUS, game_state, selected)
        }
    }
    raylib.EndMode2D()
    raylib.EndDrawing()
}