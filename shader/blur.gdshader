shader_type canvas_item;

uniform sampler2D screen_texture;
uniform float blur_amount : hint_range(0.0, 10.0) = 5.0;

void fragment() {
    vec4 color = vec4(0.0);
    vec2 texel_size = vec2(blur_amount / 512.0); // 調整
    
    color += texture(screen_texture, UV + texel_size * vec2(-1.0, -1.0));
    color += texture(screen_texture, UV + texel_size * vec2( 1.0, -1.0));
    color += texture(screen_texture, UV + texel_size * vec2(-1.0,  1.0));
    color += texture(screen_texture, UV + texel_size * vec2( 1.0,  1.0));
    color += texture(screen_texture, UV);
    color /= 5.0;

    COLOR = color;
}
