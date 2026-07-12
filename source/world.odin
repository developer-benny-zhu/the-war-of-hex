package game

import "core:fmt"
import "core:strings"
import "vendor:raylib"
import "core:math/linalg"
import "core:math"

CAMERA_SPEED :: 100
AI_ACTION_DELAY :: 0.7

World :: struct {
    grid: Grid,
    camera: Camera_2D,
    zoom: f32,
    world_fade: f32,
    current_turn: Team,
    ai_timer: f32,
    player_money: i32,
    enemy_money: i32,
    dialog: Dialog,
    units: [64]Unit,
    unit_count: int,
    selected_row: int,
    selected_column: int,
    selected_unit_index: int,
    ai_spawn_done: bool,
}

world_init :: proc(world: ^World) {
    world.grid = Grid {}
    grid_init(&world.grid)
    world.camera = Camera_2D {}
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
    offsets_even := [6][2]int{{0,-1}, {0,1}, {-1,-1}, {-1,0}, {1,-1}, {1,0}}
    offsets_odd  := [6][2]int{{0,-1}, {0,1}, {-1,0}, {-1,1}, {1,0}, {1,1}}

    offsets := is_even(i32(src_row)) ? offsets_even : offsets_odd
    for offset in offsets {
        if src_row + offset[0] == dst_row && src_col + offset[1] == dst_col {
            return true
        }
    }
    return false
}

