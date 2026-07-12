package game

import "vendor/pool"

Scene :: enum {
	Main_Game
}



Game_State :: struct {
	game_input: Game_Input,
	player: Player,
	scene: Scene,
	assets: Assets,
	item_pool: pool.Dense_Pool(Item, 10),
}

game_state_init :: proc(game_state: ^Game_State) {
	assets_init(&game_state.assets)
	player_init(&game_state.player)
	game_state.player.equipped = pool.dense_pool_allocate(&game_state.item_pool)
}
game_state_update :: proc(game_state: ^Game_State) {
	switch game_state.scene {
		case .Main_Game:
		main_game_update(game_state)
		game_input_update(&game_state.game_input)
		for item in pool.dense_pool_slice(&game_state.item_pool) {
			item_update(item)
		}
	}	
}

game_state_destroy :: proc(game_state: ^Game_State) {
	assets_destroy(&game_state.assets)
}
