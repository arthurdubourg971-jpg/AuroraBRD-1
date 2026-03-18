// =============================================================
//  Aurora BRD — renderchunk.fsh
//  RenderChunk fragment shader — full Aurora pipeline:
//    Lighting → Shadows → Water → Fog → Color Grade → Tonemap
// =============================================================
#version 300 es
precision highp float;

// ── Include order matters ────────────────────────────────────
#include "include/config.glsl"
#include "include/noise.glsl"
#include "include/lighting.glsl"
#include "include/shadows.glsl"
#include "include/water.glsl"
#include "include/fog.glsl"

// ── Samplers ─────────────────────────────────────────────────
uniform sampler2D TEXTURE_0;    // Terrain atlas
uniform sampler2D TEXTURE_1;    // Lightmap
#if SHADOW_PCF == 1
uniform sampler2D TEXTURE_2;    // Shadow map
#endif

// ── Engine Uniforms ──────────────────────────────────────────
uniform vec4 ViewPositionAndTime;    // xyz=camPos, w=time
uniform vec4 FogAndDistanceControl;  // x=fogStart, y=fogEnd
uniform vec4 FogColor;
uniform vec4 LightWorldSpaceDirection;
uniform vec4 SunMoonColor;
uniform vec4 AmbientColorAndIntensity;
uniform int  uDimensionId;           // 0=Overworld,1=Nether,2=End

// ── Varyings ─────────────────────────────────────────────────
in vec2  v_TexCoord;
in vec2  v_LightmapUV;
in vec4  v_VertexColor;
in vec3  v_Normal;
in vec3  v_WorldPos;
in vec3  v_ViewDir;
in float v_Distance;
in vec4  v_ShadowCoord;
in float v_WaterFlag;

out vec4 FragColor;

void main() {
    // ── Texture sample ────────────────────────────────────────
    vec4 albedo4 = texture(TEXTURE_0, v_TexCoord) * v_VertexColor;
    if (albedo4.a < 0.01) discard;

    vec3 albedo  = SRGBToLinear(albedo4.rgb);
    bool isWater = v_WaterFlag > 0.5;

    // ── Lightmap ──────────────────────────────────────────────
    vec2  lmUV  = clamp(v_LightmapUV, 0.0, 1.0);

    // ── Shadow ────────────────────────────────────────────────
#if SHADOW_PCF == 1
    float shadow = GetShadow(TEXTURE_2, v_ShadowCoord, lmUV.x);
#else
    float shadow = GetShadow(lmUV.x);
#endif

    // ── Normal (water gets animated normal) ───────────────────
    vec3 normal = v_Normal;
    float time  = ViewPositionAndTime.w;

    if (isWater) {
        vec3 wN    = WaterNormal(v_WorldPos.xz, time);
        // Blend animated normal with geometry normal (mostly flat)
        normal = normalize(mix(v_Normal, wN, 0.6));
    }

    // ── Lighting ──────────────────────────────────────────────
    vec3 sunDir    = normalize(LightWorldSpaceDirection.xyz);
    vec3 sunColor  = SRGBToLinear(SunMoonColor.rgb) * SunMoonColor.a;
    vec3 camPos    = ViewPositionAndTime.xyz;

    vec3 lit;
    if (isWater) {
        lit = ComputeWaterColor(
            albedo,
            normalize(v_ViewDir),
            normal,
            SRGBToLinear(FogColor.rgb),   // sky approximation from fog
            sunColor,
            sunDir,
            shadow,
            lmUV.x,
            1.0   // approximate water depth
        );
    } else {
        lit = AuroraLighting(
            albedo,
            normal,
            normalize(v_ViewDir),
            lmUV,
            TEXTURE_1,
            sunDir,
            sunColor,
            shadow,
            clamp(sunDir.y * 0.5 + 0.5, 0.0, 1.0),
            false
        );
    }

    // ── Emissive boost (torches, lava, glowstone etc.) ────────
    // High block light value with low sky light = emissive source
    float emissive = smoothstep(0.85, 1.0, lmUV.y) * (1.0 - lmUV.x * 0.5);
    lit += albedo * emissive * 1.8;

    // ── Fog ───────────────────────────────────────────────────
    lit = ApplyFog(
        lit,
        v_WorldPos,
        camPos,
        SRGBToLinear(FogColor.rgb),
        FogAndDistanceControl.xy,
        uDimensionId,
        time
    );

#ifdef AURORA_COLOR_GRADING
    // ── Color Grade (subtle) ─────────────────────────────────
    lit = ColorGrade(lit);
#endif

    // ── Tonemap → sRGB ───────────────────────────────────────
    lit = ApplyTonemap(lit);
    lit = LinearToSRGB(lit);

    FragColor = vec4(lit, albedo4.a);
}
