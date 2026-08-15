shader_type canvas_item;

// Intended for a complete tree Sprite2D, not a tree assembled from TileMap cells.
uniform float wind_strength : hint_range(0.0, 0.08, 0.001) = 0.009;
uniform float wind_speed : hint_range(0.1, 5.0, 0.05) = 0.85;
uniform float bend_power : hint_range(0.5, 6.0, 0.1) = 2.0;
uniform float phase_offset : hint_range(0.0, 6.283, 0.01) = 0.0;

void fragment() {
	vec2 uv = UV;
	float top_mask = pow(clamp(1.0 - uv.y, 0.0, 1.0), bend_power);
	uv.x -= sin(TIME * wind_speed + phase_offset) * wind_strength * top_mask;

	vec2 inside = step(vec2(0.0), uv) * step(uv, vec2(1.0));
	COLOR = texture(TEXTURE, uv) * COLOR;
	COLOR.a *= inside.x * inside.y;
}

