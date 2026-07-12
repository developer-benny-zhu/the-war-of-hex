package game

import "core:math"
import "core:math/linalg"
import "vendor:raylib"

Unit_Kind :: enum {
    Peasant,
    Footman,
    Tank,
}

Unit :: struct {
    team: Team,
    kind: Unit_Kind,
    row: int,
    column: int,
    position: linalg.Vector2f32,
    target_position: linalg.Vector2f32,
    has_moved: bool, 
}

unit_cost :: proc(kind: Unit_Kind) -> i32 {
    switch kind {
    case .Peasant: return 10
    case .Footman: return 20
    case .Tank:  return 50
    }
    return 10
}

unit_combat_power :: proc(kind: Unit_Kind) -> i32 {
    switch kind {
    case .Peasant: return 1
    case .Footman: return 2
    case .Tank:  return 3
    }
    return 1
}

unit_texture_for :: proc(unit: Unit, assets: ^Assets) -> raylib.Texture2D {
    if unit.team == .Player {
        switch unit.kind {
        case .Footman: return assets.blue_footman
        case .Peasant: return assets.blue_peasant
        case .Tank:  return assets.blue_wizard
        }
    }

    switch unit.kind {
    case .Footman: return assets.red_footman
    case .Peasant: return assets.red_peasant
    case .Tank:  return assets.red_wizard
    }
    return assets.blue_peasant
}

unit_draw :: proc(unit: Unit, assets: ^Assets) {
    texture := unit_texture_for(unit, assets)
    if unit.kind == .Peasant || unit.kind == .Footman {
        draw_texture(texture, raylib.Rectangle{0, 0, f32(texture.width), f32(texture.height)}, unit.position, .Center, scale = {2, 2})
    }
    else {
        draw_texture(texture, raylib.Rectangle{0, 0, f32(texture.width), f32(texture.height)}, unit.position, .Center, scale = {1, 1})
    }
    if unit.has_moved {
        raylib.DrawCircleV(unit.position + {20, -20}, 4, raylib.GRAY)
    }
}

unit_update :: proc(unit: ^Unit) {
    move_amount := math.clamp(8 * raylib.GetFrameTime(), 0.0, 1.0)
    unit.position = linalg.lerp(unit.position, unit.target_position, move_amount)
    if get_distance(unit.position, unit.target_position) < 0.5 {
        unit.position = unit.target_position
    }
}