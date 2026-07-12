package game

import "core:fmt"
import "core:math"
import "core:math/linalg"
import "core:strings"
import "vendor:raylib"

CAMERA_SPEED :: 100
AI_ACTION_DELAY :: 0.7

World_State :: enum {
	Playing,
	Paused,
	Player_Won,
	Enemy_Won,
	Quit_To_Menu,
}

World :: struct {
	grid:                Grid,
	camera:              Camera_2D,
	state:               World_State,
	zoom:                f32,
	world_fade:          f32,
	current_turn:        Team,
	ai_timer:            f32,
	player_money:        i32,
	enemy_money:         i32,
	dialog:              Dialog,
	units:               [64]Unit,
	unit_count:          int,
	selected_row:        int,
	selected_column:     int,
	selected_unit_index: int,
	player_base_row:     int,
	player_base_column:  int,
	enemy_base_row:      int,
	enemy_base_column:   int,
	ai_spawn_done:       bool,
}

world_init :: proc(world: ^World, game_state: ^Game_State) {
	raylib.PlayMusicStream(game_state.assets.game_music)
	world.grid = Grid{}
	grid_init(&world.grid)
	world.camera = Camera_2D{}
	camera_2d_init(&world.camera)

	world.state = .Playing
	world.zoom = 1
	world.world_fade = 1
	world.current_turn = .Player
	world.ai_timer = 0

	world.player_money = 10
	world.enemy_money = 10

	dialog_init(&world.dialog)
	world.unit_count = 0
	world.selected_row = -1
	world.selected_column = -1
	world.selected_unit_index = -1
	world.ai_spawn_done = false

	world.player_base_row = GRID_SIZE_Y - 1
	world.player_base_column = 0
	world.enemy_base_row = 0
	world.enemy_base_column = GRID_SIZE_X - 1

	for row_index in 0 ..< GRID_SIZE_Y {
		for column_index in 0 ..< GRID_SIZE_X {
			if world.grid.tiles[row_index][column_index].team == .Player {
				world.camera.target = grid_tile_position(row_index, column_index)
				return
			}
		}
	}
}

world_end_turn :: proc(world: ^World) {
	if world.current_turn == .Player {
		world.current_turn = .Enemy
		world.ai_timer = AI_ACTION_DELAY
		world.enemy_money += world_count_owned_tiles(world, .Enemy)
		world.ai_spawn_done = false
	} else {
		world.current_turn = .Player
		world.player_money += world_count_owned_tiles(world, .Player)
	}

	for index in 0 ..< world.unit_count {
		world.units[index].has_moved = false
	}
	world_clear_selection(world)
}

world_selected_tile_is_player_base :: proc(world: ^World) -> bool {
	if world.selected_row < 0 || world.selected_column < 0 do return false
	return(
		world.selected_row == world.player_base_row &&
		world.selected_column == world.player_base_column &&
		world.grid.tiles[world.selected_row][world.selected_column].team == .Player \
	)
}

world_clear_selection :: proc(world: ^World) {
	world.selected_row = -1
	world.selected_column = -1
	world.selected_unit_index = -1
}

world_team_money :: proc(world: ^World, team: Team) -> ^i32 {
	if team == .Player do return &world.player_money
	return &world.enemy_money
}

world_count_owned_tiles :: proc(world: ^World, team: Team) -> i32 {
	owned_count: i32 = 0
	for row_index in 0 ..< GRID_SIZE_Y {
		for column_index in 0 ..< GRID_SIZE_X {
			if world.grid.tiles[row_index][column_index].team == team {
				owned_count += 1
			}
		}
	}
	return owned_count
}

world_is_tile_adjacent_to_position :: proc(
	source_row, source_column, destination_row, destination_column: int,
) -> bool {
	offsets_even_row := [6][2]int{{0, -1}, {0, 1}, {-1, -1}, {-1, 0}, {1, -1}, {1, 0}}
	offsets_odd_row := [6][2]int{{0, -1}, {0, 1}, {-1, 0}, {-1, 1}, {1, 0}, {1, 1}}

	offsets := is_even(i32(source_row)) ? offsets_even_row : offsets_odd_row
	for offset in offsets {
		if source_row + offset[0] == destination_row &&
		   source_column + offset[1] == destination_column {
			return true
		}
	}
	return false
}

