shader_type canvas_item;
render_mode unshaded, blend_add;

uniform float radius_px : hint_range(0.0, 16.0) = 7.0;
uniform float softness  : hint_range(0.1, 3.0)  = 1.1;
uniform float intensity : hint_range(0.0, 8.0)  = 3.5;

void fragment() {
    float a = texture(TEXTURE, UV).a;

    float inside = smoothstep(0.05, 0.35, a);

    vec2 px = TEXTURE_PIXEL_SIZE * radius_px;

    float m = 0.0;
    m = max(m, texture(TEXTURE, UV + vec2( px.x, 0.0)).a);
    m = max(m, texture(TEXTURE, UV + vec2(-px.x, 0.0)).a);
    m = max(m, texture(TEXTURE, UV + vec2(0.0,  px.y)).a);
    m = max(m, texture(TEXTURE, UV + vec2(0.0, -px.y)).a);
    m = max(m, texture(TEXTURE, UV + vec2( px.x,  px.y)).a);
    m = max(m, texture(TEXTURE, UV + vec2(-px.x,  px.y)).a);
    m = max(m, texture(TEXTURE, UV + vec2( px.x, -px.y)).a);
    m = max(m, texture(TEXTURE, UV + vec2(-px.x, -px.y)).a);

    float ring = max(m - inside, 0.0);

    ring = pow(ring, 1.0 / softness);

    vec3 col = COLOR.rgb * intensity;
    COLOR = vec4(col, ring * COLOR.a);
}