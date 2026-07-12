package game


Scene :: enum {
    World
}
Game_State :: struct {
    world: World,
    scene: Scene,
    assets: Assets
}

game_state_init :: proc(game_state: ^Game_State) {
    assets_init(&game_state.assets)
    world_init(&game_state.world)
}

game_state_update :: proc(game_state: ^Game_State) {
    switch game_state.scene {
        case .World:
            world_update(&game_state.world, game_state)
    }
}

game_state_destroy :: proc(game_state: ^Game_State) {
    assets_destroy(&game_state.assets)
}
