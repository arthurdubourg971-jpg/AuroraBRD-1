// =============================================================
//  Aurora BRD — sky.vsh
//  Sky dome vertex shader
// =============================================================
#version 300 es

uniform mat4  WorldViewProjection;
uniform mat4  World;
uniform vec4  ViewPositionAndTime;     // xyz=camPos, w=time

in vec3 Position;
in vec4 Color;

out vec3 v_WorldPos;
out vec4 v_VertexColor;
out vec3 v_RayDir;

void main() {
    vec4 worldPos4  = World * vec4(Position, 1.0);
    vec3 camPos     = ViewPositionAndTime.xyz;

    v_WorldPos      = worldPos4.xyz;
    v_VertexColor   = Color;
    v_RayDir        = normalize(worldPos4.xyz - camPos);

    gl_Position     = WorldViewProjection * vec4(Position, 1.0);
    // Sky at far plane — set depth to 1 to avoid z-fighting
    gl_Position.z   = gl_Position.w;
}
