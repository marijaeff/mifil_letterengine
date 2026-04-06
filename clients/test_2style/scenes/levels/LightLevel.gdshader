shader_type canvas_item;

uniform vec2 light_pos = vec2(0.5, 0.5);
uniform float radius = 0.07;
uniform float softness = 0.025;
uniform float darkness = 1.0;

void fragment() {

    vec2 aspect = vec2(SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x, 1.0);

    vec2 diff = (UV - light_pos) * aspect;

    float dist = length(diff);

    float mask = smoothstep(radius - softness, radius, dist);

	COLOR = vec4(0.055, 0.031, 0.133, mask * darkness);
}