// =============================================================
//  Aurora BRD — sunmoon.vsh
// =============================================================
#version 300 es

uniform mat4 WorldViewProjection;
uniform mat4 World;
uniform vec4 ViewPositionAndTime;

in vec3 Position;
in vec4 Color;
in vec2 UV0;

out vec2 v_UV;
out vec4 v_Color;
out vec3 v_RayDir;

void main() {
    vec4 wp     = World * vec4(Position, 1.0);
    v_UV        = UV0;
    v_Color     = Color;
    v_RayDir    = normalize(wp.xyz - ViewPositionAndTime.xyz);
    gl_Position = WorldViewProjection * vec4(Position, 1.0);
    gl_Position.z = gl_Position.w;
}
