// =============================================================
//  Aurora BRD — particle.fsh
// =============================================================
#version 300 es
precision mediump float;

#include "include/config.glsl"
#include "include/lighting.glsl"

uniform sampler2D TEXTURE_0;

in vec2 v_UV;
in vec4 v_Color;

out vec4 FragColor;

void main() {
    vec4 tex = texture(TEXTURE_0, v_UV) * v_Color;
    if (tex.a < 0.01) discard;

    vec3 col = SRGBToLinear(tex.rgb);
    col      = ApplyTonemap(col);
    col      = LinearToSRGB(col);

    FragColor = vec4(col, tex.a);
}