world_spawn_panel_rectangle :: proc(scale: f32) -> raylib.Rectangle {
	window_width := f32(raylib.GetScreenWidth())
	window_height := f32(raylib.GetScreenHeight())
	panel_width := f32(440) * scale
	panel_height := f32(96) * scale
	return raylib.Rectangle {
		x = (window_width - panel_width) / 2,
		y = window_height - panel_height - (26 * scale),
		width = panel_width,
		height = panel_height,
	}
}

world_unit_at_tile :: proc(world: ^World, target_row, target_column: int) -> int {
	for index in 0 ..< world.unit_count {
		unit := world.units[index]
		if unit.row == target_row && unit.column == target_column {
			return index
		}
	}
	return -1
}

world_tile_has_unit :: proc(world: ^World, target_row, target_column: int) -> bool {
	return world_unit_at_tile(world, target_row, target_column) != -1
}

world_remove_unit :: proc(world: ^World, removal_index: int) {
	if removal_index < 0 || removal_index >= world.unit_count do return
	for index in removal_index ..< world.unit_count - 1 {
		world.units[index] = world.units[index + 1]
	}
	world.unit_count -= 1
}

world_move_unit_to_tile :: proc(world: ^World, unit_index, target_row, target_column: int) {
	if unit_index < 0 || unit_index >= world.unit_count do return
	if world.units[unit_index].has_moved do return

	attacker := &world.units[unit_index]
	if attacker.team != world.current_turn do return

	is_owned := world.grid.tiles[target_row][target_column].team == attacker.team
	is_adjacent := world_is_tile_adjacent_to_position(
		attacker.row,
		attacker.column,
		target_row,
		target_column,
	)
	if !is_owned && !is_adjacent do return

	defender_index := world_unit_at_tile(world, target_row, target_column)
	if defender_index != -1 {
		defender := &world.units[defender_index]
		if defender.team == attacker.team do return

		attacker_power := unit_combat_power(attacker.kind)
		defender_power := unit_combat_power(defender.kind)

		if attacker_power >= defender_power {
			world_remove_unit(world, defender_index)

			actual_attacker_index := unit_index
			if defender_index < unit_index do actual_attacker_index -= 1

			final_attacker := &world.units[actual_attacker_index]
			target_position := grid_tile_position(target_row, target_column)
			final_attacker.row = target_row
			final_attacker.column = target_column
			final_attacker.target_position = target_position
			final_attacker.has_moved = true
			world.grid.tiles[target_row][target_column].team = final_attacker.team
		} else {
			world_remove_unit(world, unit_index)
		}
		world_check_win_conditions(world)
		return
	}

	target_position := grid_tile_position(target_row, target_column)
	attacker.row = target_row
	attacker.column = target_column
	attacker.target_position = target_position
	attacker.has_moved = true
	world.grid.tiles[target_row][target_column].team = attacker.team
	world_check_win_conditions(world)
}

world_check_win_conditions :: proc(world: ^World) {
	if world.grid.tiles[world.enemy_base_row][world.enemy_base_column].team == .Player {
		world.state = .Player_Won
	} else if world.grid.tiles[world.player_base_row][world.player_base_column].team == .Enemy {
		world.state = .Enemy_Won
	}
}

world_spawn_unit :: proc(world: ^World, kind: Unit_Kind) {
	if world.unit_count >= len(world.units) do return
	if !world_selected_tile_is_player_base(world) do return
	if world.current_turn != .Player do return

	cost := unit_cost(kind)
	if world.player_money < cost do return

	spawn_row := world.selected_row
	spawn_column := world.selected_column

	if world_tile_has_unit(world, spawn_row, spawn_column) do return

	spawn_position := grid_tile_position(spawn_row, spawn_column)

	world.units[world.unit_count] = Unit {
		team            = .Player,
		kind            = kind,
		row             = spawn_row,
		column          = spawn_column,
		position        = spawn_position,
		target_position = spawn_position,
		has_moved       = true,
	}
	world.unit_count += 1
	world.player_money -= cost
}

