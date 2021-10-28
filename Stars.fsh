// Stars.fsh

//uniform vec2 u_offset;
//uniform vec2 u_tiling;

#include <metal_stdlib>
using namespace metal;

void main() {
    vec2 uv = v_tex_coord.xy + u_offset;
    vec2 phase = fract(uv / u_tiling);
    vec4 current_color = texture2D(u_texture, phase);

    gl_FragColor = current_color;
}
