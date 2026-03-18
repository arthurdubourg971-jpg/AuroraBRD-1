// =============================================================
//  Aurora BRD — clouds.fsh
//  Renders the active cloud mode (VANILLA / BOX / VOLUMETRIC)
// =============================================================
#version 300 es
precision highp float;

#include "include/config.glsl"
#include "include/noise.glsl"
#include "include/clouds.glsl"

uniform sampler2D TEXTURE_0;      // vanilla cloud texture (used in VANILLA mode)
uniform vec4      ViewPositionAndTime;
uniform vec4      FogColor;
uniform vec4      SunMoonColor;
uniform vec4      LightWorldSpaceDirection;
uniform vec4      FogAndDistanceControl;

in vec3 v_WorldPos;
in vec3 v_RayDir;
in vec4 v_VertexColor;
in vec2 v_UV;

out vec4 FragColor;

void main() {
    float time    = ViewPositionAndTime.w;
    vec3  sunColor = SunMoonColor.rgb * SunMoonColor.a;
    vec3  skyColor = FogColor.rgb;
    vec3  camPos   = ViewPositionAndTime.xyz;
    vec3  rayDir   = normalize(v_RayDir);

#if defined(CLOUD_VANILLA)
    // Pass vanilla cloud texture through with engine vertex colour
    vec4 tex = texture(TEXTURE_0, v_UV) * v_VertexColor;
    FragColor = tex;
    return;
#endif

    // BOX or VOLUMETRIC — use our cloud function
    vec4 cloud = SampleCloud(camPos, rayDir, time, sunColor, skyColor);

    // Discard empty fragments
    if (cloud.a < 0.005) discard;

    // Apply engine tint
    cloud.rgb *= v_VertexColor.rgb;

    // Gamma
    cloud.rgb = pow(clamp(cloud.rgb, 0.0, 1.0), vec3(1.0 / 2.2));

    FragColor = cloud;
}
