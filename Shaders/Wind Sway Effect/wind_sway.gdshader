shader_type canvas_item;

// Intended for atlas tiles on a vegetation-only TileMapLayer.
// REGION_RECT keeps sampling inside each tile's atlas region.
uniform float wind_strength : hint_range(0.0, 0.08, 0.001) = 0.012;
uniform float wind_speed : hint_range(0.1, 5.0, 0.05) = 1.15;
uniform float bend_power : hint_range(0.5, 6.0, 0.1) = 2.4;
uniform float phase_variation : hint_range(0.0, 10.0, 0.1) = 2.5;

void fragment() {
	vec2 local_uv = (UV - REGION_RECT.xy) / REGION_RECT.zw;
	float top_mask = pow(clamp(1.0 - local_uv.y, 0.0, 1.0), bend_power);
	float phase = floor(VERTEX.x * 0.0625) * phase_variation;
	float offset = sin(TIME * wind_speed + phase) * wind_strength * top_mask;

	local_uv.x -= offset;
	vec2 inside = step(vec2(0.0), local_uv) * step(local_uv, vec2(1.0));
	vec2 atlas_uv = local_uv * REGION_RECT.zw + REGION_RECT.xy;

	COLOR = texture(TEXTURE, atlas_uv) * COLOR;
	COLOR.a *= inside.x * inside.y;
}
