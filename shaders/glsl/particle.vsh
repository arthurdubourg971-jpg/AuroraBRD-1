// =============================================================
//  Aurora BRD — particle.vsh
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

void main() {
    v_UV        = UV0;
    v_Color     = Color;
    gl_Position = WorldViewProjection * vec4(Position, 1.0);
}
