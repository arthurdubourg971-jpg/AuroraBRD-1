// =============================================================
//  Aurora BRD — sky.fsh
//  Physically-inspired sky:
//    Overworld : Rayleigh-inspired gradient + horizon glow
//    Nether    : dark cave atmosphere
//    The End   : deep-space nebula with stars + optional planets
// =============================================================
#version 300 es
precision highp float;

#include "include/config.glsl"
#include "include/noise.glsl"
#include "include/clouds.glsl"

uniform vec4 FogColor;             // sky/horizon colour from engine
uniform vec4 SunMoonColor;
uniform vec4 LightWorldSpaceDirection;
uniform vec4 ViewPositionAndTime;  // w = time
uniform int  uDimensionId;

in vec3 v_WorldPos;
in vec4 v_VertexColor;
in vec3 v_RayDir;

out vec4 FragColor;

// ── Rayleigh scattering approximation ────────────────────────
vec3 AtmosphericScatter(vec3 rayDir, vec3 sunDir, vec3 horizonColor, vec3 zenithColor) {
    float sunElevation = clamp(sunDir.y, -0.1, 1.0);
    float upness       = clamp(rayDir.y, 0.0, 1.0);

    // Zenith darkens at night
    vec3  zenith  = mix(vec3(0.005, 0.006, 0.015), zenithColor, smoothstep(-0.05, 0.2, sunElevation));
    vec3  horizon = mix(vec3(0.01, 0.01, 0.02), horizonColor, smoothstep(-0.05, 0.1, sunElevation));

    vec3  sky = mix(horizon, zenith, pow(upness, 0.6));

    // Horizon glow (scattering at low angles)
    float horizonFade = exp(-abs(rayDir.y) * 4.5);
    sky += horizonColor * horizonFade * 0.35 * smoothstep(-0.1, 0.25, sunElevation);

    return sky;
}

// ── Sun disc ─────────────────────────────────────────────────
vec3 SunDisc(vec3 rayDir, vec3 sunDir, vec3 sunColor) {
    float sunDot  = dot(rayDir, sunDir);
    float disc    = smoothstep(0.9998, 0.9999, sunDot);   // tight disc
    float corona  = pow(max(0.0, sunDot), 32.0) * 0.08;   // corona glow
    return sunColor * (disc + corona);
}

// ── Moon disc ─────────────────────────────────────────────────
vec3 MoonDisc(vec3 rayDir, vec3 moonDir) {
    float d    = dot(rayDir, moonDir);
    float disc = smoothstep(0.9992, 0.9996, d);
    return vec3(0.72, 0.74, 0.80) * disc;
}

// ── Stars (procedural) ───────────────────────────────────────
float Stars(vec3 rayDir, float time) {
    // Project ray onto 2D for stable star placement
    vec2 uv     = vec2(atan(rayDir.x, rayDir.z), asin(rayDir.y)) * vec2(0.5 / 3.14159, 1.0 / 3.14159);
    uv         *= 80.0;
    vec2  cell   = floor(uv);
    vec2  frac_  = fract(uv) - 0.5;

    // Random centre per cell
    vec2  offset  = hash22(cell) - 0.5;
    float d       = length(frac_ - offset * 0.3);

    // Twinkle
    float twinkle = 0.85 + 0.15 * sin(time * 2.1 + hash12(cell) * 6.28);
    float star    = smoothstep(0.06, 0.02, d) * twinkle;
    star         *= step(0.5, hash12(cell + 7.3)); // ~50% density
    return star;
}

// ── End nebula (full-sky version) ────────────────────────────
vec3 EndNebula(vec3 rayDir, float time) {
    // Sample multiple FBM layers for nebula feel
    vec3  p0    = rayDir * 1.8 + vec3(time * 0.003, 0.0, time * 0.002);
    vec3  p1    = rayDir * 3.5 + vec3(-time * 0.002, time * 0.003, 0.0);

    float n0    = fbm3D(p0, 3);
    float n1    = fbm3D(p1, 3);

    vec3  col0  = vec3(0.30, 0.05, 0.50);
    vec3  col1  = vec3(0.10, 0.02, 0.22);
    vec3  col2  = vec3(0.55, 0.12, 0.70);

    vec3  nebula = mix(mix(col1, col0, n0), col2, n1 * n1);

    // Stars always visible in The End
    float starBright = Stars(rayDir, time) * 2.0;
    nebula          += vec3(0.7, 0.6, 0.9) * starBright;

    return nebula;
}

