shader_type canvas_item;
render_mode unshaded, blend_add;

void fragment() {
    float a = texture(TEXTURE, UV).a;

    COLOR = vec4(COLOR.rgb, a * COLOR.a);
}