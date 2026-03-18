// =============================================================
//  Aurora BRD — entity.fsh
// =============================================================
#version 300 es
precision highp float;

#include "include/config.glsl"
#include "include/lighting.glsl"
#include "include/shadows.glsl"

uniform sampler2D TEXTURE_0;
uniform sampler2D TEXTURE_1;   // lightmap
uniform vec4 ViewPositionAndTime;
uniform vec4 LightWorldSpaceDirection;
uniform vec4 SunMoonColor;
uniform vec4 FogColor;
uniform vec4 FogAndDistanceControl;

in vec2  v_UV;
in vec2  v_LightmapUV;
in vec4  v_Color;
in vec3  v_Normal;
in vec3  v_WorldPos;
in vec3  v_ViewDir;

out vec4 FragColor;

void main() {
    vec4 albedo4 = texture(TEXTURE_0, v_UV) * v_Color;
    if (albedo4.a < 0.01) discard;

    vec3 albedo   = SRGBToLinear(albedo4.rgb);
    vec2 lmUV     = clamp(v_LightmapUV, 0.0, 1.0);
    float shadow  = LightmapShadow(lmUV.x);

    vec3 sunDir   = normalize(LightWorldSpaceDirection.xyz);
    vec3 sunColor = SRGBToLinear(SunMoonColor.rgb) * SunMoonColor.a;

    vec3 lit = AuroraLighting(
        albedo, v_Normal, normalize(v_ViewDir),
        lmUV, TEXTURE_1,
        sunDir, sunColor, shadow,
        clamp(sunDir.y * 0.5 + 0.5, 0.0, 1.0),
        false
    );

    // Fog (overworld only for entities)
    float dist = length(v_WorldPos - ViewPositionAndTime.xyz);
    float fogF = clamp((dist - FogAndDistanceControl.x) /
                       ((FogAndDistanceControl.y - FogAndDistanceControl.x) / FOG_OVERWORLD_SCALE),
                       0.0, 1.0);
    lit = mix(lit, SRGBToLinear(FogColor.rgb), fogF);

#ifdef AURORA_COLOR_GRADING
    lit = ColorGrade(lit);
#endif
    lit = ApplyTonemap(lit);
    lit = LinearToSRGB(lit);

    FragColor = vec4(lit, albedo4.a);
}