// ── Optional: simple planet disc ─────────────────────────────
vec3 EndPlanet(vec3 rayDir, float time) {
#ifndef AURORA_HIGH
    return vec3(0.0);
#endif
    // Fixed large planet to one side of the sky
    vec3  planetDir = normalize(vec3(0.6, 0.3, -0.7));
    float d         = dot(rayDir, planetDir);
    if (d < 0.9) return vec3(0.0);

    float r         = 1.0 - smoothstep(0.935, 0.96, d);  // planet edge
    // Surface noise
    vec3  sp        = rayDir * 60.0 + vec3(time * 0.0005);
    float surf      = fbm3D(sp, 3);
    vec3  col       = mix(vec3(0.45, 0.25, 0.60), vec3(0.20, 0.10, 0.35), surf);
    // Ring
    float ring      = abs(dot(rayDir, vec3(0.0, 1.0, 0.0)) - 0.26) < 0.012 ? 1.0 : 0.0;
    col            += vec3(0.35, 0.20, 0.55) * ring * smoothstep(0.91, 0.935, d);

    return col * r;
}

void main() {
    vec3  rayDir    = normalize(v_RayDir);
    float time      = ViewPositionAndTime.w;
    vec3  sunDir    = normalize(LightWorldSpaceDirection.xyz);
    vec3  moonDir   = -sunDir;
    vec3  sunColor  = SunMoonColor.rgb * SunMoonColor.a;
    vec3  fogRGB    = FogColor.rgb;

    vec3 skyColor = vec3(0.0);

    if (uDimensionId == 2) {
        // ── The End ──────────────────────────────────────────
        skyColor  = EndNebula(rayDir, time);
        skyColor += EndPlanet(rayDir, time);

    } else if (uDimensionId == 1) {
        // ── Nether ───────────────────────────────────────────
        // Dark, dusty red-brown atmosphere
        float upness = clamp(rayDir.y * 0.5 + 0.5, 0.0, 1.0);
        skyColor     = mix(vec3(0.12, 0.04, 0.02), vec3(0.22, 0.06, 0.02), upness);

    } else {
        // ── Overworld ────────────────────────────────────────
        vec3 zenithColor  = vec3(0.18, 0.38, 0.72);
        vec3 horizonColor = fogRGB;

        skyColor = AtmosphericScatter(rayDir, sunDir, horizonColor, zenithColor);

        // Sun
        if (sunDir.y > -0.1) {
            skyColor += SunDisc(rayDir, sunDir, sunColor);
        }
        // Moon
        if (moonDir.y > -0.1) {
            skyColor += MoonDisc(rayDir, moonDir);
        }

        // Night stars (fade with sun elevation)
        float nightFactor = smoothstep(0.15, -0.05, sunDir.y);
        if (nightFactor > 0.01) {
            float star    = Stars(rayDir, time);
            skyColor     += vec3(0.85, 0.85, 1.0) * star * nightFactor * 0.9;
        }

        // Clouds (composite over sky)
        vec4 cloud = SampleCloud(ViewPositionAndTime.xyz, rayDir, time, sunColor, skyColor);
        skyColor   = mix(skyColor, cloud.rgb, clamp(cloud.a, 0.0, 1.0));
    }

    // Apply engine vertex color tint (handles day/night transitions)
    skyColor *= v_VertexColor.rgb;

    // Tonemap
    skyColor = pow(clamp(skyColor, 0.0, 1.0), vec3(1.0 / 2.2));

    FragColor = vec4(skyColor, 1.0);
}
