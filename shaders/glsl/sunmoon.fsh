// =============================================================
//  Aurora BRD — sunmoon.fsh
// =============================================================
#version 300 es
precision highp float;

#include "include/config.glsl"

uniform sampler2D TEXTURE_0;
uniform vec4 SunMoonColor;
uniform vec4 LightWorldSpaceDirection;
uniform vec4 ViewPositionAndTime;

in vec2 v_UV;
in vec4 v_Color;
in vec3 v_RayDir;

out vec4 FragColor;

void main() {
    vec4 tex = texture(TEXTURE_0, v_UV);
    if (tex.a < 0.01) discard;

    vec3 sunColor = SunMoonColor.rgb * SunMoonColor.a;
    vec3 col = tex.rgb * v_Color.rgb * sunColor;

    // Soft corona glow
    vec3  sunDir  = normalize(LightWorldSpaceDirection.xyz);
    float cosA    = dot(normalize(v_RayDir), sunDir);
    float corona  = pow(max(0.0, cosA), 16.0) * 0.12;
    col += sunColor * corona;

    col = pow(clamp(col, 0.0, 1.0), vec3(1.0 / 2.2));
    FragColor = vec4(col, tex.a);
}
