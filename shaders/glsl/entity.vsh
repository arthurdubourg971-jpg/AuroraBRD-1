// =============================================================
//  Aurora BRD — entity.vsh
// =============================================================
#version 300 es

uniform mat4  WorldViewProjection;
uniform mat4  World;
uniform vec4  ViewPositionAndTime;
uniform vec4  LightWorldSpaceDirection;

in vec3 Position;
in vec4 Color;
in vec2 UV0;
in vec2 UV2;
in vec3 Normal;

out vec2  v_UV;
out vec2  v_LightmapUV;
out vec4  v_Color;
out vec3  v_Normal;
out vec3  v_WorldPos;
out vec3  v_ViewDir;

void main() {
    vec4 wp       = World * vec4(Position, 1.0);
    v_WorldPos    = wp.xyz;
    v_UV          = UV0;
    v_LightmapUV  = UV2 / 255.0;
    v_Color       = Color;
    v_Normal      = normalize(mat3(World) * Normal);
    v_ViewDir     = normalize(ViewPositionAndTime.xyz - wp.xyz);
    gl_Position   = WorldViewProjection * vec4(Position, 1.0);
}