world_enemy_ai_update :: proc(world: ^World) {
	world.ai_timer -= raylib.GetFrameTime()
	if world.ai_timer > 0 do return

	if !world.ai_spawn_done {
		if world.enemy_money >= 10 {
			chosen_kind: Unit_Kind = .Peasant
			if world.enemy_money >= 50 do chosen_kind = .Tank
			else if world.enemy_money >= 20 do chosen_kind = .Footman

			cost := unit_cost(chosen_kind)
			if !world_tile_has_unit(world, world.enemy_base_row, world.enemy_base_column) {
				if world.unit_count < len(world.units) {
					spawn_position := grid_tile_position(
						world.enemy_base_row,
						world.enemy_base_column,
					)
					world.units[world.unit_count] = Unit {
						team            = .Enemy,
						kind            = chosen_kind,
						row             = world.enemy_base_row,
						column          = world.enemy_base_column,
						position        = spawn_position,
						target_position = spawn_position,
						has_moved       = true,
					}
					world.unit_count += 1
					world.enemy_money -= cost
					world.grid.tiles[world.enemy_base_row][world.enemy_base_column].team = .Enemy

					world.ai_timer = AI_ACTION_DELAY
					return
				}
			}
		}
		world.ai_spawn_done = true
	}

	offsets_even_row := [6][2]int{{0, -1}, {0, 1}, {-1, -1}, {-1, 0}, {1, -1}, {1, 0}}
	offsets_odd_row := [6][2]int{{0, -1}, {0, 1}, {-1, 0}, {-1, 1}, {1, 0}, {1, 1}}

	active_unit_index := -1
	for index in 0 ..< world.unit_count {
		if world.units[index].team == .Enemy && !world.units[index].has_moved {
			active_unit_index = index
			break
		}
	}

	if active_unit_index == -1 {
		world_end_turn(world)
		return
	}

	unit := &world.units[active_unit_index]
	offsets := is_even(i32(unit.row)) ? offsets_even_row : offsets_odd_row
	unit_has_completed_action := false
	attacker_power := unit_combat_power(unit.kind)

	for offset in offsets {
		neighbor_row := unit.row + offset[0]
		neighbor_column := unit.column + offset[1]

		if neighbor_row >= 0 &&
		   neighbor_row < GRID_SIZE_Y &&
		   neighbor_column >= 0 &&
		   neighbor_column < GRID_SIZE_X {
			defender_index := world_unit_at_tile(world, neighbor_row, neighbor_column)
			if defender_index != -1 && world.units[defender_index].team == .Player {
				defender_power := unit_combat_power(world.units[defender_index].kind)
				if attacker_power >= defender_power {
					world_move_unit_to_tile(
						world,
						active_unit_index,
						neighbor_row,
						neighbor_column,
					)
					unit_has_completed_action = true
					break
				}
			}
		}
	}

	if !unit_has_completed_action {
		base_threatened := false
		base_offsets := is_even(i32(world.enemy_base_row)) ? offsets_even_row : offsets_odd_row

		for base_off in base_offsets {
			check_r := world.enemy_base_row + base_off[0]
			check_c := world.enemy_base_column + base_off[1]
			if check_r >= 0 && check_r < GRID_SIZE_Y && check_c >= 0 && check_c < GRID_SIZE_X {
				defender_idx := world_unit_at_tile(world, check_r, check_c)
				if defender_idx != -1 && world.units[defender_idx].team == .Player {
					base_threatened = true
					break
				}
			}
		}

		if base_threatened {
			if unit.row == world.enemy_base_row && unit.column == world.enemy_base_column {
				world.units[active_unit_index].has_moved = true
				unit_has_completed_action = true
			} else if !world_tile_has_unit(world, world.enemy_base_row, world.enemy_base_column) &&
			   world.grid.tiles[world.enemy_base_row][world.enemy_base_column].team == .Enemy {
				world_move_unit_to_tile(
					world,
					active_unit_index,
					world.enemy_base_row,
					world.enemy_base_column,
				)
				unit_has_completed_action = true
			}
		}
	}

	if !unit_has_completed_action {
		for offset in offsets {
			neighbor_row := unit.row + offset[0]
			neighbor_column := unit.column + offset[1]

			if neighbor_row >= 0 &&
			   neighbor_row < GRID_SIZE_Y &&
			   neighbor_column >= 0 &&
			   neighbor_column < GRID_SIZE_X {
				if !world_tile_has_unit(world, neighbor_row, neighbor_column) &&
				   world.grid.tiles[neighbor_row][neighbor_column].team != .Enemy {
					world_move_unit_to_tile(
						world,
						active_unit_index,
						neighbor_row,
						neighbor_column,
					)
					unit_has_completed_action = true
					break
				}
			}
		}
	}

	if !unit_has_completed_action {
		best_row := -1
		best_col := -1
		best_dist := 9999

		for row_index in 0 ..< GRID_SIZE_Y {
			for column_index in 0 ..< GRID_SIZE_X {
				if world.grid.tiles[row_index][column_index].team == .Enemy &&
				   !world_tile_has_unit(world, row_index, column_index) {
					check_offsets := is_even(i32(row_index)) ? offsets_even_row : offsets_odd_row
					is_frontline := false

					for check_offset in check_offsets {
						check_row := row_index + check_offset[0]
						check_column := column_index + check_offset[1]

						if check_row >= 0 &&
						   check_row < GRID_SIZE_Y &&
						   check_column >= 0 &&
						   check_column < GRID_SIZE_X {
							if world.grid.tiles[check_row][check_column].team == .Player ||
							   world_unit_at_tile(world, check_row, check_column) != -1 {
								is_frontline = true
								break
							}
						}
					}

					if is_frontline {
						dist :=
							math.abs(row_index - world.player_base_row) +
							math.abs(column_index - world.player_base_column)
						if dist < best_dist {
							best_dist = dist
							best_row = row_index
							best_col = column_index
						}
					}
				}
			}
		}
		if best_row != -1 {
			world_move_unit_to_tile(world, active_unit_index, best_row, best_col)
			unit_has_completed_action = true
		}
	}

	if !unit_has_completed_action {
		world.units[active_unit_index].has_moved = true
	}

	world.ai_timer = AI_ACTION_DELAY
}

