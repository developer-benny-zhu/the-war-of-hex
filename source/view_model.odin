package game


import "core:math"
import "core:math/linalg"
import "vendor:raylib"


BLASTER_A_VIEW_MODEL_POSITION :: linalg.Vector3f32{0.25, -0.2, -1}
BLASTER_A_BOB_X_AMPLITUDE :: 0.01
BLASTER_A_BOB_Y_AMPLITUDE :: 0.01
BLASTER_A_BOB_Y_FREQUENCY :: 1
BLASTER_A_BOB_X_FREQUENCY :: 1
BLASTER_A_BOB_SPEED :: 8.0
BLASTER_A_VIEW_MODEL_RETURN_SPEED :: 10
BLASTER_A_IDLE_SWAY_X_AMPLITUDE :: 0.005
BLASTER_A_IDLE_SWAY_Y_AMPLITUDE :: 0.005
BLASTER_A_IDLE_SWAY_SPEED :: 1.5


View_Model :: struct {
	position:  linalg.Vector3f32,
	kind:      View_Model_Kind,
	bob_time:  f32,
	idle_time: f32,
}

View_Model_Kind :: enum u8 {
	Blaster_A,
}

view_model_draw :: proc(view_model: View_Model, assets: Assets) {
	switch view_model.kind {
	case .Blaster_A:
		raylib.DrawModel(assets.blaster_a, view_model.position, 1, raylib.WHITE)
	}
}


update_view_model_idle_sway_animation :: proc(
	target_position: ^linalg.Vector3f32,
	view_model: ^View_Model,
	delta_time: f32,
) {
	view_model.idle_time += delta_time * BLASTER_A_IDLE_SWAY_SPEED
	target_position.x += math.sin(view_model.idle_time) * BLASTER_A_IDLE_SWAY_X_AMPLITUDE
	target_position.y += math.cos(view_model.idle_time * 1.3) * BLASTER_A_IDLE_SWAY_Y_AMPLITUDE
}

update_view_model_bob_animation :: proc(
	target_position: ^linalg.Vector3f32,
	view_model: ^View_Model,
	player: Player,
	delta_time: f32,
) {
	if player_is_moving(player) {
		view_model.bob_time += delta_time * BLASTER_A_BOB_SPEED
		target_position.x +=
			math.cos(view_model.bob_time * BLASTER_A_BOB_X_FREQUENCY) * BLASTER_A_BOB_X_AMPLITUDE
		target_position.y +=
			math.abs(math.sin(view_model.bob_time * BLASTER_A_BOB_Y_FREQUENCY)) *
			BLASTER_A_BOB_Y_AMPLITUDE
	}
}


update_view_model_animation :: proc(view_model: ^View_Model, player: Player, delta_time: f32) {
	target_position := BLASTER_A_VIEW_MODEL_POSITION
	update_view_model_bob_animation(&target_position, view_model, player, delta_time)
    update_view_model_idle_sway_animation(&target_position, view_model, delta_time)

	view_model.position = linalg.lerp(
		view_model.position,
		target_position,
		delta_time * BLASTER_A_VIEW_MODEL_RETURN_SPEED,
	)

}
