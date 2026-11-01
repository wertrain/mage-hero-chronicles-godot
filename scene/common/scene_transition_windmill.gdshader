shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float rotation = 0.0;
uniform vec4 cover_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float edge_softness : hint_range(0.0, 0.05) = 0.006;
uniform float step_size_pixels = 16.0;

void fragment() {
	// 各象限を中心から見た距離にそろえ、斜めの境界を作る。
	vec2 centered = UV * 2.0 - vec2(1.0);
	vec2 local_position = abs(centered);
	// 0以下なら滑らかな境界、正の値なら矩形単位の階段状境界にする。
	if (step_size_pixels > 1.0) {
		vec2 half_view_pixels = vec2(0.5) / SCREEN_PIXEL_SIZE;
		vec2 step_counts = max(half_view_pixels / step_size_pixels, vec2(1.0));
		local_position = ceil(local_position * step_counts) / step_counts;
	}
	float quadrant = 0.0;
	if (centered.x >= 0.0 && centered.y < 0.0) {
		quadrant = 1.0;
	} else if (centered.x >= 0.0 && centered.y >= 0.0) {
		quadrant = 2.0;
	} else if (centered.x < 0.0 && centered.y >= 0.0) {
		quadrant = 3.0;
	}

	// 四つの境界を90度ずつずらし、回転しながら同時に画面を覆う。
	float angle = 0.78539816339 + quadrant * 1.57079632679 + rotation;
	vec2 direction = vec2(cos(angle), sin(angle));
	float projection = dot(local_position, direction);
	float projection_min = min(direction.x, 0.0) + min(direction.y, 0.0);
	float projection_max = max(direction.x, 0.0) + max(direction.y, 0.0);
	float front_position = (projection - projection_min) / max(projection_max - projection_min, 0.0001);
	float covered = 1.0 - smoothstep(progress - edge_softness, progress + edge_softness, front_position);

	COLOR = cover_color;
	COLOR.a *= covered;
}