world_draw_spawn_buttons :: proc(
	world: ^World,
	game_state: ^Game_State,
	font: raylib.Font,
	scale: f32,
) {
	if !world_selected_tile_is_player_base(world) do return

	panel := world_spawn_panel_rectangle(scale)

	raylib.DrawRectangleRounded(
		{panel.x + (4 * scale), panel.y + (4 * scale), panel.width, panel.height},
		0.15,
		8,
		{10, 10, 15, 180},
	)
	raylib.DrawRectangleRounded(panel, 0.15, 8, {25, 25, 35, 240})
	raylib.DrawRectangleRoundedLinesEx(panel, 0.15, 8, 2 * scale, raylib.GOLD)

	button_width := f32(124) * scale
	button_height := f32(44) * scale
	button_y_position := panel.y + (panel.height - button_height) / 2
	button_gap := f32(12) * scale
	button_start_x := panel.x + (panel.width - (button_width * 3 + button_gap * 2)) / 2

	button_rectangles := [3]raylib.Rectangle {
		{x = button_start_x, y = button_y_position, width = button_width, height = button_height},
		{
			x = button_start_x + button_width + button_gap,
			y = button_y_position,
			width = button_width,
			height = button_height,
		},
		{
			x = button_start_x + (button_width + button_gap) * 2,
			y = button_y_position,
			width = button_width,
			height = button_height,
		},
	}

	button_labels := [3]cstring{"Tank (50)", "Footman (20)", "Peasant (10)"}
	unit_costs := [3]i32{50, 20, 10}

	base_button_style := Button_Style {
		font             = font,
		font_size        = 15 * scale,
		text_color       = raylib.WHITE,
		normal_color     = raylib.Color{45, 45, 60, 255},
		hover_color      = raylib.Color{65, 65, 85, 255},
		pressed_color    = raylib.Color{30, 30, 45, 255},
		border_color     = raylib.GOLD,
		border_thickness = 1 * scale,
		roundness        = 0.2,
		segments         = 6,
	}

	for index in 0 ..< 3 {
		current_style := base_button_style
		if world.player_money < unit_costs[index] {
			current_style.text_color = raylib.Color{130, 130, 130, 255}
			current_style.normal_color = raylib.Color{25, 25, 30, 255}
			current_style.border_color = raylib.Color{80, 80, 80, 255}
		}

		if button(button_rectangles[index], button_labels[index], current_style) &&
		   world.player_money >= unit_costs[index] {
			if index == 0 do world_spawn_unit(world, .Tank)
			if index == 1 do world_spawn_unit(world, .Footman)
			if index == 2 do world_spawn_unit(world, .Peasant)
		}
	}
}

