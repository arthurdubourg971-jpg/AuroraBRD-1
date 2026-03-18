// =============================================================
//  Aurora BRD — renderchunk.vsh
//  RenderChunk vertex shader
//  Compatible: MaterialBinLoader / Better Render Dragon
//  Target:     GLSL ES 3.0 (Android/iOS)
// =============================================================
#version 300 es

// ── BRD Uniform Inputs ───────────────────────────────────────
// These are provided by Minecraft's RenderDragon engine.
// Names/bindings must match what MaterialBinTool expects.

uniform mat4  WorldViewProjection;
uniform mat4  World;
uniform mat4  ShadowWorldViewProjection; // shadow cascade 0
uniform vec4  ViewPositionAndTime;       // xyz=camPos, w=time
uniform vec4  FogAndDistanceControl;     // x=fogStart, y=fogEnd
uniform vec4  FogColor;
uniform vec4  LightWorldSpaceDirection;  // xyz=sun direction
uniform vec4  SunMoonColor;
uniform vec4  AmbientColorAndIntensity;  // xyz=ambient, w=intensity

// ── Vertex Attributes ────────────────────────────────────────
in vec3 Position;
in vec4 Color;
in vec2 UV0;          // Terrain atlas UV
in vec2 UV2;          // Lightmap UV
in vec3 Normal;

// ── Varyings → Fragment Shader ───────────────────────────────
out vec2  v_TexCoord;
out vec2  v_LightmapUV;
out vec4  v_VertexColor;
out vec3  v_Normal;
out vec3  v_WorldPos;
out vec3  v_ViewDir;
out float v_Distance;
out vec4  v_ShadowCoord;   // shadow-space position
out float v_WaterFlag;     // 1.0 if this vertex is water

void main() {
    // World-space position
    vec4 worldPos4  = World * vec4(Position, 1.0);
    vec3 worldPos   = worldPos4.xyz;

    // Camera-relative direction
    vec3 camPos     = ViewPositionAndTime.xyz;
    vec3 viewDir    = normalize(camPos - worldPos);

    // Shadow space position (for cascade 0)
    v_ShadowCoord   = ShadowWorldViewProjection * vec4(Position, 1.0);

    // Clip-space output
    gl_Position     = WorldViewProjection * vec4(Position, 1.0);

    // Pass-through varyings
    v_TexCoord      = UV0;
    v_LightmapUV    = UV2 / 255.0;   // Lightmap UV normalised to 0..1
    v_VertexColor   = Color;
    v_Normal        = normalize(mat3(World) * Normal);
    v_WorldPos      = worldPos;
    v_ViewDir       = viewDir;
    v_Distance      = length(worldPos - camPos);

    // Water detection heuristic:
    // Water blocks typically have a specific vertex-color alpha from Minecraft.
    // Engine sets alpha to ~0 for water-type geometry.
    // Adjust this threshold if needed for your pack's atlas.
    v_WaterFlag = step(Color.a, 0.02);
}
