package game

import "core:fmt"
import "core:math"
import "core:math/linalg"
import "core:strings"
import "vendor:raylib"

CAMERA_SPEED :: 100
AI_ACTION_DELAY :: 0.7

World :: struct {
	grid:                Grid,
	camera:              Camera_2D,
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
	ai_spawn_done:       bool,
}

world_init :: proc(world: ^World, game_state: ^Game_State) {
	raylib.PlayMusicStream(game_state.assets.game_music)
	world.grid = Grid{}
	grid_init(&world.grid)
	world.camera = Camera_2D{}
	camera_2d_init(&world.camera)
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

	for i in 0 ..< world.unit_count {
		world.units[i].has_moved = false
	}
	world_clear_selection(world)
}

world_selected_tile_is_player_castle :: proc(world: ^World) -> bool {
	if world.selected_row < 0 || world.selected_column < 0 do return false
	return world.grid.tiles[world.selected_row][world.selected_column].team == .Player
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

world_is_tile_adjacent_to_pos :: proc(src_row, src_col, dst_row, dst_col: int) -> bool {
	offsets_even := [6][2]int{{0, -1}, {0, 1}, {-1, -1}, {-1, 0}, {1, -1}, {1, 0}}
	offsets_odd := [6][2]int{{0, -1}, {0, 1}, {-1, 0}, {-1, 1}, {1, 0}, {1, 1}}

	offsets := is_even(i32(src_row)) ? offsets_even : offsets_odd
	for offset in offsets {
		if src_row + offset[0] == dst_row && src_col + offset[1] == dst_col {
			return true
		}
	}
	return false
}

world_spawn_panel_rect :: proc(scale: f32) -> raylib.Rectangle {
	window_w := f32(raylib.GetScreenWidth())
	window_h := f32(raylib.GetScreenHeight())
	panel_w := f32(440) * scale
	panel_h := f32(96) * scale
	return raylib.Rectangle {
		x = (window_w - panel_w) / 2,
		y = window_h - panel_h - (26 * scale),
		width = panel_w,
		height = panel_h,
	}
}

world_unit_at_tile :: proc(world: ^World, row, column: int) -> int {
	for index in 0 ..< world.unit_count {
		unit := world.units[index]
		if unit.row == row && unit.column == column {
			return index
		}
	}
	return -1
}

world_tile_has_unit :: proc(world: ^World, row, column: int) -> bool {
	return world_unit_at_tile(world, row, column) != -1
}

world_remove_unit :: proc(world: ^World, index: int) {
	if index < 0 || index >= world.unit_count do return
	for i in index ..< world.unit_count - 1 {
		world.units[i] = world.units[i + 1]
	}
	world.unit_count -= 1
}

world_move_unit_to_tile :: proc(world: ^World, unit_index, row, column: int) {
	if unit_index < 0 || unit_index >= world.unit_count do return
	if world.units[unit_index].has_moved do return

	attacker := &world.units[unit_index]
	if attacker.team != world.current_turn do return

	is_owned := world.grid.tiles[row][column].team == attacker.team
	is_adjacent := world_is_tile_adjacent_to_pos(attacker.row, attacker.column, row, column)
	if !is_owned && !is_adjacent do return

	defender_index := world_unit_at_tile(world, row, column)
	if defender_index != -1 {
		defender := &world.units[defender_index]
		if defender.team == attacker.team do return

		attacker_power := unit_combat_power(attacker.kind)
		defender_power := unit_combat_power(defender.kind)

		if attacker_power >= defender_power {
			world_remove_unit(world, defender_index)

			actual_attacker_idx := unit_index
			if defender_index < unit_index do actual_attacker_idx -= 1

			final_attacker := &world.units[actual_attacker_idx]
			target_position := grid_tile_position(row, column)
			final_attacker.row = row
			final_attacker.column = column
			final_attacker.target_position = target_position
			final_attacker.has_moved = true
			world.grid.tiles[row][column].team = final_attacker.team
		} else {
			world_remove_unit(world, unit_index)
		}
		return
	}
	target_position := grid_tile_position(row, column)
	attacker.row = row
	attacker.column = column
	attacker.target_position = target_position
	attacker.has_moved = true
	world.grid.tiles[row][column].team = attacker.team
}

world_spawn_unit :: proc(world: ^World, kind: Unit_Kind) {
	if world.unit_count >= len(world.units) do return
	if !world_selected_tile_is_player_castle(world) do return
	if world.current_turn != .Player do return

	cost := unit_cost(kind)
	if world.player_money < cost do return

	spawn_row := world.selected_row
	spawn_column := world.selected_column
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

	castle_row := 0
	castle_col := GRID_SIZE_X - 1
	if !world.ai_spawn_done {
		if world.enemy_money >= 10 {
			chosen_kind: Unit_Kind = .Peasant
			if world.enemy_money >= 50 do chosen_kind = .Wizard
			else if world.enemy_money >= 20 do chosen_kind = .Footman

			cost := unit_cost(chosen_kind)
			if !world_tile_has_unit(world, castle_row, castle_col) {
				if world.unit_count < len(world.units) {
					spawn_pos := grid_tile_position(castle_row, castle_col)
					world.units[world.unit_count] = Unit {
						team            = .Enemy,
						kind            = chosen_kind,
						row             = castle_row,
						column          = castle_col,
						position        = spawn_pos,
						target_position = spawn_pos,
						has_moved       = true,
					}
					world.unit_count += 1
					world.enemy_money -= cost
					world.grid.tiles[castle_row][castle_col].team = .Enemy

					world.ai_timer = AI_ACTION_DELAY
					return
				}
			}
		}
		world.ai_spawn_done = true
	}
	offsets_even := [6][2]int{{0, -1}, {0, 1}, {-1, -1}, {-1, 0}, {1, -1}, {1, 0}}
	offsets_odd := [6][2]int{{0, -1}, {0, 1}, {-1, 0}, {-1, 1}, {1, 0}, {1, 1}}

	active_index := -1
	for i in 0 ..< world.unit_count {
		if world.units[i].team == .Enemy && !world.units[i].has_moved {
			active_index = i
			break
		}
	}

	if active_index == -1 {
		world_end_turn(world)
		return
	}

	unit := &world.units[active_index]
	offsets := is_even(i32(unit.row)) ? offsets_even : offsets_odd
	moved := false
	for offset in offsets {
		nr := unit.row + offset[0]
		nc := unit.column + offset[1]
		if nr >= 0 && nr < GRID_SIZE_Y && nc >= 0 && nc < GRID_SIZE_X {
			def_idx := world_unit_at_tile(world, nr, nc)
			if def_idx != -1 && world.units[def_idx].team == .Player {
				world_move_unit_to_tile(world, active_index, nr, nc)
				moved = true
				break
			}
		}
	}
	if !moved {
		for offset in offsets {
			nr := unit.row + offset[0]
			nc := unit.column + offset[1]
			if nr >= 0 && nr < GRID_SIZE_Y && nc >= 0 && nc < GRID_SIZE_X {
				if !world_tile_has_unit(world, nr, nc) && world.grid.tiles[nr][nc].team != .Enemy {
					world_move_unit_to_tile(world, active_index, nr, nc)
					moved = true
					break
				}
			}
		}
	}
	if !moved {
		frontline_loop: for r in 0 ..< GRID_SIZE_Y {
			for c in 0 ..< GRID_SIZE_X {
				if world.grid.tiles[r][c].team == .Enemy && !world_tile_has_unit(world, r, c) {
					check_offsets := is_even(i32(r)) ? offsets_even : offsets_odd
					is_frontline := false
					for co in check_offsets {
						cr := r + co[0]
						cc := c + co[1]
						if cr >= 0 && cr < GRID_SIZE_Y && cc >= 0 && cc < GRID_SIZE_X {
							if world.grid.tiles[cr][cc].team == .Player ||
							   world_unit_at_tile(world, cr, cc) != -1 {
								is_frontline = true
								break
							}
						}
					}

					if is_frontline {
						world_move_unit_to_tile(world, active_index, r, c)
						moved = true
						break frontline_loop
					}
				}
			}
		}
	}

	if !moved {
		world.units[active_index].has_moved = true
	}

	world.ai_timer = AI_ACTION_DELAY
}

world_draw_spawn_buttons :: proc(
	world: ^World,
	game_state: ^Game_State,
	font: raylib.Font,
	scale: f32,
) {
	if !world_selected_tile_is_player_castle(world) do return

	panel := world_spawn_panel_rect(scale)

	raylib.DrawRectangleRounded(
		{panel.x + (4 * scale), panel.y + (4 * scale), panel.width, panel.height},
		0.15,
		8,
		{10, 10, 15, 180},
	)
	raylib.DrawRectangleRounded(panel, 0.15, 8, {25, 25, 35, 240})
	raylib.DrawRectangleRoundedLinesEx(panel, 0.15, 8, 2 * scale, raylib.GOLD)

	button_w := f32(124) * scale
	button_h := f32(44) * scale
	button_y := panel.y + (panel.height - button_h) / 2
	button_gap := f32(12) * scale
	button_start_x := panel.x + (panel.width - (button_w * 3 + button_gap * 2)) / 2

	button_rects := [3]raylib.Rectangle {
		{x = button_start_x, y = button_y, width = button_w, height = button_h},
		{
			x = button_start_x + button_w + button_gap,
			y = button_y,
			width = button_w,
			height = button_h,
		},
		{
			x = button_start_x + (button_w + button_gap) * 2,
			y = button_y,
			width = button_w,
			height = button_h,
		},
	}

	button_labels := [3]cstring{"Wizard (50)", "Footman (20)", "Peasant (10)"}
	costs := [3]i32{50, 20, 10}

	button_style := Button_Style {
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
		current_style := button_style
		if world.player_money < costs[index] {
			current_style.text_color = raylib.Color{130, 130, 130, 255}
			current_style.normal_color = raylib.Color{25, 25, 30, 255}
			current_style.border_color = raylib.Color{80, 80, 80, 255}
		}

		if button(button_rects[index], button_labels[index], current_style) &&
		   world.player_money >= costs[index] {
			if index == 0 do world_spawn_unit(world, .Wizard)
			if index == 1 do world_spawn_unit(world, .Footman)
			if index == 2 do world_spawn_unit(world, .Peasant)
		}
	}
}

world_update :: proc(world: ^World, game_state: ^Game_State) {
	raylib.UpdateMusicStream(game_state.assets.game_music)
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
	wheel_move := raylib.GetMouseWheelMoveV()
	if wheel_move.x != 0 || wheel_move.y != 0 {
		zoom_change += (wheel_move.x + wheel_move.y) * 0.1
	}

	world.camera.zoom = (f32(raylib.GetScreenHeight()) / f32(VIRTUAL_SCREEN_HEIGHT)) * world.zoom
	if zoom_change != 0 {
		mouse_position := raylib.GetMousePosition()
		mouse_world_before := raylib.GetScreenToWorld2D(mouse_position, world.camera)
		world.zoom += zoom_change
		world.zoom = math.clamp(world.zoom, 0.5, 3.0)
		world.camera.zoom =
			(f32(raylib.GetScreenHeight()) / f32(VIRTUAL_SCREEN_HEIGHT)) * world.zoom
		mouse_world_after := raylib.GetScreenToWorld2D(mouse_position, world.camera)
		world.camera.target += mouse_world_before - mouse_world_after
	}

	if raylib.IsKeyDown(MOVE_UP) do world.camera.velocity.y = -CAMERA_SPEED * raylib.GetFrameTime()
	if raylib.IsKeyDown(MOVE_DOWN) do world.camera.velocity.y = CAMERA_SPEED * raylib.GetFrameTime()
	if raylib.IsKeyDown(MOVE_LEFT) do world.camera.velocity.x = -CAMERA_SPEED * raylib.GetFrameTime()
	if raylib.IsKeyDown(MOVE_RIGHT) do world.camera.velocity.x = CAMERA_SPEED * raylib.GetFrameTime()
	camera_2d_update(&world.camera)

	window_h := f32(raylib.GetScreenHeight())
	scale := window_h / f32(VIRTUAL_SCREEN_HEIGHT)

	if world.current_turn == .Player &&
	   !world.dialog.active &&
	   raylib.IsMouseButtonPressed(.LEFT) {
		mouse_position := raylib.GetScreenToWorld2D(raylib.GetMousePosition(), world.camera)
		found := false
		if world_selected_tile_is_player_castle(world) {
			mouse_screen := raylib.GetMousePosition()
			if raylib.CheckCollisionPointRec(mouse_screen, world_spawn_panel_rect(scale)) {
				found = true
			}
		}
		for row, row_index in world.grid.tiles {
			if found do break
			for _, column_index in row {
				tile_position := grid_tile_position(row_index, column_index)
				if get_distance(mouse_position, tile_position) <= TILE_RADIUS {
					if world.selected_row == row_index && world.selected_column == column_index {
						world_clear_selection(world)
						found = true
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
						found = true
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
					found = true
					break
				}
			}
			if found do break
		}
	}

	raylib.BeginDrawing()

	ww_i := raylib.GetScreenWidth()
	wh_i := raylib.GetScreenHeight()
	window_w := f32(ww_i)
	font := raylib.GetFontDefault()
	time := f32(raylib.GetTime())

	raylib.DrawRectangleGradientV(0, 0, ww_i, wh_i, {10, 8, 24, 255}, {22, 14, 45, 255})

	raylib.DrawCircleGradient(
		i32(window_w * 0.25),
		i32(window_h * 0.3),
		window_h * 0.5,
		{40, 20, 75, 45},
		{0, 0, 0, 0},
	)
	raylib.DrawCircleGradient(
		i32(window_w * 0.8),
		i32(window_h * 0.7),
		window_h * 0.6,
		{25, 45, 85, 35},
		{0, 0, 0, 0},
	)

	for i in 0 ..< 45 {
		val := i32(i * 1337 + 73)
		sx_base := val % ww_i
		sy_base := (val / 3) % wh_i

		parallax_x := i32(-world.camera.target.x * 0.04 * (f32(i % 3) + 1.0))
		parallax_y := i32(-world.camera.target.y * 0.04 * (f32(i % 3) + 1.0))

		final_sx := (sx_base + parallax_x) % ww_i
		if final_sx < 0 do final_sx += ww_i
		final_sy := (sy_base + parallax_y) % wh_i
		if final_sy < 0 do final_sy += wh_i

		brightness := u8(160 + 95 * math.sin(time * 1.5 + f32(i)))
		size := i % 3 == 0 ? 2 : 1

		if size > 1 {
			raylib.DrawCircle(final_sx, final_sy, f32(size), {255, 255, 255, brightness})
		} else {
			raylib.DrawPixel(final_sx, final_sy, {230, 240, 255, brightness})
		}
	}

	raylib.BeginMode2D(world.camera)
	for row, row_index in world.grid.tiles {
		for tile, column_index in row {
			tile_position := grid_tile_position(row_index, column_index)
			selected := row_index == world.selected_row && column_index == world.selected_column
			tile_draw(tile, tile_position, TILE_RADIUS, game_state, selected)
		}
	}
	for index in 0 ..< world.unit_count {
		unit_draw(world.units[index], &game_state.assets)
	}
	raylib.EndMode2D()

	world_draw_spawn_buttons(world, game_state, font, scale)

	hud_w := 640 * scale
	hud_h := 74 * scale
	hud_rect := raylib.Rectangle{(window_w - hud_w) / 2, 12, hud_w, hud_h}

	raylib.DrawRectangleRounded(
		{hud_rect.x + (3 * scale), hud_rect.y + (3 * scale), hud_rect.width, hud_rect.height},
		0.2,
		6,
		{10, 10, 15, 160},
	)
	raylib.DrawRectangleRounded(hud_rect, 0.2, 6, {28, 28, 38, 235})
	raylib.DrawRectangleRoundedLinesEx(hud_rect, 0.2, 6, 2 * scale, raylib.Color{45, 45, 65, 255})

	money_builder := strings.builder_make(context.temp_allocator)
	fmt.sbprint(
		&money_builder,
		"PLAYER GOLD: ",
		world.player_money,
		"  |  ENEMY GOLD: ",
		world.enemy_money,
	)
	if money_text, err := strings.to_cstring(&money_builder); err == nil {
		text_pos := linalg.Vector2f32{window_w / 2, hud_rect.y + 18 * scale}
		draw_text(
			money_text,
			text_pos + {2 * scale, 2 * scale},
			font,
			16 * scale,
			.Center,
			tint = raylib.Color{10, 10, 15, 255},
		)
		draw_text(money_text, text_pos, font, 16 * scale, .Center, tint = raylib.WHITE)
	}

	turn_pos := linalg.Vector2f32{window_w / 2, hud_rect.y + 44 * scale}
	if world.current_turn == .Player {
		pulse_alpha := u8(200 + 55 * f32(math.sin(time * 4.0)))
		draw_text(
			"YOUR TURN",
			turn_pos + {1 * scale, 1 * scale},
			font,
			16 * scale,
			.Center,
			tint = raylib.Color{0, 20, 0, 255},
		)
		draw_text(
			"YOUR TURN",
			turn_pos,
			font,
			16 * scale,
			.Center,
			tint = raylib.Color{50, 220, 110, pulse_alpha},
		)
	} else {
		draw_text(
			"ENEMY ACTION...",
			turn_pos + {1 * scale, 1 * scale},
			font,
			16 * scale,
			.Center,
			tint = raylib.Color{20, 0, 0, 255},
		)
		draw_text(
			"ENEMY ACTION...",
			turn_pos,
			font,
			16 * scale,
			.Center,
			tint = raylib.Color{230, 70, 70, 255},
		)
	}

	if world.world_fade > 0 {
		raylib.DrawRectangle(
			0,
			0,
			raylib.GetScreenWidth(),
			raylib.GetScreenHeight(),
			{0, 0, 0, u8(255 * world.world_fade)},
		)
		world.world_fade -= 1.5 * raylib.GetFrameTime()
		if world.world_fade < 0 do world.world_fade = 0
	}
	raylib.EndDrawing()
}