world_update :: proc(world: ^World, game_state: ^Game_State) {
	raylib.UpdateMusicStream(game_state.assets.game_music)

	if raylib.IsKeyPressed(.ESCAPE) {
		if world.state == .Playing {
			world.state = .Paused
		} else if world.state == .Paused {
			world.state = .Playing
		}
	}

	if world.state == .Player_Won || world.state == .Enemy_Won {
		if raylib.IsKeyPressed(.ENTER) {
			world_init(world, game_state)
		}
	}

	if world.state == .Playing {
		world.camera.velocity = {}
		for index in 0 ..< world.unit_count {
			unit_update(&world.units[index])
		}

		if world.current_turn == .Enemy {
			world_enemy_ai_update(world)
		}

		if world.current_turn == .Player {
			if raylib.IsKeyPressed(raylib.KeyboardKey.ENTER) {
				world_end_turn(world)
			}
		}

		zoom_change := f32(0)
		mouse_wheel_movement := raylib.GetMouseWheelMoveV()
		if mouse_wheel_movement.x != 0 || mouse_wheel_movement.y != 0 {
			zoom_change += (mouse_wheel_movement.x + mouse_wheel_movement.y) * 0.1
		}

		world.camera.zoom =
			(f32(raylib.GetScreenHeight()) / f32(VIRTUAL_SCREEN_HEIGHT)) * world.zoom
		if zoom_change != 0 {
			mouse_screen_position := raylib.GetMousePosition()
			mouse_world_position_before := raylib.GetScreenToWorld2D(
				mouse_screen_position,
				world.camera,
			)
			world.zoom += zoom_change
			world.zoom = math.clamp(world.zoom, 0.5, 3.0)
			world.camera.zoom =
				(f32(raylib.GetScreenHeight()) / f32(VIRTUAL_SCREEN_HEIGHT)) * world.zoom
			mouse_world_position_after := raylib.GetScreenToWorld2D(
				mouse_screen_position,
				world.camera,
			)
			world.camera.target += mouse_world_position_before - mouse_world_position_after
		}

		if raylib.IsKeyDown(MOVE_UP) do world.camera.velocity.y = -CAMERA_SPEED * raylib.GetFrameTime()
		if raylib.IsKeyDown(MOVE_DOWN) do world.camera.velocity.y = CAMERA_SPEED * raylib.GetFrameTime()
		if raylib.IsKeyDown(MOVE_LEFT) do world.camera.velocity.x = -CAMERA_SPEED * raylib.GetFrameTime()
		if raylib.IsKeyDown(MOVE_RIGHT) do world.camera.velocity.x = CAMERA_SPEED * raylib.GetFrameTime()
		camera_2d_update(&world.camera)
	}

	window_height_float := f32(raylib.GetScreenHeight())
	ui_scale := window_height_float / f32(VIRTUAL_SCREEN_HEIGHT)

	if world.state == .Playing &&
	   world.current_turn == .Player &&
	   !world.dialog.active &&
	   raylib.IsMouseButtonPressed(.LEFT) {
		mouse_world_position := raylib.GetScreenToWorld2D(raylib.GetMousePosition(), world.camera)
		click_handled := false

		if world_selected_tile_is_player_base(world) {
			mouse_screen_position := raylib.GetMousePosition()
			if raylib.CheckCollisionPointRec(
				mouse_screen_position,
				world_spawn_panel_rectangle(ui_scale),
			) {
				click_handled = true
			}
		}

		for row, row_index in world.grid.tiles {
			if click_handled do break
			for _, column_index in row {
				tile_position := grid_tile_position(row_index, column_index)
				if get_distance(mouse_world_position, tile_position) <= TILE_RADIUS {
					if world.selected_row == row_index && world.selected_column == column_index {
						world_clear_selection(world)
						click_handled = true
						break
					}

					if world.selected_unit_index != -1 {
						world_move_unit_to_tile(
							world,
							world.selected_unit_index,
							row_index,
							column_index,
						)
						world_clear_selection(world)
						click_handled = true
						break
					}

					unit_index := world_unit_at_tile(world, row_index, column_index)
					if unit_index != -1 && world.units[unit_index].team == .Player {
						world.selected_row = row_index
						world.selected_column = column_index
						world.selected_unit_index = unit_index
					} else {
						world.selected_row = row_index
						world.selected_column = column_index
						world.selected_unit_index = -1
					}
					click_handled = true
					break
				}
			}
			if click_handled do break
		}
	}

	raylib.BeginDrawing()

	window_width_integer := raylib.GetScreenWidth()
	window_height_integer := raylib.GetScreenHeight()
	window_width_float := f32(window_width_integer)
	default_font := raylib.GetFontDefault()
	elapsed_time := f32(raylib.GetTime())

	raylib.DrawRectangleGradientV(
		0,
		0,
		window_width_integer,
		window_height_integer,
		{10, 8, 24, 255},
		{22, 14, 45, 255},
	)

	raylib.DrawCircleGradient(
		i32(window_width_float * 0.25),
		i32(window_height_float * 0.3),
		window_height_float * 0.5,
		{40, 20, 75, 45},
		{0, 0, 0, 0},
	)
	raylib.DrawCircleGradient(
		i32(window_width_float * 0.8),
		i32(window_height_float * 0.7),
		window_height_float * 0.6,
		{25, 45, 85, 35},
		{0, 0, 0, 0},
	)

	grid_size :: 60
	grid_color := raylib.Color{255, 255, 255, 10}

	for x: f32 = 0; x < window_width_float; x += grid_size {
		raylib.DrawLineV({x, 0}, {x, window_height_float}, grid_color)
	}
	for y: f32 = 0; y < window_height_float; y += grid_size {
		raylib.DrawLineV({0, y}, {window_width_float, y}, grid_color)
	}

	raylib.BeginMode2D(world.camera)
	for row, row_index in world.grid.tiles {
		for tile, column_index in row {
			tile_position := grid_tile_position(row_index, column_index)
			is_selected := row_index == world.selected_row && column_index == world.selected_column
			tile_draw(tile, tile_position, TILE_RADIUS, game_state, is_selected)
		}
	}
	for index in 0 ..< world.unit_count {
		unit_draw(world.units[index], &game_state.assets)
	}
	raylib.EndMode2D()

	if world.state == .Playing {
		world_draw_spawn_buttons(world, game_state, default_font, ui_scale)

		hud_width := 640 * ui_scale
		hud_height := 74 * ui_scale
		hud_rectangle := raylib.Rectangle {
			(window_width_float - hud_width) / 2,
			12,
			hud_width,
			hud_height,
		}

		raylib.DrawRectangleRounded(
			{
				hud_rectangle.x + (3 * ui_scale),
				hud_rectangle.y + (3 * ui_scale),
				hud_rectangle.width,
				hud_rectangle.height,
			},
			0.2,
			6,
			{10, 10, 15, 160},
		)
		raylib.DrawRectangleRounded(hud_rectangle, 0.2, 6, {28, 28, 38, 235})
		raylib.DrawRectangleRoundedLinesEx(
			hud_rectangle,
			0.2,
			6,
			2 * ui_scale,
			raylib.Color{45, 45, 65, 255},
		)

		money_string_builder := strings.builder_make(context.temp_allocator)
		fmt.sbprint(
			&money_string_builder,
			"PLAYER GOLD: ",
			world.player_money,
			"  |  ENEMY GOLD: ",
			world.enemy_money,
		)
		if money_text, err := strings.to_cstring(&money_string_builder); err == nil {
			text_position := linalg.Vector2f32 {
				window_width_float / 2,
				hud_rectangle.y + 18 * ui_scale,
			}
			draw_text(
				money_text,
				text_position + {2 * ui_scale, 2 * ui_scale},
				default_font,
				16 * ui_scale,
				.Center,
				tint = raylib.Color{10, 10, 15, 255},
			)
			draw_text(
				money_text,
				text_position,
				default_font,
				16 * ui_scale,
				.Center,
				tint = raylib.WHITE,
			)
		}

		turn_text_position := linalg.Vector2f32 {
			window_width_float / 2,
			hud_rectangle.y + 44 * ui_scale,
		}

		if world.current_turn == .Player {
			pulse_alpha_value := u8(200 + 55 * f32(math.sin(elapsed_time * 4.0)))
			draw_text(
				"YOUR TURN",
				turn_text_position + {1 * ui_scale, 1 * ui_scale},
				default_font,
				16 * ui_scale,
				.Center,
				tint = raylib.Color{0, 20, 0, 255},
			)
			draw_text(
				"YOUR TURN",
				turn_text_position,
				default_font,
				16 * ui_scale,
				.Center,
				tint = raylib.Color{50, 220, 110, pulse_alpha_value},
			)

			enter_text: cstring = "PRESS [ENTER] TO END TURN"
			enter_font_size := 16 * ui_scale
			enter_text_pos := linalg.Vector2f32 {
				window_width_float - (140 * ui_scale),
				window_height_float - (24 * ui_scale),
			}
			draw_text(
				enter_text,
				enter_text_pos + {2 * ui_scale, 2 * ui_scale},
				default_font,
				enter_font_size,
				.Center,
				tint = raylib.Color{10, 10, 15, 180},
			)
			draw_text(
				enter_text,
				enter_text_pos,
				default_font,
				enter_font_size,
				.Center,
				tint = raylib.Color{200, 200, 220, pulse_alpha_value},
			)

		} else {
			draw_text(
				"ENEMY ACTION...",
				turn_text_position + {1 * ui_scale, 1 * ui_scale},
				default_font,
				16 * ui_scale,
				.Center,
				tint = raylib.Color{20, 0, 0, 255},
			)
			draw_text(
				"ENEMY ACTION...",
				turn_text_position,
				default_font,
				16 * ui_scale,
				.Center,
				tint = raylib.Color{230, 70, 70, 255},
			)
		}
	} else {
		overlay_color := raylib.Color{0, 0, 0, 200}
		raylib.DrawRectangle(0, 0, window_width_integer, window_height_integer, overlay_color)

		if world.state == .Paused {
			panel_width := f32(300) * ui_scale
			panel_height := f32(250) * ui_scale
			panel_x := (window_width_float - panel_width) / 2
			panel_y := (window_height_float - panel_height) / 2
			pause_panel := raylib.Rectangle {
				x      = panel_x,
				y      = panel_y,
				width  = panel_width,
				height = panel_height,
			}

			raylib.DrawRectangleRounded(
				{
					pause_panel.x + 4 * ui_scale,
					pause_panel.y + 4 * ui_scale,
					pause_panel.width,
					pause_panel.height,
				},
				0.15,
				8,
				{10, 10, 15, 180},
			)
			raylib.DrawRectangleRounded(pause_panel, 0.15, 8, {25, 25, 35, 240})
			raylib.DrawRectangleRoundedLinesEx(pause_panel, 0.15, 8, 2 * ui_scale, raylib.GOLD)

			draw_text(
				"PAUSED",
				{window_width_float / 2, panel_y + 40 * ui_scale},
				default_font,
				32 * ui_scale,
				.Center,
				tint = raylib.WHITE,
			)

			button_width := f32(200) * ui_scale
			button_height := f32(50) * ui_scale
			button_x := (window_width_float - button_width) / 2

			resume_rectangle := raylib.Rectangle {
				x      = button_x,
				y      = panel_y + 100 * ui_scale,
				width  = button_width,
				height = button_height,
			}
			menu_rectangle := raylib.Rectangle {
				x      = button_x,
				y      = panel_y + 170 * ui_scale,
				width  = button_width,
				height = button_height,
			}

			menu_button_style := Button_Style {
				font             = default_font,
				font_size        = 20 * ui_scale,
				text_color       = raylib.WHITE,
				normal_color     = raylib.Color{45, 45, 60, 255},
				hover_color      = raylib.Color{65, 65, 85, 255},
				pressed_color    = raylib.Color{30, 30, 45, 255},
				border_color     = raylib.GOLD,
				border_thickness = 2 * ui_scale,
				roundness        = 0.2,
				segments         = 6,
			}

			if button(resume_rectangle, "Resume", menu_button_style) {
				world.state = .Playing
			}

			if button(menu_rectangle, "Main Menu", menu_button_style) {
				game_state.main_menu = {}
				main_menu_init(&game_state.main_menu, game_state)
				game_state.scene = .Main_Menu
			}
		} else if world.state == .Player_Won || world.state == .Enemy_Won {
			status_text: cstring
			if world.state == .Player_Won {
				status_text = "VICTORY! (PRESS ENTER TO RESTART)"
			} else if world.state == .Enemy_Won {
				status_text = "DEFEAT... (PRESS ENTER TO RESTART)"
			}

			status_position := linalg.Vector2f32{window_width_float / 2, window_height_float / 2}
			draw_text(
				status_text,
				status_position,
				default_font,
				32 * ui_scale,
				.Center,
				tint = raylib.WHITE,
			)
		}
	}

	if world.world_fade > 0 {
		raylib.DrawRectangle(
			0,
			0,
			window_width_integer,
			window_height_integer,
			{0, 0, 0, u8(255 * world.world_fade)},
		)
		world.world_fade -= 1.5 * raylib.GetFrameTime()
		if world.world_fade < 0 do world.world_fade = 0
	}

	raylib.EndDrawing()
}