world_spawn_panel_rect :: proc() -> raylib.Rectangle {
    window_w := f32(raylib.GetScreenWidth())
    window_h := f32(raylib.GetScreenHeight())
    panel_w := f32(420)
    panel_h := f32(92)
    return raylib.Rectangle{
        x = (window_w - panel_w) / 2,
        y = window_h - panel_h - 26,
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

    world.units[world.unit_count] = Unit{
        team = .Player,
        kind = kind,
        row = spawn_row,
        column = spawn_column,
        position = spawn_position,
        target_position = spawn_position,
        has_moved = true,
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
            chosen_kind : Unit_Kind = .Peasant
            if world.enemy_money >= 50 do chosen_kind = .Wizard
            else if world.enemy_money >= 20 do chosen_kind = .Footman
            
            cost := unit_cost(chosen_kind)
            if !world_tile_has_unit(world, castle_row, castle_col) {
                if world.unit_count < len(world.units) {
                    spawn_pos := grid_tile_position(castle_row, castle_col)
                    world.units[world.unit_count] = Unit{
                        team = .Enemy,
                        kind = chosen_kind,
                        row = castle_row,
                        column = castle_col,
                        position = spawn_pos,
                        target_position = spawn_pos,
                        has_moved = true, 
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
    offsets_even := [6][2]int{{0,-1}, {0,1}, {-1,-1}, {-1,0}, {1,-1}, {1,0}}
    offsets_odd  := [6][2]int{{0,-1}, {0,1}, {-1,0}, {-1,1}, {1,0}, {1,1}}

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
                            if world.grid.tiles[cr][cc].team == .Player || world_unit_at_tile(world, cr, cc) != -1 {
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

world_draw_spawn_buttons :: proc(world: ^World, game_state: ^Game_State) {
    if !world_selected_tile_is_player_castle(world) do return

    panel := world_spawn_panel_rect()
    raylib.DrawRectangleRounded(panel, 0.12, 6, {22, 22, 28, 220})
    raylib.DrawRectangleRoundedLinesEx(panel, 0.12, 6, 2, {235, 230, 220, 160})

    button_w := f32(118)
    button_h := f32(40)
    button_y := panel.y + 24
    button_gap := f32(12)
    button_start_x := panel.x + (panel.width - (button_w * 3 + button_gap * 2)) / 2

    button_rects := [3]raylib.Rectangle{
        {x = button_start_x, y = button_y, width = button_w, height = button_h},
        {x = button_start_x + button_w + button_gap, y = button_y, width = button_w, height = button_h},
        {x = button_start_x + (button_w + button_gap) * 2, y = button_y, width = button_w, height = button_h},
    }
    button_labels := [3]cstring{ "Wizard (50)", "Footman (20)", "Peasant (10)" }

    for index in 0 ..< 3 {
        raylib.DrawRectangleRounded(button_rects[index], 0.2, 6, {54, 48, 62, 255})
        raylib.DrawRectangleRoundedLinesEx(button_rects[index], 0.2, 6, 2, {255, 255, 255, 70})
        center := linalg.Vector2f32{button_rects[index].x + button_rects[index].width / 2, button_rects[index].y + button_rects[index].height / 2}
        draw_text(button_labels[index], center, raylib.GetFontDefault(), 15, .Center, tint = raylib.WHITE)
    }

    if raylib.IsMouseButtonPressed(.LEFT) {
        mouse_position := raylib.GetMousePosition()
        if raylib.CheckCollisionPointRec(mouse_position, button_rects[0]) {
            world_spawn_unit(world, .Wizard)
        } else if raylib.CheckCollisionPointRec(mouse_position, button_rects[1]) {
            world_spawn_unit(world, .Footman)
        } else if raylib.CheckCollisionPointRec(mouse_position, button_rects[2]) {
            world_spawn_unit(world, .Peasant)
        }
    }
}

world_update :: proc(world: ^World, game_state: ^Game_State) {
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
        world.camera.zoom = (f32(raylib.GetScreenHeight()) / f32(VIRTUAL_SCREEN_HEIGHT)) * world.zoom
        mouse_world_after := raylib.GetScreenToWorld2D(mouse_position, world.camera)
        world.camera.target += mouse_world_before - mouse_world_after
    }

    if raylib.IsKeyDown(MOVE_UP)    do world.camera.velocity.y = -CAMERA_SPEED * raylib.GetFrameTime()
    if raylib.IsKeyDown(MOVE_DOWN)  do world.camera.velocity.y = CAMERA_SPEED * raylib.GetFrameTime()
    if raylib.IsKeyDown(MOVE_LEFT)  do world.camera.velocity.x = -CAMERA_SPEED * raylib.GetFrameTime()
    if raylib.IsKeyDown(MOVE_RIGHT) do world.camera.velocity.x = CAMERA_SPEED * raylib.GetFrameTime()
    camera_2d_update(&world.camera)

    if world.current_turn == .Player && !world.dialog.active && raylib.IsMouseButtonPressed(.LEFT) {
        mouse_position := raylib.GetScreenToWorld2D(raylib.GetMousePosition(), world.camera)
        found := false
        if world_selected_tile_is_player_castle(world) {
            mouse_screen := raylib.GetMousePosition()
            if raylib.CheckCollisionPointRec(mouse_screen, world_spawn_panel_rect()) {
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
                        world_move_unit_to_tile(world, world.selected_unit_index, row_index, column_index)
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
    raylib.ClearBackground(raylib.BLACK)
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
    
    world_draw_spawn_buttons(world, game_state)
    
    money_builder := strings.builder_make(context.temp_allocator)
    fmt.sbprint(&money_builder, "Player Gold: ", world.player_money, "   Enemy Gold: ", world.enemy_money)
    if money_text, err := strings.to_cstring(&money_builder); err == nil {
        raylib.DrawText(money_text, 18, 16, 20, raylib.WHITE)
    }
    
    if world.current_turn == .Player {
        raylib.DrawText("PLAYER TURN (Press ENTER to end)", 18, 40, 20, raylib.GREEN)
    } else {
        raylib.DrawText("ENEMY TURN...", 18, 40, 20, raylib.RED)
    }

    if world.world_fade > 0 {
        raylib.DrawRectangle(0, 0, raylib.GetScreenWidth(), raylib.GetScreenHeight(), {0, 0, 0, u8(255 * world.world_fade)})
        world.world_fade -= 1.5 * raylib.GetFrameTime()
        if world.world_fade < 0 do world.world_fade = 0
    }
    raylib.EndDrawing()
}