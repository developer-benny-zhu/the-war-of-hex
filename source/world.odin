package game


import "vendor:raylib"
import "core:math/linalg"

CAMERA_SPEED :: 100

World :: struct {
    grid: Grid,
    camera: Camera_2D,
}

world_init :: proc(world: ^World) {
    world.grid = Grid {}
    grid_init(&world.grid)
    world.camera = Camera_2D {}
    camera_2d_init(&world.camera)
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
    raylib.BeginDrawing()
    raylib.ClearBackground(raylib.BLACK)
    raylib.BeginMode2D(world.camera)
    grid_draw(world.grid, game_state)
    raylib.EndMode2D()
    raylib.EndDrawing()
}