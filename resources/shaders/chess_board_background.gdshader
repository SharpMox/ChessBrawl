shader_type canvas_item;

uniform vec4 color_light : source_color = vec4(0.15, 0.15, 0.18, 1.0);
uniform vec4 color_dark : source_color = vec4(0.10, 0.10, 0.13, 1.0);
uniform float tile_count : hint_range(2.0, 32.0) = 10.0;
uniform vec2 scroll_speed = vec2(0.03, 0.03);

void fragment() {
	vec2 offset = scroll_speed * TIME;
	float aspect = SCREEN_PIXEL_SIZE.x / SCREEN_PIXEL_SIZE.y;
	vec2 uv_square = vec2(UV.x, UV.y * aspect);
	vec2 cell = floor((uv_square + offset) * tile_count);
	float checker = mod(cell.x + cell.y, 2.0);
	COLOR = mix(color_light, color_dark, checker);
}
