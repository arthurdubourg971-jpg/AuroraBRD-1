// =============================================================
//  Aurora BRD — clouds.vsh
//  Dedicated cloud-pass vertex shader
// =============================================================
#version 300 es

uniform mat4 WorldViewProjection;
uniform mat4 World;
uniform vec4 ViewPositionAndTime;

in vec3 Position;
in vec4 Color;
in vec2 UV0;

out vec3 v_WorldPos;
out vec3 v_RayDir;
out vec4 v_VertexColor;
out vec2 v_UV;

void main() {
    vec4 worldPos4  = World * vec4(Position, 1.0);
    v_WorldPos      = worldPos4.xyz;
    v_RayDir        = normalize(worldPos4.xyz - ViewPositionAndTime.xyz);
    v_VertexColor   = Color;
    v_UV            = UV0;
    gl_Position     = WorldViewProjection * vec4(Position, 1.0);
}
